# Lab 04 — SQL injection UNION attack, finding a column containing text

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-find-column-containing-text)

**Entry point:** `GET /filter?category=`

## Goal

Return an extra row containing the random string the lab provides
(e.g. `Pb4Nz2`), proving you can locate a text column.

## Solution

1. The query returns **3 columns** (from the previous lab's methodology).
2. The lab page gives you a random value — call it `<RANDOM>`.
3. Probe each column position with a test string until one renders:

```
'+UNION+SELECT+'a',NULL,NULL--     ← error: column 1 is not text
'+UNION+SELECT+NULL,'a',NULL--     ← works: column 2 accepts text
```

4. Put the lab's random string into the text column:

```
'+UNION+SELECT+NULL,'<RANDOM>',NULL--
```

5. The random string appears in the product list — lab solved.

## Notes

Testing with `'a'` (or `NULL`) position by position is the generic way to
map column data types before placing real data in a UNION attack.
