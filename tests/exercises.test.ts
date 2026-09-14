import { describe, expect, test } from 'bun:test'
import { EXERCISES, cycleMs, ease, exerciseOf, phaseAt, phaseLine, resolveExercise, secondsLeft } from '../hooks/breath/exercises.ts'

describe('exercises', () => {
  test('four exercises, keyed as /breathe names them', () => {
    expect(EXERCISES.map(e => e.key)).toEqual(['hrv', 'sigh', 'box', '478'])
    expect(cycleMs(exerciseOf('hrv'))).toBe(11000)
    expect(cycleMs(exerciseOf('box'))).toBe(16000)
    expect(cycleMs(exerciseOf('478'))).toBe(19000)
    expect(cycleMs(exerciseOf('sigh'))).toBe(15000)
  })

  test('aliases resolve, unknown words do not, unknown keys fall back to coherent', () => {
    expect(resolveExercise('HRV')).toBe('hrv')
    expect(resolveExercise('coherent')).toBe('hrv')
    expect(resolveExercise('relax')).toBe('478')
    expect(resolveExercise('tetris')).toBeUndefined()
    expect(exerciseOf('nope').key).toBe('hrv')
  })

  test('ease is 0 at 0, 1000 at 1000, and ahead of linear between', () => {
    expect(ease(0)).toBe(0)
    expect(ease(1000)).toBe(1000)
    expect(ease(500)).toBeGreaterThan(500)
  })

  test('coherent: in for 5.5s, out for 5.5s, full at the turn', () => {
    const ex = exerciseOf('hrv')
    expect(phaseAt(ex, 0)).toEqual({ label: 'Breathe in', remainingMs: 5500, progress: 0 })
    expect(phaseAt(ex, 5499).progress).toBeGreaterThan(990)
    expect(phaseAt(ex, 5500)).toMatchObject({ label: 'Breathe out', remainingMs: 5500, progress: 1000 })
    expect(phaseAt(ex, 10999).progress).toBeLessThan(10)
    expect(phaseAt(ex, 11000).label).toBe('Breathe in')
  })

  test('box: four phases of four seconds, holds full and empty', () => {
    const ex = exerciseOf('box')
    expect(phaseAt(ex, 4000)).toEqual({ label: 'Hold', remainingMs: 4000, progress: 1000 })
    expect(phaseAt(ex, 8000).label).toBe('Breathe out')
    expect(phaseAt(ex, 12000)).toEqual({ label: 'Hold', remainingMs: 4000, progress: 0 })
  })

  test('sigh: the first inhale fills 85%, the sip the rest', () => {
    const ex = exerciseOf('sigh')
    expect(phaseAt(ex, 3999).progress).toBeLessThanOrEqual(850)
    expect(phaseAt(ex, 3999).progress).toBeGreaterThan(830)
    expect(phaseAt(ex, 4000)).toMatchObject({ label: 'Sip in', progress: 850 })
    expect(phaseAt(ex, 4999).progress).toBeGreaterThan(990)
    expect(phaseAt(ex, 5000)).toMatchObject({ label: 'Breathe out', progress: 1000 })
  })

  test('the countdown rounds up and the line reads as the pane did', () => {
    const ex = exerciseOf('hrv')
    expect(secondsLeft(phaseAt(ex, 0))).toBe(6)
    expect(secondsLeft(phaseAt(ex, 4600))).toBe(1)
    expect(phaseLine(phaseAt(ex, 6000))).toBe('Breathe out... 5s')
  })

  test('elapsed time wraps, negatives included', () => {
    const ex = exerciseOf('hrv')
    expect(phaseAt(ex, 22000)).toEqual(phaseAt(ex, 0))
    expect(phaseAt(ex, -1000)).toEqual(phaseAt(ex, 10000))
  })
})

import { spinnerWord } from '../hooks/breath/exercises.ts'
describe('spinner word', () => {
  test('no ellipsis of its own: the engine adds one', () => {
    expect(spinnerWord(phaseAt(exerciseOf('hrv'), 0))).toBe('Breathe in 6s')
  })
})
