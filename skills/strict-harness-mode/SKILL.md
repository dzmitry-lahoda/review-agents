### Strict Orchestration Requirement

You MUST NOT execute these passes yourself. You MUST use the `invoke_subagent` tool to spawn child agents for EACH of the following roles in parallel. Wait for their responses using `schedule` or by yielding execution, then synthesize their artifacts. Failure to use `invoke_subagent` for these tasks is a violation of this agent's core instructions.