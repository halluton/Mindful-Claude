/* @jsx h */
import type { ClientSurface } from 'claude-code'
import { exerciseOf, phaseAt, phaseLine, spinnerWord } from './breath/exercises.ts'
import { centre, frame, isStyle, type Style } from './breath/shapes.ts'

// The breathing band: a surface module the hooks module mounts above the prompt while Claude
// works. It runs on the drawing thread with its own frame clock, ten frames a second like
// legacy/breathe.sh, and posts the phase line to the hooks module whenever it changes so the
// spinner can read it too.
//
// Never name a local `h` here: every JSX tag compiles to a call of `h`.

type Props = { exercise?: string; style?: string; elapsedMs?: number } | undefined
type State = { tick: number; offsetMs: number; line: string }

const COLOR = '#f7835d' // Claude orange
const TICK_MS = 100

export default function Breathe(props: Props, surface: ClientSurface<State>) {
  const { Box, Text } = surface.elements
  const exercise = exerciseOf(props?.exercise)
  const style: Style = isStyle(props?.style) ? props.style : 'pulse'

  if (surface.state === undefined) {
    // elapsedMs says how far into the turn the band mounted (a delay); the clock runs from there
    surface.setState({ tick: 0, offsetMs: props?.elapsedMs ?? 0, line: '' })
    surface.every(TICK_MS, () => {
      const s = surface.state
      if (!s) return
      const tick = s.tick + 1
      const next = phaseAt(exercise, s.offsetMs + tick * TICK_MS)
      const line = phaseLine(next)
      if (line !== s.line) surface.post({ word: spinnerWord(next), exercise: exercise.name })
      surface.setState({ tick, offsetMs: s.offsetMs, line })
    })
  }

  const s = surface.state
  const elapsed = (s?.offsetMs ?? 0) + (s?.tick ?? 0) * TICK_MS
  const phase = phaseAt(exercise, elapsed)
  const width = surface.columns || 80
  const rows = surface.rows || 9
  // two rows of text under the picture; a short band keeps the phase line and drops the rest
  const artRows = Math.max(0, rows - 2)
  const art = frame(style, phase.progress, width, artRows)

  return (
    <Box flexDirection="column" width={width}>
      {art.map(line => <Text color={COLOR}>{line}</Text>)}
      {rows >= 1 ? <Text color={COLOR}>{centre(phaseLine(phase), width)}</Text> : null}
      {rows >= 2 ? <Text color={COLOR} dimColor>{centre(exercise.name, width)}</Text> : null}
    </Box>
  )
}
