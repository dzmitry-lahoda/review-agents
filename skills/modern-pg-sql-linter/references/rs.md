# SQLX

- Check that SQLx queries are compile checked where the project supports it.
- Flag raw dynamic SQL that bypasses SQLx checking without strong tests and parameterization.
- all SQL files should be separate files, not inside Rust