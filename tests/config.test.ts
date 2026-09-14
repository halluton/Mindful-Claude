import { describe, expect, test } from 'bun:test'
import { DEFAULTS, HELP, applyCommand, readConfig, statusLine } from '../hooks/breath/config.ts'

describe('config', () => {
  test('the store may hold anything; defaults fill what it lacks', () => {
    expect(readConfig(undefined)).toEqual(DEFAULTS)
    expect(readConfig({ exercise: 'box', delay: 5 })).toEqual({ ...DEFAULTS, exercise: 'box', delay: 5 })
    expect(readConfig({ exercise: 'nope', delay: -1, style: 'neon', enabled: 'yes' })).toEqual(DEFAULTS)
  })

  test('no argument reports, help lists', () => {
    expect(applyCommand(DEFAULTS, '').text).toBe(statusLine(DEFAULTS))
    expect(applyCommand(DEFAULTS, 'help').text).toBe(HELP)
    expect(applyCommand(DEFAULTS, '').config).toBe(DEFAULTS)
  })

  test('on and off', () => {
    const off = applyCommand(DEFAULTS, 'off')
    expect(off.config.enabled).toBe(false)
    expect(off.text).toContain('breathe: off')
    expect(applyCommand(off.config, 'ON').config.enabled).toBe(true)
  })

  test('an exercise by name or alias', () => {
    expect(applyCommand(DEFAULTS, 'box').config.exercise).toBe('box')
    expect(applyCommand(DEFAULTS, 'relax').config.exercise).toBe('478')
    expect(applyCommand(DEFAULTS, 'sigh').text).toContain('Physiological Sigh')
  })

  test('style, with and without the word', () => {
    expect(applyCommand(DEFAULTS, 'style wave').config.style).toBe('wave')
    expect(applyCommand(DEFAULTS, 'dots').config.style).toBe('dots')
    expect(applyCommand(DEFAULTS, 'style random').config.style).toBe('random')
    const bad = applyCommand(DEFAULTS, 'style neon')
    expect(bad.config).toBe(DEFAULTS)
    expect(bad.text).toContain('pulse, ripples, dots, wave')
  })

  test('delay takes seconds, refuses the rest', () => {
    expect(applyCommand(DEFAULTS, 'delay 5').config.delay).toBe(5)
    expect(applyCommand(DEFAULTS, 'delay 0').config.delay).toBe(0)
    expect(applyCommand(DEFAULTS, 'delay').config).toBe(DEFAULTS)
    expect(applyCommand(DEFAULTS, 'delay soon').config).toBe(DEFAULTS)
  })

  test('spinner on or off', () => {
    expect(applyCommand(DEFAULTS, 'spinner off').config.spinner).toBe(false)
    expect(applyCommand(DEFAULTS, 'spinner maybe').config).toBe(DEFAULTS)
  })

  test('an unknown word leaves the config and prints the help', () => {
    const r = applyCommand(DEFAULTS, 'tetris')
    expect(r.config).toBe(DEFAULTS)
    expect(r.text).toContain('no setting called "tetris"')
  })
})
