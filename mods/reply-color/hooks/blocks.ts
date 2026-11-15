import type { Role } from './palette'

export type Span = { text: string; role?: Role }
export type Line = Span[]
export type Align = 'left' | 'center' | 'right'

export type Block =
  | { kind: 'blank' }
  | { kind: 'lines'; lines: Line[] }
  | { kind: 'table'; header: Line[]; align: Align[]; rows: Line[][]; source: string }
  | { kind: 'code'; language?: string; source: string }
  | { kind: 'markdown'; text: string }

// ---------- display width (CJK and emoji take two cells) ----------

const WIDE: ReadonlyArray<readonly [number, number]> = [
  [0x1100, 0x115f], [0x2e80, 0x303e], [0x3041, 0x33ff], [0x3400, 0x4dbf], [0x4e00, 0x9fff],
  [0xa000, 0xa4cf], [0xac00, 0xd7a3], [0xf900, 0xfaff], [0xfe30, 0xfe4f], [0xff00, 0xff60],
  [0xffe0, 0xffe6], [0x1f300, 0x1f64f], [0x1f900, 0x1f9ff], [0x20000, 0x3fffd],
]

const charWidth = (cp: number): number => (WIDE.some(([lo, hi]) => cp >= lo && cp <= hi) ? 2 : 1)

export const displayWidth = (text: string): number => {
  let width = 0
  for (const ch of text) width += charWidth(ch.codePointAt(0) ?? 0)
  return width
}

const lineWidth = (line: Line): number => line.reduce((sum, span) => sum + displayWidth(span.text), 0)

// ---------- inline: **bold**, `code`, paths ----------

const EXT = 'ts|tsx|js|jsx|mjs|cjs|py|md|json|jsonl|sh|zsh|go|rs|rb|java|kt|swift|yml|yaml|toml|html|css|sql|txt|lock|env|d\\.ts'
const PATH = new RegExp(`(?<![\\w.@/-])(?:~|\\.{1,2})?\\/[\\w.@-]+(?:\\/[\\w.@-]+)*(?::\\d+)?|(?<![\\w.@/-])[\\w.@-]+(?:\\/[\\w.@-]+)*\\.(?:${EXT})(?::\\d+)?\\b`, 'g')
const INLINE = /(\*\*[^*\n]+\*\*)|(`[^`\n]+`)/g

// Inline syntax this mod does not draw: links, URLs, HTML, strikethrough, escapes, math, images.
const FOREIGN = /\[[^\]]*\]\(|https?:\/\/|<[a-zA-Z/!]|~~|\\[\\`*_{}[\]()#+\-.!|]|\$\$|!\[/
// Single-star or underscore emphasis, checked after bold and code are taken out.
const EMPHASIS = /(^|[^\w*])\*[^\s*]|(^|[^\w])_[^\s_][^_]*_(?!\w)/

export const isPlainInline = (text: string): boolean => {
  if (FOREIGN.test(text)) return false
  return !EMPHASIS.test(text.replace(INLINE, ''))
}

const withPaths = (text: string): Span[] => {
  const spans: Span[] = []
  let at = 0
  for (const m of text.matchAll(PATH)) {
    const start = m.index ?? 0
    if (start > at) spans.push({ text: text.slice(at, start) })
    spans.push({ text: m[0], role: 'path' })
    at = start + m[0].length
  }
  if (at < text.length) spans.push({ text: text.slice(at) })
  return spans
}

export const inline = (text: string): Span[] => {
  const spans: Span[] = []
  let at = 0
  for (const m of text.matchAll(INLINE)) {
    const start = m.index ?? 0
    if (start > at) spans.push(...withPaths(text.slice(at, start)))
    spans.push(m[1] ? { text: m[1].slice(2, -2), role: 'bold' } : { text: m[0].slice(1, -1), role: 'code' })
    at = start + m[0].length
  }
  if (at < text.length) spans.push(...withPaths(text.slice(at)))
  return spans
}

// ---------- lines: headings, list items, prose ----------

const HEADING = /^(#{1,6})\s+(.*?)\s*#*\s*$/
const LIST = /^(\s*)([-*+]|\d+[.)])(\s+)(.*)$/
const TASK = /^\s*[-*+]\s+\[[ xX]\]/
const RULE = /^\s*([-*_])(\s*\1){2,}\s*$/

const headingRole = (level: number): Role => (level === 1 ? 'h1' : level === 2 ? 'h2' : 'h3')

const lineOf = (raw: string): Line | undefined => {
  if (/^\s*[>|<]/.test(raw) || RULE.test(raw) || TASK.test(raw)) return undefined
  const heading = HEADING.exec(raw)
  if (heading) {
    const body = heading[2] ?? ''
    if (!isPlainInline(body)) return undefined
    const role = headingRole(heading[1]!.length)
    return inline(body).map(span => (span.role === 'code' ? span : { text: span.text, role }))
  }
  const item = LIST.exec(raw)
  if (item) {
    const body = item[4] ?? ''
    if (!isPlainInline(body)) return undefined
    return [{ text: `${item[1]}${item[2]}${item[3]}`, role: 'marker' }, ...inline(body)]
  }
  if (!isPlainInline(raw)) return undefined
  return inline(raw)
}

// ---------- tables ----------

const SEPARATOR = /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/

const cellsOf = (row: string): string[] => {
  const body = row.trim().replace(/^\|/, '').replace(/\|$/, '')
  return body.split('|').map(cell => cell.trim())
}

const alignOf = (cell: string): Align => {
  const left = cell.startsWith(':')
  const right = cell.endsWith(':')
  return left && right ? 'center' : right ? 'right' : 'left'
}

const tableOf = (group: string[]): Block | undefined => {
  const [head, sep, ...body] = group
  if (!head || !sep || !SEPARATOR.test(sep)) return undefined
  if (!group.every(row => row.trim().startsWith('|'))) return undefined
  if (!group.every(row => isPlainInline(row.replace(/\|/g, ' ')))) return undefined
  const header = cellsOf(head)
  const width = header.length
  const fit = (cells: string[]) => Array.from({ length: width }, (_, i) => inline(cells[i] ?? ''))
  return {
    kind: 'table',
    header: header.map(inline),
    align: Array.from({ length: width }, (_, i) => alignOf(cellsOf(sep)[i] ?? '')),
    rows: body.map(row => fit(cellsOf(row))),
    source: group.join('\n'),
  }
}

const pad = (line: Line, width: number, align: Align): Line => {
  const room = width - lineWidth(line)
  const left = align === 'right' ? room : align === 'center' ? Math.floor(room / 2) : 0
  return [{ text: ' '.repeat(left) }, ...line, { text: ' '.repeat(room - left) }]
}

const rule = (widths: number[], [l, m, r]: readonly [string, string, string]): Line => [
  { text: l + widths.map(w => '─'.repeat(w + 2)).join(m) + r, role: 'border' },
]

/** The table as drawn lines, or undefined when it is wider than `columns`. */
export const tableLines = (table: Extract<Block, { kind: 'table' }>, columns: number): Line[] | undefined => {
  const all = [table.header, ...table.rows]
  const widths = table.header.map((_, i) => Math.max(1, ...all.map(row => lineWidth(row[i] ?? []))))
  const total = widths.reduce((sum, w) => sum + w + 3, 1)
  if (total > columns) return undefined
  const bar: Span = { text: '│', role: 'border' }
  const row = (cells: Line[], header: boolean): Line => [
    bar,
    ...cells.flatMap((cell, i) => {
      const styled = header ? cell.map(span => ({ text: span.text, role: 'header' as const })) : cell
      return [{ text: ' ' }, ...pad(styled, widths[i]!, table.align[i] ?? 'left'), { text: ' ' }, bar]
    }),
  ]
  return [
    rule(widths, ['┌', '┬', '┐']),
    row(table.header, true),
    rule(widths, ['├', '┼', '┤']),
    ...table.rows.map(cells => row(cells, false)),
    rule(widths, ['└', '┴', '┘']),
  ]
}

// ---------- blocks ----------

const FENCE = /^\s*(`{3,}|~{3,})\s*([\w+#.-]*)/

const groupBlock = (group: string[]): Block => {
  const text = group.join('\n')
  if (group.some(row => row.trim().startsWith('|'))) return tableOf(group) ?? { kind: 'markdown', text }
  if (/^ {4,}/.test(group[0] ?? '')) return { kind: 'markdown', text }
  const lines = group.map(lineOf)
  if (lines.some(line => line === undefined)) return { kind: 'markdown', text }
  return { kind: 'lines', lines: lines as Line[] }
}

export const parse = (text: string): Block[] => {
  const rows = text.split('\n')
  const blocks: Block[] = []
  let i = 0
  while (i < rows.length) {
    const row = rows[i]!
    const fence = FENCE.exec(row)
    if (fence) {
      const close = rows.findIndex((r, j) => j > i && r.trim().startsWith(fence[1]!))
      if (close === -1) {
        blocks.push({ kind: 'markdown', text: rows.slice(i).join('\n') })
        break
      }
      blocks.push({ kind: 'code', language: fence[2] || undefined, source: rows.slice(i + 1, close).join('\n') })
      i = close + 1
      continue
    }
    if (row.trim() === '') {
      blocks.push({ kind: 'blank' })
      i += 1
      continue
    }
    const group: string[] = []
    while (i < rows.length && rows[i]!.trim() !== '' && !FENCE.test(rows[i]!)) group.push(rows[i++]!)
    blocks.push(groupBlock(group))
  }
  return blocks
}

const colors = (line: Line): boolean => line.some(span => span.role !== undefined && span.role !== 'marker')

/** True when the reply has something this mod colors; otherwise the engine draws it as is. */
export const hasColor = (blocks: Block[]): boolean =>
  blocks.some(b => b.kind === 'table' || (b.kind === 'lines' && b.lines.some(colors)))
