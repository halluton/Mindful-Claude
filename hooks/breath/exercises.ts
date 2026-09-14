// The four breathing exercises and the maths of one breath, ported from legacy/breathe.sh.
// Pure functions: no engine, no surface, so `bun test` covers them.

export type ExerciseKey = 'hrv' | 'sigh' | 'box' | '478'

export type Exercise = {
  key: ExerciseKey
  name: string
  /** The pattern, as the list prints it. */
  pattern: string
  inhaleMs: number
  hold1Ms: number
  exhaleMs: number
  hold2Ms: number
  /** Physiological sigh: the first hold is a second, smaller inhale. */
  sip?: true
}

export const EXERCISES: readonly Exercise[] = [
  { key: 'hrv', name: 'Coherent Breathing', pattern: '5.5s in, 5.5s out', inhaleMs: 5500, hold1Ms: 0, exhaleMs: 5500, hold2Ms: 0 },
  { key: 'sigh', name: 'Physiological Sigh', pattern: 'double inhale, long exhale', inhaleMs: 4000, hold1Ms: 1000, exhaleMs: 10000, hold2Ms: 0, sip: true },
  { key: 'box', name: 'Box Breathing', pattern: '4s in, 4s hold, 4s out, 4s hold', inhaleMs: 4000, hold1Ms: 4000, exhaleMs: 4000, hold2Ms: 4000 },
  { key: '478', name: '4-7-8 Breathing', pattern: '4s in, 7s hold, 8s out', inhaleMs: 4000, hold1Ms: 7000, exhaleMs: 8000, hold2Ms: 0 },
]

const ALIASES: Record<string, ExerciseKey> = {
  hrv: 'hrv', coherent: 'hrv', coherence: 'hrv',
  sigh: 'sigh', physiological: 'sigh',
  box: 'box',
  '478': '478', relax: '478',
}

export const isExerciseKey = (value: unknown): value is ExerciseKey =>
  typeof value === 'string' && EXERCISES.some(e => e.key === value)

/** The exercise a word names (`hrv`, `coherent`, `sigh`, `box`, `478`, `relax`), or undefined. */
export const resolveExercise = (word: string): ExerciseKey | undefined => ALIASES[word.trim().toLowerCase()]

export const exerciseOf = (key: unknown): Exercise => EXERCISES.find(e => e.key === key) ?? EXERCISES[0]!

export const cycleMs = (ex: Exercise): number => ex.inhaleMs + ex.hold1Ms + ex.exhaleMs + ex.hold2Ms

export type PhaseLabel = 'Breathe in' | 'Sip in' | 'Hold' | 'Breathe out'

export type Phase = {
  label: PhaseLabel
  /** Milliseconds left in this phase. */
  remainingMs: number
  /** How full the lungs are, 0..1000. */
  progress: number
}

/** Ease-out (quadratic) over 0..1000: fast start, gentle deceleration. */
export const ease = (x: number): number => Math.floor((x * (2000 - x)) / 1000)

/** Where in the breath `elapsedMs` since the start lands. */
export function phaseAt(ex: Exercise, elapsedMs: number): Phase {
  const cycle = cycleMs(ex)
  const t = ((Math.floor(elapsedMs) % cycle) + cycle) % cycle
  const inhaleEnd = ex.inhaleMs
  const hold1End = inhaleEnd + ex.hold1Ms
  const exhaleEnd = hold1End + ex.exhaleMs

  if (t < inhaleEnd) {
    const eased = ease(Math.floor((t * 1000) / ex.inhaleMs))
    // a sigh's first inhale fills 85%; the sip takes the rest
    const progress = ex.sip ? Math.floor((eased * 850) / 1000) : eased
    return { label: 'Breathe in', remainingMs: inhaleEnd - t, progress }
  }
  if (t < hold1End) {
    if (ex.sip) {
      const eased = ease(Math.floor(((t - inhaleEnd) * 1000) / ex.hold1Ms))
      return { label: 'Sip in', remainingMs: hold1End - t, progress: 850 + Math.floor((eased * 150) / 1000) }
    }
    return { label: 'Hold', remainingMs: hold1End - t, progress: 1000 }
  }
  if (t < exhaleEnd) {
    const eased = ease(Math.floor(((t - hold1End) * 1000) / ex.exhaleMs))
    return { label: 'Breathe out', remainingMs: exhaleEnd - t, progress: 1000 - eased }
  }
  return { label: 'Hold', remainingMs: cycle - t, progress: 0 }
}

/** The countdown the phase line shows: whole seconds, rounded up. */
export const secondsLeft = (phase: Phase): number => Math.ceil(phase.remainingMs / 1000)

/** The band's line: `Breathe in... 4s` */
export const phaseLine = (phase: Phase): string => `${phase.label}... ${secondsLeft(phase)}s`

/** The spinner's word, which the engine follows with its own ellipsis: `Breathe in 4s` */
export const spinnerWord = (phase: Phase): string => `${phase.label} ${secondsLeft(phase)}s`
