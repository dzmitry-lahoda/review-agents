#### SQLX and SQL usage (linter)

Load these skills/tools:

- load `sql-code-review`: `https://github.com/github/awesome-copilot/blob/main/skills/sql-code-review/SKILL.md`
- load https://github.com/github/awesome-copilot/blob/master/skills/postgresql-code-review/SKILL.md
- `squawk`
- `sqruff`

Checks:

- Run `squawk` on changed PostgreSQL migration and SQL files. Same using `sqruff`

- Check query parameter types against indexed column types.
-
- use modern SQL:2023 and modern PGSql when possible, dislike old constucts(assuming same performan or better)

```bash
rg -n "query!|query_as!|query_file!|query_file_as!|SELECT|INSERT|UPDATE|DELETE|WITH|FOR UPDATE|SKIP LOCKED" .
```
