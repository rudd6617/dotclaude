import { expect, test } from 'claude-code/testing'

const MESSAGE = (text: string, surface: 'terminal' | 'desktop') =>
  ({
    plugin: 'reply-color',
    component: 'AssistantMessage',
    surface,
    props: { text, isFirstOfReply: true },
  }) as const

const REPLY = [
  '## 結論',
  '改了 **兩個檔**：`register.tsx` 與 hooks/blocks.ts:12',
  '',
  '| 專案 | 數量 |',
  '|---|---:|',
  '| 中文名稱 | 12 |',
  '',
  '```ts',
  'const a = 1',
  '```',
  '',
  '> 引言交回內建',
].join('\n')

test('the terminal draws the colored tree', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const ui = await $.ui.mount(MESSAGE(REPLY, 'terminal'))
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /^●$/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /│ 中文名稱 │   12 │/ })).toBeDefined()
  expect(await ui.find({ type: 'Code' })).toBeDefined()
  expect(await ui.find({ type: 'Markdown' })).toBeDefined()
  await ui.unmount()
})

test('plain text, other surfaces and summaries stay with the engine', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  for (const mount of [
    MESSAGE('只有純文字', 'terminal'),
    MESSAGE(REPLY, 'desktop'),
    { ...MESSAGE(REPLY, 'terminal'), props: { text: REPLY, isFirstOfReply: false, isSummary: true } },
  ] as const) {
    const ui = await $.ui.mount(mount)
    expect(await ui.find({ type: 'Text', text: /engine/ })).toBeDefined()
    await ui.unmount()
  }
})

const PROMPT = (kind: 'composer' | 'task-notification', surface: 'terminal' | 'desktop') =>
  ({
    plugin: 'reply-color',
    component: 'UserMessage',
    surface,
    props: { text: '幫我加底色', origin: { kind }, isExpanded: true },
  }) as const

test('your own prompt draws on a filled band', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const ui = await $.ui.mount(PROMPT('composer', 'terminal'))
  expect(await ui.find({ type: 'Text', text: /engine/ })).toBeUndefined()
  const row = await ui.find({ type: 'Text', text: /^幫我加底色$/ })
  expect(row?.props.backgroundColor).toBe('#2e3a52')
  await ui.unmount()
})

test('notifications and other surfaces keep the engine row', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  for (const mount of [PROMPT('task-notification', 'terminal'), PROMPT('composer', 'desktop')] as const) {
    const ui = await $.ui.mount(mount)
    expect(await ui.find({ type: 'Text', text: /engine/ })).toBeDefined()
    await ui.unmount()
  }
})
