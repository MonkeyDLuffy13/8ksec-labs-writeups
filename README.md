# 8kSec Labs — Write-ups & Solutions

Personal write-up repository for challenges from
[8kSec Academy](https://academy.8ksec.io/) and
[8kSec Battlegrounds](https://battlegrounds.8ksec.io/), focused on Android
application exploitation: exposed components, IPC abuse, confused-deputy
attacks, Flutter/TLS bypasses, and runtime instrumentation with Frida.

## Solved Labs

| Lab | Category | Vulnerability Class | Key Tools | Write-up |
|-----|----------|--------------------|-----------|----------|
| **FactsDroid** | Flutter app exploitation | Missing TLS validation → MITM response tampering (root check + Flutter TLS bypass) | jadx, apktool, blutter, Frida, mitmproxy | [factsdroid/](factsdroid/) |
| **AndroDialer** | Android component abuse | Confused deputy via exported activity + hardcoded auth token | jadx, adb, deep links | [androdialer/](androdialer/) |
| **AndroPseudoProtect** | Android IPC abuse | Exported receiver/service authenticated by an observable runtime secret | JADX, Frida, ADB | [andropseudoprotect/](andropseudoprotect/) |
| **DroidCave** | Android IPC abuse | Exposed ContentProvider: arbitrary SQL injection + IPC-toggleable encryption | adb, JADX | [droidcave/](droidcave/) |

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
│   └── payloads.md          # Quick-reference payload list
├── droidcave/               # 8kSec — Secure Password Management
│   ├── README.md            # Solution write-up
│   └── droidcave_payload.sh # Automated solver script
└── _TEMPLATE.md             # Template for new write-ups
```

## Adding a New Write-up

1. Copy `_TEMPLATE.md` into a new folder named after the lab (lowercase,
   hyphenated), e.g. `androcalendar/README.md`.
2. Fill in every section — recon notes matter as much as the final exploit.
3. Add a row to the **Solved Labs** table above.

## Disclaimer

- These write-ups are published **for educational purposes only**, documenting
  techniques learned while solving intentionally vulnerable lab applications.
- All targets are lab environments owned by 8kSec. Do not apply any technique
  described here to systems you do not have explicit permission to test.
- Application binaries (APKs) are **not** redistributed in this repository —
  they must be obtained through an enrollment with 8kSec. Please respect
  8kSec's course/lab terms when sharing or referencing this material.

## License

Code samples and PoCs are released under the [MIT License](LICENSE).
Write-up text: all rights reserved by the author.
