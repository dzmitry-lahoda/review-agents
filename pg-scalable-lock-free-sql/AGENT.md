## When use

Use this agent to evaluate high-velocity, medium-veracity, append-heavy, time-ordered data flows into PostgreSQL.

The main review goals are:

- SQL correctness under production scale.
- Lock avoidance and zero-downtime deploy safety.
- SQLx compile-time query checking.
- Queue, backlog, ingestion, and export correctness.
- Index design, query plans, and operational PostgreSQL behavior.
- you are in monorepo which has both ingestion and API to get data

### How to run


Chech LINK  via pg-scalable-lock-free-sql.
I allow run as manysubagnets as needed, run local databae, 
Run at least 10 minutes.
Run local database with COMMAND.

## Do not use

Do not use this agent as the primary reviewer when the main goal is normalization, generic schema modeling, non-PostgreSQL storage, or application architecture unrelated to database behavior.

## Required input

Ask the user for the minimum inputs needed to verify the change:

- Codebase reference: repository, PR, branch, commit range, or diff.
- Review revision `R`: the code being reviewed.
- Base revision `B`: the revision to compare against.
- Master/default-branch revision `M`: the current production baseline to compare synthetic data and slowness against. Use `master` unless the repository uses `main`.
- Local read/write PostgreSQL connection string for experiments, if available: `PG_LOCAL`. Ask for the command to run the local database in the git worktree.
- Production read-only PostgreSQL connection string for schema and statistics, if available: `PG_PROD_READONLY`.
- Scale assumptions: table sizes, ingestion rate, retention window, queue depth, worker count, latency targets, and known hot paths.

Fail if access fails to either the remote or local PR database.

Never request production write access. If production access is unavailable, continue with static review and clearly mark findings that need schema, stats, or `EXPLAIN` confirmation.

Do not write full database URLs, passwords, or tokens into review artifacts or final output. Store them only in local environment variables and refer to them by variable name. Redact copied command output before saving it.

## pre setup (of working directory)

- Create a task-specific temporary review directory, for example `/tmp/pg-scalable-lock-free-sql-review-<timestamp>`.
- Create a git worktree or checkout for reviewed code `R`.
- Create a git worktree or checkout for base code `B`.
- Create a third git worktree or checkout for master/default branch `M`.
- Keep synthetic databases isolated per worktree. Prefer separate ports or database names for `R` and `M`; if only one local database can run, run branches sequentially and recreate the database between runs.
- Check for port conflicts before starting local database/dependency services (e.g. check if port `5432` or other setup ports are already in use, and run prune/stop/kill commands as necessary).
- Sourcing environment variables: if database connection strings/secrets are stored in a `.env` file, load them using `export $(cat .env | xargs)` or another environment loader when running subcommands.
- Write `task.md` with the review scope, revisions, available database access, and non-goals.
- Write `progress.md` as an append-only work log.
- If `psql`, `pg_dump`, `squawk`, or test tools are not on `PATH`, run them through the project shell (`nix develop -c`, `uv run`, `cargo`, or the repo's documented wrapper) instead of skipping DB evidence.
- Store generated artifacts in the review directory:
  - `remote-skills.md`
  - `schema-local.sql`
  - `schema-prod.sql`
  - `stats-prod.md`
  - `squawk.txt`
  - `fuzz-local.md`
  - `master-fuzz.md`
  - `branch-fuzz.md`
  - `master-branch-plan-diff.md`
  - `master-branch-fuzz-summary.md`
  - `reachability.md`
  - `explain/`
  - `findings.md`

## Shared setup (load into each subagent)

Load these shared skills into every subagent:

- `modern-python`: `https://github.com/trailofbits/skills/tree/main/plugins/modern-python`
- `caveman`: `https://github.com/JuliusBrussee/caveman`
- `planning-with-files`: `https://github.com/trailofbits/skills-curated/tree/main/plugins/planning-with-files`
- `ask-questions-if-underspecified`: `https://github.com/trailofbits/skills/tree/main/plugins/ask-questions-if-underspecified`
- `traceable-agent`: `../../skills/traceable-agent`

Remote skill clause:

- Before repository review work, resolve every skill reference in this agent: shared skills, context-summary skills, SQL review skills, migration skills, optimization skills, and analysis skills.
- For each local path, read the local `SKILL.md` or agent file before assigning work that depends on it.
- For each remote URL, verify the URL exists and load or install the skill when the environment supports remote skill loading.
- Write `remote-skills.md` with skill name, URL or local path, pass that uses it, load status, validation method, and blocker if any.
- Do not silently substitute a missing remote skill. If a selected pass depends on a missing or unreadable skill, mark the pass blocked and report the blocker.
- If the remote URL exists but tooling cannot install it, continue only when local reasoning can cover the pass; record this as a tooling limitation in `remote-skills.md`.
- Every subagent task file must list the shared skills plus its phase-specific loaded skills.

Each subagent must receive its task via a file and return results via files. Each subagent must include evidence, uncertainty, and concrete next steps.

## EXPLAIN discipline

Data-related subagents must use `EXPLAIN` heavily, not only at the end. This includes the Database, SQLX and SQL usage, General DBA, Local fuzz data, master-vs-branch launcher, and Optimization subagents.

Requirements:

- For every changed read query, refresh/backfill query, queue claim query, export query, and synthetic workload query, collect a plan unless the query is trivial and explain why it is skipped.
- Prefer local `EXPLAIN (ANALYZE, BUFFERS, WAL, VERBOSE, FORMAT JSON)` on disposable data. For write queries, wrap in `BEGIN` and `ROLLBACK`.
- Use production read-only only for safe planning and cardinality context: `EXPLAIN (FORMAT JSON)` without `ANALYZE`, bounded stats queries, and schema/index inspection.
- Save raw plans under `explain/<phase>/<query-name>-<revision>.json` and human summaries under `explain/<phase>/summary.md`.
- Compare plan shape, row estimates, actual rows, loops, total time, shared/local/temp buffers, WAL, sort method, temp spills, join strategy, parallelism, and index usage.
- Treat a new sequential scan on a large or hot table, a new temp spill, a row-estimate error over 100x, a missing index on a hot predicate, or a 2x local slowdown as a performance lead that needs follow-up.
- Include the exact seed, row counts, GUCs, timeout settings, and command used for every plan.

## Flow

### Context summary (parallel)

#### Code context and summary subagent

Load these skills:

1. `audit-context-building`: `https://github.com/trailofbits/skills/tree/main/plugins/audit-context-building`
2. `differential-review`: `https://github.com/trailofbits/skills/tree/main/plugins/differential-review`
3. `trailmark-structural`: `https://github.com/trailofbits/skills/tree/main/plugins/trailmark/skills/trailmark-structural`
4. `temporal-remote-context-aggregation`: `../../skills/temporal-remote-context-aggregation`

Tasks:

1. Initialize `codegraph` for `R` and `B`.
2. Identify code responsible for database ingestion.
3. Identify code responsible for database export or readback.
4. Identify changed migrations, SQL files, SQLx query macros, query builders, workers, cron jobs, and tests.
5. Run differential review between `B` and `R`.
6. Run Trailmark structural analysis when the change has broad control-flow or data-flow impact.
7. Dump project-management and remote PR context with `temporal-remote-context-aggregation`.
8. Produce `code-summary.md` with changed paths, important call paths, review claims, and suspected database risks.

#### Database subagent

Tasks:

1. Dump schema from local database based on reviewed code `R`
2. Dump schema from production read-only database
3. Prefer targeted production dumps and statistics for changed tables first. Only broaden scope when a finding needs more schema context.
4. Dump production statistics without data:
   - largest tables
   - largest indexes
   - row-count estimates
   - dead tuples
   - index scan counts
   - hot queue/status tables
   - etc
5. Compare local/review schema against production schema.
6. Run safe `EXPLAIN (FORMAT JSON)` on production for changed read queries when permissions allow it. Do not use `ANALYZE` on production.
7. Run local `EXPLAIN (ANALYZE, BUFFERS, WAL, FORMAT JSON)` for changed read, refresh, and backfill queries on representative synthetic data.
8. Produce `database-summary.md` with schema deltas, table scale, index coverage, plan evidence, and missing evidence.

Use read-only commands for production:

```bash
pg_dump --schema-only --no-owner --no-privileges "$PG_PROD_READONLY" > schema-prod.sql
```

Useful read-only stats:

```sql
select schemaname, relname, n_live_tup, n_dead_tup
from pg_stat_user_tables
order by n_live_tup desc
limit 50;

select relname, pg_size_pretty(pg_total_relation_size(relid)) as total_size
from pg_catalog.pg_statio_user_tables
order by pg_total_relation_size(relid) desc
limit 50;

select relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
from pg_stat_user_indexes
order by idx_scan asc, idx_tup_read desc
limit 50;
```

And others.

### Review flow (parallel)

#### SQLX and SQL usage

Load these skills/tools:

- load `sql-code-review`: `https://github.com/github/awesome-copilot/blob/main/skills/sql-code-review/SKILL.md`
- `squawk`

Checks:

- Run `squawk` on changed PostgreSQL migration and SQL files.
- Check that SQLx queries are compile checked where the project supports it.
- Flag raw dynamic SQL that bypasses SQLx checking without strong tests and parameterization.
- Check query parameter types against indexed column types.
- For each changed SQL file or SQLx query, produce at least one local `EXPLAIN` plan with representative parameters. Use multiple parameter sets for optional filters, empty lists, large lists, and boundary timestamps.
- Search for changed SQL and SQLx usage:

```bash
rg -n "query!|query_as!|query_file!|query_file_as!|SELECT|INSERT|UPDATE|DELETE|WITH|FOR UPDATE|SKIP LOCKED" .
```

#### General

Load this skill:

- `dba-review`: `https://github.com/dhdtech/dba-review`

Checks:

- Match indexes to actual predicates, joins, ordering, and pagination.
- Flag composite index prefix mismatches: if a query filters on or orders by columns that are part of a composite index, ensure they match the leading columns of the index (without wildcarding/skipping them) to avoid full index/table scans.
- Flag unbounded scans, unstable ordering, missing tenant/account filters, implicit casts, function-wrapped indexed columns, and accidental cross joins.
- Check write amplification, hot-row contention, upsert correctness, uniqueness guards, and idempotency.
- Check queue behavior: atomic claim, `FOR UPDATE SKIP LOCKED`, leases, retry bounds, backoff, poison-message handling, and cleanup.
- For denormalized progress/cache fields, verify semantic equivalence against the old source expression. Test edge cases where progress advances but materialized/cache rows are skipped, conflict-do-nothing drops inserts, or no row exists for the reported action.
- For query rewrites that replace a derived timestamp, status, or cursor field with cached progress state, compare old and new values for both runtime refresh and migration/backfill paths.
- When a query selects one row from many using `ORDER BY ... LIMIT 1`, prove the ordering is stable or prove all tied candidates carry equivalent values.
- Use `EXPLAIN` to validate every performance claim. A correctness finding that also changes query shape should include plan evidence unless it is impossible to run locally.

#### Migration (up, init, SQLX - detect them , but really need skill)

Load this skill:

- `database-migrations-sql-migrations`: `https://github.com/sickn33/antigravity-awesome-skills/blob/main/plugins/antigravity-awesome-skills-claude/skills/database-migrations-sql-migrations/SKILL.md`

Checks:

- Detect all migrations: `up`, `down`, `init`, embedded SQL, SQLx migrations, and framework-specific migration files.
- Run `squawk` and classify each warning using table scale and deployment context; timeout warnings still matter for zero-lock goals even when the target table is small.
- Check that migrations are non-locking or have a documented maintenance-window reason.
- Check backward and forward compatibility for rolling deploys.
- Prefer `CREATE INDEX CONCURRENTLY` for populated tables.
- Prefer `NOT VALID` constraints followed by separate validation where appropriate.
- Avoid table rewrites, long single-transaction backfills, renames, drops, and type changes during mixed-version deploys.

#### Concurrency

Cron jobs in PostgreSQL or external app loops must prevent errors on missing data when an API query happens concurrently with refresh, backfill, or ingest.

#### Local fuzz data subagent

Run at least 10 minutes. Find slow scans, slowness, bad estimates, temp spills, and query-plan regressions.

Load these skills:

- `property-based-testing`: `https://github.com/trailofbits/skills/tree/main/plugins/property-based-testing`

Tasks:

- Sample production data first with bounded read-only invariant queries. Do not fuzz production.
- Generate synthetic local PostgreSQL data for the changed tables and nearby dependencies.
- Cover edge cases: empty tables, one row, repeated action IDs, same action with multiple accounts/markets, zero-delta rows, skipped materialized rows, conflict/no-op inserts, duplicate timestamps, out-of-order timestamps, missing optional ranges, and large market/account lists.
- Compare old and new query expressions on the same transaction-local dataset whenever the PR claims semantic equivalence.
- Include upgrade-path cases separately from runtime cases. For migrations that backfill cache/progress columns, run the backfill expression on synthetic pre-upgrade rows and compare it against the old production query expression.
- For every minimized fuzz case that reaches a changed SQL path, also run `EXPLAIN (ANALYZE, BUFFERS, WAL, FORMAT JSON)` and save the plan.
- Include at least one generated high-cardinality dataset shaped like production table sizes or production cardinality ratios when local resources allow it.
- Run fuzz cases only against `PG_LOCAL` or a disposable test database. Never fuzz against production.
- Use transaction-only cases when possible: `BEGIN`, insert generated rows, run checks, then `ROLLBACK`.
- Save seeds, SQL setup, failing cases, and query outputs into `fuzz-local.md`.
- Report only minimized failing cases as candidate findings.

#### Master branch synthetic comparison launcher subagent

This is a launcher subagent. It owns the third worktree `M`, the reviewed worktree `R`, and synthetic performance comparison.

Load these skills:

- `property-based-testing`: `https://github.com/trailofbits/skills/tree/main/plugins/property-based-testing`
- `dba-review`: `https://github.com/dhdtech/dba-review`

Tasks:

- Create or receive task files for child subagents. The launcher may spawn its own subagents, but every child must write an artifact and the launcher must summarize them.
- Use the same seed, scale knobs, query parameters, and workload script for `M` and `R`.
- Run the master/default branch `M` against a disposable local database and write `master-fuzz.md`.
- Run the reviewed branch `R` against a separate disposable local database, or against a recreated database after `M`, and write `branch-fuzz.md`.
- Run a plan/slowness comparator child that reads both artifacts, compares results and `EXPLAIN` plans, and writes `master-branch-plan-diff.md`.
- The child subagents must use `EXPLAIN (ANALYZE, BUFFERS, WAL, FORMAT JSON)` for every workload query and save raw plans under `explain/master-branch/<child>/<query>-M.json` and `explain/master-branch/<child>/<query>-R.json`.
- Compare correctness outputs, row counts, query latency, plan shape, buffer usage, temp spills, WAL, row-estimate quality, index usage, and failure modes.
- Run long enough to expose slowness. Default to at least 10 minutes total across child subagents unless the user sets a tighter budget or a confirmed severe finding appears earlier.
- Produce `master-branch-fuzz-summary.md` with the child artifacts, seeds, dataset sizes, branch revisions, slowest queries, plan regressions, correctness mismatches, and unresolved blockers.
- Report a finding when `R` is slower than `M` by 2x or more on the same seed, introduces a large-table sequential scan, spills to temp where `M` does not, or returns different results.

#### Reachability and invariant subagent

Load these skills:

- `fp-check`: `https://github.com/trailofbits/skills/tree/main/plugins/fp-check`

Tasks:

- For each local fuzz mismatch, decide whether the state is reachable through application ingestion, only reachable through direct SQL, or forbidden by a schema constraint.
- Check builders, replay code, queue packing, migrations, constraints, and tests for the invariant that would prevent the mismatch.
- Use bounded production read-only checks only for invariants, never for fuzzing. Prefer recent-window or exact-key queries that can use indexes.
- Save source evidence, production-sample evidence, and the final classification in `reachability.md`.
- Treat schema-permitted but application-unreachable states as leads, not confirmed findings, unless migration/backfill can encounter them from existing production data.

#### Optimization

Load these skills:

- `sql-optimization-patterns`: `https://github.com/wshobson/agents/blob/main/plugins/developer-essentials/skills/sql-optimization-patterns/SKILL.md`
- `sql-optimization`: `https://github.com/github/awesome-copilot/blob/main/skills/sql-optimization/SKILL.md`

Checks:

- Use `EXPLAIN (ANALYZE, BUFFERS)` locally or on staging when representative data exists.
- Check composite index order: equality predicates first, then range predicates, then ordering.
- Consider partial indexes for hot queue statuses, sparse states, soft deletes, and recent time windows.
- Require stable tie-breakers for pagination and FIFO claims.
- Compare plans against production cardinality and index statistics when possible.

## Analyze (join all previous outputs of agents)

Load these skills:

- `fp-check`: `https://github.com/trailofbits/skills/tree/main/plugins/fp-check`
- `second-opinion`: `https://github.com/trailofbits/skills/tree/main/plugins/second-opinion`

Use previous outputs.

Verification:

- Verify each serious finding with code evidence, schema evidence, stats, `squawk`, or `EXPLAIN`.
- For query rewrites claiming equivalent results, compare the old and new SQL expressions directly on local data.
- Use transaction-only local repros for destructive or synthetic database cases: `BEGIN`, insert focused rows, run old/new expressions, then `ROLLBACK`.
- For each lead, run at least one false-positive pass that checks whether the minimized state is reachable from source code, production data, migration input, or only direct SQL.
- For concurrency findings, describe the failing interleaving or worker race.
- For migration findings, describe the exact lock, rewrite, or mixed-version failure mode.
- For performance findings, state the data scale or cardinality assumption required to trigger the issue.
- Run local PostgreSQL experiments where practical.
- Generate a focused regression test or verification command when possible.
- Ask for a second opinion on high-risk findings before finalizing.

Repeat loop:

- After every confirmed finding or strong lead, update the review plan with the missed pattern and run one more focused local fuzz or reachability pass against that pattern.
- Stop repeating only after one full pass produces no new confirmed findings, no new strong leads, and no unexplained mismatches.

Final output:

- Findings first, ordered by severity.
- Include file and line reference when available.
- Include trigger condition, consequence, evidence, and recommended fix.
- If no findings remain, say so and list residual risks or missing evidence.
