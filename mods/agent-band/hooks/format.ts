import type { AgentOutcome, AgentRun } from '../types'

const MAX_DESCRIPTION = 24

export const clockOf = (ms: number): string => {
  const seconds = Math.max(0, Math.floor(ms / 1000))
  const minutes = Math.floor(seconds / 60)
  return `${minutes}:${String(seconds % 60).padStart(2, '0')}`
}

export const shorten = (text: string, max = MAX_DESCRIPTION): string => {
  const chars = [...text.trim()]
  return chars.length > max ? `${chars.slice(0, max - 1).join('')}…` : chars.join('')
}

export const outcomeOf = (reason: string): AgentOutcome => {
  if (reason === 'answer') return 'done'
  if (reason === 'aborted') return 'aborted'
  return 'failed'
}

const MARK: Record<AgentOutcome | 'running', string> = { running: '▶', done: '✓', failed: '✗', aborted: '■' }

export type Chip = { mark: string; state: AgentOutcome | 'running'; label: string; elapsed: string }

export const chipOf = (run: AgentRun, now: number): Chip => {
  const state = run.outcome ?? 'running'
  const end = run.endedAt ?? Math.max(now, run.startedAt)
  return {
    mark: MARK[state],
    state,
    label: `${run.type}「${shorten(run.description)}」`,
    elapsed: clockOf(end - run.startedAt),
  }
}

export const finish = (runs: AgentRun[], id: string, at: number, outcome: AgentOutcome): AgentRun[] =>
  runs.map(run => (run.id === id && !run.outcome ? { ...run, endedAt: at, outcome } : run))

export const stillRunning = (runs: AgentRun[]): AgentRun[] => runs.filter(run => !run.outcome)
