# Challenge 04 — ClearRoute

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Network traffic interception

## Goal

The app sends an outgoing **POST** request containing the flag — intercept
it by first evading the app's interception checks.

## Approach

1. **Proxy the device** through Burp (Wi-Fi proxy or `rvictl` + upstream
   rules) and browse the app to map endpoints.
2. The app likely includes certificate pinning or a proxy-detection check —
   clear it first:
   - **SSL Kill Switch 3** (jailbroken), or
   - Frida pinning bypass (see the script pack), or
   - re-sign a patched IPA with the pinning class swizzled out.
3. Browse every screen with the proxy live. The POST carrying the flag
   appears — read its body (`flag=...` JSON/form field).
4. Submit the flag — lab solved.

## Notes

- If nothing appears, trigger every app feature (search, sync, upload) —
  the POST fires on a specific action.
- Keep Burp's response rewriting off until the POST is identified; then you
  can also intercept the response if the challenge requires interaction.
