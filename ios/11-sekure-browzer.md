# Challenge 11 — SekureBrowzer

> **Expert** · [Official lab](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** screenshot exfiltration · works on non-jailbroken devices

## Goal

A browser app captures screenshots and supports deep linking. Build a
malicious webpage that silently triggers the browser and **exfiltrates all
screenshots** — no extra user interaction, and it must work on
**non-jailbroken** devices.

## Solution

1. Map the browser's deeplink (Info.plist → `CFBundleURLTypes`), e.g.
   `sekurebrowzer://open?url=...`.
2. The app stores captures in its sandbox and (critically) exposes them via
   a deeplink-routable preview path — screenshots are reachable through
   `Documents/` or a `file:`-backed preview route.
3. Craft the malicious page: first silently drive the browser to visit the
   screenshots (generating them), then leverage the iOS pasteboard/preview
   rendering weakness to leak the images out-of-band:

```html
<script>
  // 1) open the browser at the captures route
  location = 'sekurebrowzer://open?url=<captures-path>';
</script>
```

4. The accepted solution path: chain the deeplink with the app's screenshot
   preview rendering so the captured images load into a page you control —
   then collect them from your server.

Deliver the page to the target (phishing link); when it is visited once,
all screenshots are exfiltrated — lab solved.

## Mitigation

Mark screenshot files `NSFileProtectionComplete`, exclude them from any
URL-routable preview, and require user confirmation before opening external
content.
