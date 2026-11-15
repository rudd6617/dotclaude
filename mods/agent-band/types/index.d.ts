export type AgentOutcome = 'done' | 'failed' | 'aborted'

export type AgentRun = {
  id: string
  type: string
  description: string
  startedAt: number
  endedAt?: number
  outcome?: AgentOutcome
}

declare module 'claude-code' {
  interface PluginState {
    'agent-band': { runs: AgentRun[]; now: number }
  }
}
