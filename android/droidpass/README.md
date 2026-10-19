# DroidPass — Ultimate Password Vault

> **Course:** [Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
> **Focus:** Static analysis only — **no hooking, no dynamic analysis, no
> secret-extraction tools** — manual APK parsing required.

## Goal

The vault claims tamper detection and layered security. Statically reverse
the APK to extract the **base encryption key** of the database and read the
stored passwords.

## Solution

### 1 — Identify the framework

```bash
apktool d DroidPass.apk -o droidpass/
unzip -o DroidPass.apk -d raw/
ls raw/lib/arm64-v8a/
# libapp.so + libflutter.so  →  Flutter app (Dart AOT)
```

Flutter means the logic lives in `libapp.so` (Dart AOT snapshot) — no smali
to read; work with the binary directly.

### 2 — Hunt the key in the Dart snapshot

Dart AOT keeps string literals in cleartext inside `libapp.so`:

```bash
strings -a raw/lib/arm64-v8a/libapp.so | grep -iE "key|encrypt|database|pass|sqlcipher|aes" | sort -u
```

The database is SQLCipher/encrypted SQLite — look for a printable 16/32-byte
string sitting near `database`, `cipher`, or `primaryKey` markers. Verify by
decrypting the pulled database:

```bash
adb pull /data/data/<bundle>/databases/app.db   # or via backup on non-root
python3 - <<'EOF'
from Crypto.Cipher import AES
key = b'YOUR-32-BYTE-KEY'          # the candidate from strings
data = open('app.db','rb').read()
open('app_decrypted.db','wb').write(AES.new(key, AES.MODE_CBC, data[:16]).decrypt(data[16:16+(len(data)//16)*16]))
EOF
file app_decrypted.db               # → SQLite 3.x = key confirmed
```

3. Open the decrypted DB, extract the administrator's password, log in —
   lab solved.

## Notes

- "Tamper detection" (checksum checks) does not protect the key that ships
  inside the binary — static strings are readable by definition.
- If the key isn't printable, look for a key-derivation call pattern around
  the DB-open sequence in Ghidra (Dart `Ffi` → native `sqlite3_key`).
