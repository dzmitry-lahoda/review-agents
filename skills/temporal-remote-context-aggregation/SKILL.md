---
name: temporal-remote-context-aggregation
description: Aggregate time-ordered remote project context for code review, including GitHub PR descriptions, review comments, linked issues, CI results, project-management tasks, design links, and prior decisions. Use when a review needs external discussion history, issue references, decision context, or a chronological task narrative before judging code changes.
---

# Temporal Remote Context Aggregation

## Goal

Build a compact, chronological context packet that explains why a change exists, what reviewers already discussed, and which claims need verification in the code or database.

## Inputs

Collect whichever sources are available:

- PR or merge request URL, number, branch, or commit range.
- Issue tracker links, project-management task IDs, design docs, incident links, or Slack/email references.
- CI run links and failure summaries.
- The review objective and any suspected risk areas.

Do not block on missing sources. Record gaps explicitly.

## Procedure

1. Identify the canonical review object: PR, branch, commit range, or issue.
2. Read the title, description, linked issues, labels, requested reviewers, and changed-file summary.
3. Read review threads and comments in chronological order. Separate resolved discussion from unresolved action.
4. Follow only links that affect the review decision: design rationale, bug reports, incident notes, schema docs, rollout plans, and CI failures.
5. Extract claims that must be checked against code or runtime evidence.
6. Emit a small context bundle into the active working directory.

## Output Files

Write these files when the workflow has a working directory:

- `remote-context.md`: concise chronological summary.
- `review-claims.md`: claims to verify, each with source link or source label.
- `open-questions.md`: missing context, ambiguous requirements, and access gaps.
- `remote-tasks.md`: action items already requested by humans.

## Summary Format

Use this structure:

```markdown
# Remote Context

## Timeline
- YYYY-MM-DD: Event, decision, or comment summary. Source: <link or label>

## Review-Relevant Claims
- Claim: ...
  Evidence needed: ...

## Existing Reviewer Requests
- Request: ...
  Status: unresolved | resolved | unclear

## Open Questions
- ...
```

## Review Rules

- Do not treat PR descriptions as truth; convert them into claims.
- Prefer direct source links or stable identifiers over vague summaries.
- Do not include long quotes unless exact wording changes the technical interpretation.
- Keep the packet short enough for downstream review agents to load without losing code context.
