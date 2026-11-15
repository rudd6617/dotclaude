import { expect, test } from 'claude-code/testing'

import { chipOf, clockOf, outcomeOf, shorten } from './format'

const BAND = {
  plugin: 'agent-band',
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isCollapsed: false,
    isWorking: true,
    maxRows: 10,
    bodyColumns: 100,
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const spawn = (description: string, subagentType: string) => ({
  prompt: 'p',
  description,
  subagentType,
  tool_use_id: `t-${description}`,
  provider: { plugin: 'engine', tier: 'core' },
  parentModel: 'm',
  background: false,
  fork: false,
}) as const

const TURN = { answer: '', durationMs: 1000, isAborted: false, turnId: 't1' } as const

test('format: clock, shorten, outcome', async () => {
  expect(clockOf(0)).toBe('0:00')
  expect(clockOf(75_400)).toBe('1:15')
  expect(shorten('查 hook 設定')).toBe('查 hook 設定')
  expect(shorten('一二三四五六七八九十', 5)).toBe('一二三四…')
  expect(outcomeOf('answer')).toBe('done')
  expect(outcomeOf('aborted')).toBe('aborted')
  expect(outcomeOf('error')).toBe('failed')
  expect(outcomeOf('refusal')).toBe('failed')
  const chip = chipOf({ id: 'a', type: 'Plan', description: 'x', startedAt: 1000, endedAt: 76_000, outcome: 'done' }, 999_999)
  expect(chip).toEqual({ mark: '✓', state: 'done', label: 'Plan「x」', elapsed: '1:15' })
})

test('band is empty until an agent spawns', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface })
    expect((await ui.find({ type: 'Text', text: /engine/ }))?.text).toBe('engine')
    await ui.unmount()
  }
})

test('running, done, failed, then cleared on the next prompt', async ($, on) => {
  let n = 0
  on('clock.now', () => ({ value: 1000 }))
  on('clock.every', () => ({ value: undefined }))
  on('agent.spawn', () => ({ model: 'm', agentId: `a${++n}` }))
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', (_, e) => ({ text: e.text }))

  await $.agent.spawn(spawn('查 hook 設定', 'Explore'))
  await $.agent.spawn(spawn('寫方案', 'Plan'))

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface })
    expect(await ui.find({ type: 'Text', text: /▶ Explore「查 hook 設定」/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /▶ Plan「寫方案」/ })).toBeDefined()
    await ui.unmount()
  }

  await $.turn.complete({ ...TURN, agentId: 'a1', reason: 'answer' })
  await $.turn.complete({ ...TURN, agentId: 'a2', reason: 'error' })
  // the main loop's own turn end touches nothing
  await $.turn.complete({ ...TURN, reason: 'answer' })

  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /✓ Explore/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /✗ Plan/ })).toBeDefined()
  await ui.unmount()

  await $.agent.spawn(spawn('還在跑', 'Explore'))
  await $.prompt.submit({ text: 'next', origin: { kind: 'composer' } } as never)

  const after = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await after.find({ type: 'Text', text: /✓ Explore/ })).toBeUndefined()
  expect(await after.find({ type: 'Text', text: /▶ Explore「還在跑」/ })).toBeDefined()
  await after.unmount()
})

test('an Agent row keeps the engine row inside a colored bar', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine row</Text>
  })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({
      plugin: 'agent-band',
      component: 'ToolUse',
      surface,
      requestId: 't1',
      props: { tool_use_id: 't1', tool: 'Agent', input: {}, isRunning: true, isErrored: false, isInterrupted: false },
    } as never)
    expect(await ui.find({ type: 'Text', text: /engine row/ })).toBeDefined()
    expect(await ui.find({ type: 'Box' })).toBeDefined()
    await ui.unmount()
  }
})
