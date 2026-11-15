import { expect, test } from 'claude-code/testing'

import { displayWidth, hasColor, inline, isPlainInline, parse, tableLines } from './blocks'
import type { Block, Line } from './blocks'

const text = (line: Line) => line.map(span => span.text).join('')

test('display width counts CJK as two cells', async () => {
  expect(displayWidth('abc')).toBe(3)
  expect(displayWidth('中文')).toBe(4)
  expect(displayWidth('a中b')).toBe(4)
  expect(displayWidth('，')).toBe(2)
})

test('inline: bold, code and paths get roles', async () => {
  expect(inline('看 **重點** 與 `make test`')).toEqual([
    { text: '看 ' },
    { text: '重點', role: 'bold' },
    { text: ' 與 ' },
    { text: 'make test', role: 'code' },
  ])
  const spans = inline('改了 hooks/register.tsx:12 和 ~/.claude/settings.json')
  expect(spans.filter(s => s.role === 'path').map(s => s.text)).toEqual(['hooks/register.tsx:12', '~/.claude/settings.json'])
  expect(inline('e.g. 1/2 不是路徑').some(s => s.role === 'path')).toBe(false)
})

test('syntax the mod does not draw falls back', async () => {
  expect(isPlainInline('一般 **粗體** `碼`')).toBe(true)
  expect(isPlainInline('[連結](https://x.y)')).toBe(false)
  expect(isPlainInline('看 https://x.y')).toBe(false)
  expect(isPlainInline('*斜體*')).toBe(false)
  expect(isPlainInline('~~刪~~')).toBe(false)
  expect(parse('> 引言\n第二行')).toEqual([{ kind: 'markdown', text: '> 引言\n第二行' }])
  expect(parse('- [ ] 待辦')).toEqual([{ kind: 'markdown', text: '- [ ] 待辦' }])
})

test('parse: heading, list, blank, code fence', async () => {
  const blocks = parse('## 結論\n- 第一 **點**\n\n```ts\nconst a = 1\n\nconst b = 2\n```\n純文字')
  expect(blocks.map(b => b.kind)).toEqual(['lines', 'blank', 'code', 'lines'])
  const first = blocks[0] as Extract<Block, { kind: 'lines' }>
  expect(first.lines[0]).toEqual([{ text: '結論', role: 'h2' }])
  expect(first.lines[1]?.[0]).toEqual({ text: '- ', role: 'marker' })
  expect(blocks[2]).toEqual({ kind: 'code', language: 'ts', source: 'const a = 1\n\nconst b = 2' })
  expect(hasColor(blocks)).toBe(true)
  expect(hasColor(parse('只有純文字\n\n第二段'))).toBe(false)
})

test('an unclosed fence (a reply still streaming) goes to the engine', async () => {
  expect(parse('前言\n```ts\nconst a')).toEqual([
    { kind: 'lines', lines: [[{ text: '前言' }]] },
    { kind: 'markdown', text: '```ts\nconst a' },
  ])
})

test('table: CJK cells line up, alignment, too wide falls back', async () => {
  const [table] = parse('| 專案 | 數量 |\n|---|---:|\n| thec-ops | 3 |\n| 中文名稱 | 12 |')
  expect(table?.kind).toBe('table')
  const lines = tableLines(table as Extract<Block, { kind: 'table' }>, 80)!
  const drawn = lines.map(text)
  expect(drawn).toEqual([
    '┌──────────┬──────┐',
    '│ 專案     │ 數量 │',
    '├──────────┼──────┤',
    '│ thec-ops │    3 │',
    '│ 中文名稱 │   12 │',
    '└──────────┴──────┘',
  ])
  expect(new Set(drawn.map(displayWidth)).size).toBe(1)
  expect(tableLines(table as Extract<Block, { kind: 'table' }>, 10)).toBeUndefined()
})

test('a table with a link in it falls back whole', async () => {
  const src = '| a | b |\n|---|---|\n| [x](https://y) | 1 |'
  expect(parse(src)).toEqual([{ kind: 'markdown', text: src }])
})
