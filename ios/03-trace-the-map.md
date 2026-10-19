# Challenge 03 — TraceTheMap

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** GPS spoofing · anti-cheat bypass

## Goal

Collect 5 map markers (each within 50 m, 500 points total) while the app
runs spoof-detection countermeasures.

## Approach

### 1 — Simulate movement (no jailbreak needed)

Xcode → *Features → Location → Custom…* — feed a GPX file that walks the
route through all 5 marker coordinates (markers unlock sequentially by
proximity).

```xml
<gpx>
  <wpt lat="37.334600" lon="-122.009000"><time>2026-01-01T00:00:00Z</time></wpt>
  <wpt lat="37.335100" lon="-122.008800"><time>2026-01-01T00:00:20Z</time></wpt>
  ...
</gpx>
```

### 2 — Defeat the spoof checks

The app counters naive teleporting. Typical checks + answers:

| Check | Bypass |
|---|---|
| Instant jumps between fixes | GPX with realistic speed/timestamps |
| `CLLocationManager` mocked (simulator flag) | hook `CLLocation` init and override coordinates on a **real** device |
| Horizontal accuracy = 0 / -1 | spoof `horizontalAccuracy` to a plausible value (5–20 m) |
| Course/speed consistency | derive speed from the GPX deltas |

Frida example (device):

```javascript
const CLLocation = ObjC.classes.CLLocation;
Interceptor.attach(CLLocation['- coordinate'].implementation, {
  onLeave(retval) {
    const coord = this.self.coordinate();
    // rewrite to the marker's lat/lon
  }
});
```

### 3 — Collect all 5 markers → flag — lab solved.

## Notes

Consistency beats force: the anti-cheat compares *physics*, so feed it
physically plausible movement.
