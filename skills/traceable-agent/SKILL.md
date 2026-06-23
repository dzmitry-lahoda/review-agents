---
name: traceable-agent
description: "Run multi-step or multi-agent technical work with auditable local artifacts: task files, plans, progress logs, subagent inputs, subagent outputs, evidence, and final findings. Use when coordinating review agents, database audits, security reviews, CI investigations, or any work where decisions must be reproducible from files in a working directory."
---

# Traceable Agent

## Goal

Make review work reproducible. Every important task, assumption, command, evidence item, subagent assignment, and conclusion should be recoverable from files in the working directory.

## Working Directory

Create or reuse a task-specific directory. When running in environments with a designated artifact directory (e.g., `<appDataDir>/brain/<conversation-id>`), place audit artifacts there instead of `/tmp/` to ensure they are properly persisted and presented as user-facing artifacts.

Prefer these files:

- `task.md`: user request, scope, repositories, revisions, credentials available, and explicit non-goals.
- `plan.md`: current plan with status.
- `progress.md`: timestamped work log.
- `evidence.md`: commands, outputs, links, schemas, screenshots, logs, and other facts used for conclusions.
- `findings.md`: final findings or answer draft.
- `subagents/`: one subdirectory per delegated task.

## Procedure

1. Write `task.md` before substantial work.
2. Write or update `plan.md` for multi-step work.
3. Append to `progress.md` after each meaningful phase: context gathering, hypothesis, test, result, and decision.
4. Save raw or summarized evidence in `evidence.md` or nearby files. Include enough command output to support the conclusion.
   Redact secrets, full database URLs, tokens, cookies, and credentials; record the environment variable name instead.
5. For each subagent, create:
   - `subagents/<name>/task.md`: exact assignment, scope, and allowed tools.
   - `subagents/<name>/context.md`: minimal context needed for that task.
   - `subagents/<name>/result.md`: findings, evidence, uncertainty, and recommended next steps.
6. Merge subagent results by verifying their evidence. Do not copy unverified conclusions into final findings.

## Progress Log Format

Use append-only entries:

```markdown
## YYYY-MM-DD HH:MM TZ

Action: ...
Evidence: ...
Decision: ...
Next: ...
```

## Delegation Rules

- Give each subagent a narrow task with a clear artifact to produce.
- Pass raw inputs, not the desired answer.
- State whether the subagent may modify files, run tests, access network tools, or only review.
- Require file and line references for code findings.
- Require uncertainty notes when evidence is incomplete.

## Finalization

Before returning the final answer:

1. Check `plan.md` for unfinished required tasks.
2. Check `findings.md` against `evidence.md` for unsupported claims.
3. List any tests, data, credentials, or external context that were unavailable.
4. Keep the final response concise; leave detailed evidence in the working directory.
