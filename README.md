# 8kSec Labs — Write-ups & Solutions

Personal write-up repository for challenges from
[8kSec Academy](https://academy.8ksec.io/) and
[8kSec Battlegrounds](https://battlegrounds.8ksec.io/), covering **Android**
and **iOS** application exploitation: exposed components, IPC abuse,
confused-deputy attacks, Flutter/TLS bypasses, runtime instrumentation with
Frida, method swizzling, GPS spoofing, and deeplink abuse.

## Android — Solved Labs (all 10 course labs)

Full index: [android/README.md](android/README.md)

| Lab | Category | Vulnerability Class | Key Tools | Write-up |
|-----|----------|--------------------|-----------|----------|
| **FactsDroid** | Flutter app exploitation | Missing TLS validation → MITM response tampering (root check + Flutter TLS bypass) | jadx, apktool, blutter, Frida, mitmproxy | [factsdroid/](android/factsdroid/) |
| **AndroDialer** | Android component abuse | Confused deputy via exported activity + hardcoded auth token | jadx, adb, deep links | [androdialer/](android/androdialer/) |
| **AndroPseudoProtect** | Android IPC abuse | Exported receiver/service authenticated by an observable runtime secret | JADX, Frida, ADB | [andropseudoprotect/](android/andropseudoprotect/) |
| **DroidCave** | Android IPC abuse | Exposed ContentProvider: arbitrary SQL injection + IPC-toggleable encryption | adb, JADX | [droidcave/](android/droidcave/) |
| **DroidPass** | Flutter static analysis | Hardcoded AES base key in Dart AOT snapshot → database decryption | strings, Ghidra, Python | [droidpass/](android/droidpass/) |
| **DroidView** | WebView + IPC abuse | Exported Tor controller + WebView redirect → real-IP and inventory exfiltration | JADX, adb, intent URLs | [droidview/](android/droidview/) |
| **DroidWars** | Dynamic code loading | Malicious DexClassLoader plugin inheriting host permissions | JADX, d8, Python server | [droidwars/](android/droidwars/) |
| **GeofenceGamble** | Location spoofing | Geofence + anti-cheat evasion with realistic GPS traces | mock provider, Frida | [geofencegamble/](android/geofencegamble/) |
| **ReconDroid** | Browser-based attack | intent:// URL from web page → exported export-component abuse | Chrome intents, JADX | [reconduroid/](android/reconduroid/) |
| **BorderDroid** | Kiosk / device-policy abuse | Hidden volume-key backdoor + unauthenticated HTTP unlock + PIN brute force | adb, curl, arp-scan | [borderdroid/](android/borderdroid/) |

## iOS — Application Exploitation Challenges

Write-up guides for the 11 challenges of the free
[iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
course — see [ios/](ios/) for the full index.

## Repository Structure

```
.
├── android/                 # Android Application Exploitation Challenges
│   ├── README.md            # Index of all 10 Android labs
│   ├── factsdroid/          # Full walkthrough + screenshots + artifacts
│   ├── androdialer/         # Solution + PoC exploit app source
│   ├── andropseudoprotect/  # Solution + quick-reference payloads
│   ├── droidcave/           # Solution + automated solver script
│   ├── borderdroid/         # Full solution (3 exploit paths)
│   ├── droidpass/           # Flutter static-analysis solution
│   ├── droidview/           # WebView/IPC exfiltration solution
│   ├── droidwars/           # Malicious plugin solution
│   ├── geofencegamble/      # Location-spoofing solution
│   └── reconduroid/         # Browser-based intent solution
└── ios/                     # iOS Application Exploitation Challenges
    ├── README.md            # Index of all 11 challenges
    └── 01-...-11-*.md       # Per-challenge solution guides
```

## Companion repository

iOS methodology and full Frida script pack:
[ios-mobile-pentesting](https://github.com/MonkeyDLuffy13/ios-mobile-pentesting).
