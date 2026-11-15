// Every color reply-color draws. Change a color here and nowhere else.
// A value is a six-digit hex or one of Claude Code's theme keys ('success', 'inactive', ...).
// Soft preset: lower saturation than the first version, which read too sharp on a dark terminal.
export const PALETTE = {
  h1: '#8fa6d6',
  h2: '#8db6c4',
  h3: '#ab9cc8',
  bold: '#cdb184',
  code: '#a6bd94',
  path: '#8cb8ae',
  header: '#8fa6d6',
  border: '#5a5f72',
  marker: '#5a5f72',
  // Your own prompt row: a plum band with a left bar, so it is easy to spot when scrolling back.
  // Kept off yellow on purpose: replies already use yellow for bold.
  promptBg: '#3a2d48',
  promptFg: '#efe6fa',
  promptBar: '#b9a3d9',
} as const

export type Role = keyof typeof PALETTE
