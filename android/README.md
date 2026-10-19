# 8kSec Android Application Exploitation Challenges

Write-up solutions for the 10 Android labs of the free
[8kSec Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
course — exposed components, IPC abuse, WebView exploitation, dynamic code
loading, location spoofing, and browser-based attacks on Android 14–15.

| # | Lab | Level | Focus | Solution |
|---|-----|-------|-------|----------|
| 1 | FactsDroid: Your Universal Knowledgebase | APPRENTICE | MITM response tampering (Flutter, TLS + root-check bypass) | [01](factsdroid/README.md) |
| 2 | AndroPseudoProtect: Ultimate Device Security | APPRENTICE | Exported receiver/service + token reuse (IPC abuse) | [02](andropseudoprotect/README.md) |
| 3 | AndroDialer: The Ultimate Phone Experience | APPRENTICE | Confused deputy via exported activity + hardcoded token | [03](androdialer/README.md) |
| 4 | DroidCave: Secure Password Management | APPRENTICE | Exposed ContentProvider: SQLi + IPC-toggleable encryption | [04](droidcave/README.md) |
| 5 | BorderDroid: International Border Protection | — | Kiosk bypass: volume-key backdoor + HTTP unlock + PIN brute force | [05](borderdroid/README.md) |
| 6 | DroidPass: Ultimate Password Vault | — | Flutter static analysis: AES key from Dart AOT → DB decryption | [06](droidpass/README.md) |
| 7 | DroidView: Ultimate Private Browsing | — | Exported Tor controller + WebView redirect exfiltration | [07](droidview/README.md) |
| 8 | DroidWars: The Plugins Race | — | Malicious DexClassLoader plugin inheriting host permissions | [08](droidwars/README.md) |
| 9 | GeofenceGamble: The Ultimate Game of Speed | — | Location spoofing with realistic GPS traces + anti-cheat evasion | [09](geofencegamble/README.md) |
| 10 | ReconDroid: The Application Intelligence Provider | — | intent:// URL → exported export-component abuse | [10](reconduroid/README.md) |

All solutions are solvable with free tooling: JADX, apktool, adb, Frida,
Objection — no Burp Pro required.

Companion iOS cheatsheets & scripts:
[ios-mobile-pentesting](https://github.com/MonkeyDLuffy13/ios-mobile-pentesting).
