import type { Register } from 'claude-code'

import { hasColor, parse, tableLines } from './blocks'
import type { Block, Line } from './blocks'
import { PALETTE } from './palette'

const BOLD = new Set(['h1', 'h2', 'h3', 'bold', 'header'])
// The reply's bullet column, as the built-in renderer leaves it.
const GUTTER = 2

// Prompts the person typed: at the terminal (composer) or from a phone (bridge).
const OWN_PROMPT = new Set(['composer', 'bridge'])

export const register: Register = on => {
  on('ui.render', { component: 'UserMessage' }, async ($, e, next) => {
    if (e.surface !== 'terminal' || !OWN_PROMPT.has(e.props.origin.kind)) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" backgroundColor={PALETTE.promptBg} paddingRight={1}>
        <Box width={GUTTER} flexShrink={0}>
          <Text color={PALETTE.promptBar} backgroundColor={PALETTE.promptBg}>▌</Text>
        </Box>
        <Box width={GUTTER} flexShrink={0}>
          <Text color={PALETTE.promptFg} backgroundColor={PALETTE.promptBg} bold>❯</Text>
        </Box>
        <Box flexGrow={1}>
          <Text color={PALETTE.promptFg} backgroundColor={PALETTE.promptBg}>{e.props.text}</Text>
        </Box>
      </Box>
    )
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    if (e.surface !== 'terminal' || e.props.isSummary) return next(e)
    const blocks = parse(e.props.text)
    if (!hasColor(blocks)) return next(e)

    const { Box, Text, Code, Markdown } = $.ui.resolve(e)
    const columns = (e.viewport?.columns ?? 80) - GUTTER

    const drawLine = (line: Line, i: number) => (
      <Text key={String(i)}>
        {line.map(span =>
          span.role ? (
            <Text color={PALETTE[span.role]} bold={BOLD.has(span.role)}>
              {span.text}
            </Text>
          ) : (
            span.text
          ),
        )}
      </Text>
    )

    const drawBlock = (block: Block, i: number) => {
      const key = String(i)
      if (block.kind === 'blank') return <Text key={key}> </Text>
      if (block.kind === 'lines') return <Box key={key} flexDirection="column">{block.lines.map(drawLine)}</Box>
      if (block.kind === 'code') return <Code key={key} source={block.source} language={block.language} />
      if (block.kind === 'markdown') return <Markdown key={key} text={block.text} />
      const lines = tableLines(block, columns)
      if (!lines) return <Markdown key={key} text={block.source} />
      return <Box key={key} flexDirection="column">{lines.map(drawLine)}</Box>
    }

    return (
      <Box flexDirection="row">
        <Box width={GUTTER} flexShrink={0}>
          <Text>{e.props.isFirstOfReply ? '●' : ' '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1}>
          {blocks.map(drawBlock)}
        </Box>
      </Box>
    )
  })
}
