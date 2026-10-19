# GeofenceGamble — The Ultimate Game of Speed

> **Course:** [Android Application Exploitation Challenges](https://academy.8ksec.io/course/android-application-exploitation-challenges)
> **Focus:** Location manipulation · geofence bypass · anti-cheat evasion
> Android 15 · no APK patching

## Goal

An AR-style game spawns collectible relics at real-world coordinates.
Collect the high-value relics **remotely** by defeating the location
verification — without patching the APK or tripping the anti-cheat.

## Solution

### 1 — Map the relics

Reverse the coordinate set (hardcoded/seeded relic positions — from
strings, or log the geofence registration):

```bash
adb logcat | grep -iE "geofence|relic|latitude"
```

### 2 — Simulate believable travel

The anti-cheat rejects teleports. Feed a **realistic GPX route** through
each relic:

- Mock provider app (Lock/Toolkit) with the GPX, **or**
- Frida on the location APIs with a moving coordinate feed:

```javascript
const lat0 = 52.5200, lon0 = 13.4050;   // start
const relics = [[52.5215, 13.4100], [52.5230, 13.4150], ...];
let step = 0;
setInterval(() => {
  const [la, lo] = relics[step % relics.length];
  // drive CLLocation/FusedLocation fix rewrite here
  step++;
}, 30000);   // walk-speed intervals
```

### 3 — Defeat the verification layer

| Anti-cheat check | Counter |
|---|---|
| `isFromMockProvider() == true` | hook the return to `false`, or use a root-level mock that bypasses the flag |
| Impossible speed/distance | interpolate movement (walking pace), timestamps monotonic |
| Accuracy too perfect | randomize `accuracy` 5–20 m |
| FusedLocation provenance | hook the fused provider output, not the raw one |

4. With the route running, the game registers you inside each relic's
   geofence in sequence — collect all high-value relics remotely —
   lab solved.

## Mitigation

Server-side plausibility (speed between fixes, device sensors agreeing,
attestation of location provider), and flag anomalous route shapes.
