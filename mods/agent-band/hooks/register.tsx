import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import type { AgentRun } from '../types'
import { chipOf, finish, outcomeOf, stillRunning } from './format'

const runs = atom({ plugin: 'agent-band', key: 'runs' } as const, [] as AgentRun[])
const now = atom({ plugin: 'agent-band', key: 'now' } as const, 0)

const COLOR = { running: 'suggestion', done: 'success', failed: 'error', aborted: 'inactive' } as const

type Ticker = { timer?: Timer }

async function tick($: EngineInterface, ticker: Ticker) {
  const at = await $.clock.now()
  await update($, now, () => at)
  if (stillRunning(await read($, runs)).length > 0) return
  ticker.timer?.cancel()
  ticker.timer = undefined
}

function startTicker($: EngineInterface, ticker: Ticker) {
  ticker.timer ??= $.clock.every(1000, () => void tick($, ticker))
}

export const register: Register = on => {
  const ticker: Ticker = {}

  on('session.start', async ($, e, next) => {
    const started = await next(e)
    if (stillRunning(await read($, runs)).length > 0) startTicker($, ticker)
    return started
  })

  on('agent.spawn', async ($, e, next) => {
    const spawned = await next(e)
    if (spawned.deny !== undefined || !spawned.agentId) return spawned
    const run: AgentRun = { id: spawned.agentId, type: e.subagentType, description: e.description, startedAt: await $.clock.now() }
    await update($, runs, list => [...list, run])
    startTicker($, ticker)
    return spawned
  }).catch(($, e, next) => next(e))

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (!e.agentId) return done
    const id = e.agentId
    const at = await $.clock.now()
    await update($, runs, list => finish(list, id, at, outcomeOf(e.reason)))
    return done
  })

  on('prompt.submit', async ($, e, next) => {
    await update($, runs, stillRunning)
    return next(e)
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const list = await read($, runs)
    if (e.props.hasSurvey || list.length === 0) return next(e)
    const at = await read($, now)
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="row" flexWrap="wrap" columnGap={2}>
        {list.map(run => {
          const chip = chipOf(run, at)
          return (
            <Text key={run.id} color={COLOR[chip.state]}>
              {chip.mark} {chip.label} <Text dimColor>{chip.elapsed}</Text>
            </Text>
          )
        })}
      </Box>
    )
  })

  on('ui.render', { component: 'ToolUse', props: { tool: 'Agent' } }, async ($, e, next) => {
    const row = await next(e)
    const { Box } = $.ui.resolve(e)
    return (
      <Box borderStyle="quote" borderColor={e.props.isErrored ? 'error' : 'suggestion'}>
        {row}
      </Box>
    )
  })
}
