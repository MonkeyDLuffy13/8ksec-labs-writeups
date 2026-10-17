# PortSwigger Web Security Academy — SQL Injection Labs

Personal solutions for the 18 official **SQL injection** labs of the
[PortSwigger Web Security Academy](https://portswigger.net/web-security/sql-injection).
Each write-up includes the goal, the injection point, step-by-step payloads,
and a short mitigation note.

## Labs

| # | Lab | Level | Official | Solution |
|---|-----|-------|----------|----------|
| 01 | SQL injection vulnerability in WHERE clause allowing retrieval of hidden data | Apprentice | [lab](https://portswigger.net/web-security/sql-injection/lab-retrieve-hidden-data) | [01](01-retrieve-hidden-data.md) |
| 02 | SQL injection vulnerability allowing login bypass | Apprentice | [lab](https://portswigger.net/web-security/sql-injection/lab-login-bypass) | [02](02-login-bypass.md) |
| 03 | UNION attack, determining the number of columns returned by the query | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-determine-number-of-columns) | [03](03-union-determine-number-of-columns.md) |
| 04 | UNION attack, finding a column containing text | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-find-column-containing-text) | [04](04-union-find-column-containing-text.md) |
| 05 | UNION attack, retrieving data from other tables | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-retrieve-data-from-other-tables) | [05](05-union-retrieve-data-from-other-tables.md) |
| 06 | UNION attack, retrieving multiple values in a single column | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/union-attacks/lab-retrieve-multiple-values-in-single-column) | [06](06-union-retrieve-multiple-values-single-column.md) |
| 07 | Querying the database type and version on Oracle | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-querying-database-version-oracle) | [07](07-db-version-oracle.md) |
| 08 | Querying the database type and version on MySQL and Microsoft | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-querying-database-version-mysql-microsoft) | [08](08-db-version-mysql-microsoft.md) |
| 09 | Listing the database contents on non-Oracle databases | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-listing-database-contents-non-oracle) | [09](09-listing-contents-non-oracle.md) |
| 10 | Listing the database contents on Oracle | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/examining-the-database/lab-listing-database-contents-oracle) | [10](10-listing-contents-oracle.md) |
| 11 | Blind SQL injection with conditional responses | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-conditional-responses) | [11](11-blind-conditional-responses.md) |
| 12 | Blind SQL injection with conditional errors | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-conditional-errors) | [12](12-blind-conditional-errors.md) |
| 13 | Blind SQL injection with time delays | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-time-delays) | [13](13-blind-time-delays.md) |
| 14 | Blind SQL injection with time delays and information retrieval | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-time-delays-info-retrieval) | [14](14-blind-time-delays-info-retrieval.md) |
| 15 | Blind SQL injection with out-of-band interaction | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-out-of-band) | [15](15-blind-oob-interaction.md) |
| 16 | Blind SQL injection with out-of-band data exfiltration | Expert | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-out-of-band-data-exfiltration) | [16](16-blind-oob-data-exfiltration.md) |
| 17 | Visible error-based SQL injection | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/blind/lab-sql-injection-visible-error-based) | [17](17-visible-error-based.md) |
| 18 | SQL injection with filter bypass via XML encoding | Practitioner | [lab](https://portswigger.net/web-security/sql-injection/lab-sql-injection-with-filter-bypass-via-xml-encoding) | [18](18-filter-bypass-xml-encoding.md) |

> All lab URLs were verified live (HTTP 200) at the time of writing.

## Universal methodology

Every UNION lab follows the same loop — memorize it once, reuse everywhere:

1. **Injectability** — break the quote, confirm with a tautology (`' OR 1=1--`).
2. **Column count** — `' ORDER BY n--` (increase until error) or
   `' UNION SELECT NULL,NULL,...--` (add NULLs until OK).
3. **Column types** — replace NULLs with `'a'` one position at a time.
4. **Enumerate** — version (`@@version` / `v$version`), tables
   (`information_schema.tables` / `all_tables`), columns (`...columns` /
   `all_tab_columns`).
5. **Extract** — dump target columns, concatenating when only one text
   column exists (`username||':'||password`).
6. **Deliver** — log in as `administrator`.

Blind variants swap the *response channel* only: boolean content
(lab 11) → forced errors (12) → time delays (13/14) → out-of-band
interactions (15/16) → reflected errors (17).

## Note on a common lab list mismatch

Some circulating lab lists (including the `data.json` tracker this repo was
built from) contain three SQLi labs that **do not exist** on the Academy:

- *"SQL injection with filter bypass via escaped string processing"*
- *"SQL injection with filter bypass via comment injection"*
- *"SQL injection attack, listing the database contents on PostgreSQL"*

Their URLs return 404 and no lab page exists under any slug — the real
series is the 18 labs above (the PostgreSQL listing technique is covered by
the non-Oracle lab, which runs on PostgreSQL).
