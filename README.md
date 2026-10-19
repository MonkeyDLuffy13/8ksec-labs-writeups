# 8kSec Labs — Write-ups & Solutions

Personal write-up repository for challenges from
[8kSec Academy](https://academy.8ksec.io/) and
[8kSec Battlegrounds](https://battlegrounds.8ksec.io/), covering **Android**
and **iOS** application exploitation: exposed components, IPC abuse,
confused-deputy attacks, Flutter/TLS bypasses, runtime instrumentation with
Frida, method swizzling, GPS spoofing, and deeplink abuse.

## Android — Solved Labs

| Lab | Category | Vulnerability Class | Key Tools | Write-up |
|-----|----------|--------------------|-----------|----------|
| **FactsDroid** | Flutter app exploitation | Missing TLS validation → MITM response tampering (root check + Flutter TLS bypass) | jadx, apktool, blutter, Frida, mitmproxy | [factsdroid/](factsdroid/) |
| **AndroDialer** | Android component abuse | Confused deputy via exported activity + hardcoded auth token | jadx, adb, deep links | [androdialer/](androdialer/) |
| **AndroPseudoProtect** | Android IPC abuse | Exported receiver/service authenticated by an observable runtime secret | JADX, Frida, ADB | [andropseudoprotect/](andropseudoprotect/) |
| **DroidCave** | Android IPC abuse | Exposed ContentProvider: arbitrary SQL injection + IPC-toggleable encryption | adb, JADX | [droidcave/](droidcave/) |
| **DroidPass** | Flutter static analysis | Hardcoded AES base key in Dart AOT snapshot → database decryption | strings, Ghidra, Python | [droidpass/](droidpass/) |
| **DroidView** | WebView + IPC abuse | Exported Tor controller + WebView redirect → real-IP and inventory exfiltration | JADX, adb, intent URLs | [droidview/](droidview/) |
| **DroidWars** | Dynamic code loading | Malicious DexClassLoader plugin inheriting host permissions | JADX, d8, Python server | [droidwars/](droidwars/) |
| **GeofenceGamble** | Location spoofing | Geofence + anti-cheat evasion with realistic GPS traces | mock provider, Frida | [geofencegamble/](geofencegamble/) |
| **ReconDroid** | Browser-based attack | intent:// URL from web page → exported export-component abuse | Chrome intents, JADX | [reconduroid/](reconduroid/) |
| **BorderDroid** | Kiosk / device-policy abuse | Hidden volume-key backdoor + unauthenticated HTTP unlock + PIN brute force | adb, curl, arp-scan | [borderdroid/](borderdroid/) |

## iOS — Application Exploitation Challenges

Write-up guides for the 11 challenges of the free
[iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
course — see [ios/](ios/) for the full index.

## Repository Structure

```
.
├── factsdroid/              # 8kSec Academy — Android Application Exploitation
│   ├── README.md            # Full walkthrough
│   ├── screenshots/         # Challenge-solved proof
│   └── artifacts/           # mitmproxy session log
├── androdialer/             # 8kSec Battlegrounds
│   ├── README.md            # Solution write-up
│   └── poc/                 # Proof-of-concept exploit app source
├── andropseudoprotect/      # 8kSec Battlegrounds
│   ├── README.md            # Solution write-up
│   └── payloads.md          # Quick-reference payloads
├── droidcave/               # 8kSec Battlegrounds
│   ├── README.md            # Solution write-up
│   └── droidcave_payload.sh # Automated solver script
├── borderdroid/             # 8kSec Battlegrounds
│   └── README.md            # Full solution (3 exploit paths)
└── ios/                     # iOS Application Exploitation Challenges
    ├── README.md            # Index of all 11 challenges
    └── 01-...-11-*.md       # Per-challenge solution guides
```

## Companion repository

iOS methodology and full Frida script pack:
[ios-mobile-pentesting](https://github.com/MonkeyDLuffy13/ios-mobile-pentesting).
