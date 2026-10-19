# Challenge 07 — WhereAmIReally

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Geofencing + authenticity validation bypass

## Goal

The flag requires "verified presence" inside a geofenced area, with
authenticity checks on the location. Simulate a trusted location and defeat
the validation.

## Solution

1. Map the geofence: trigger the location updates and log coordinates to
   learn the target region.
2. Spoof with consistency (see [TraceTheMap](03-trace-the-map.md)):
   GPX/Xcode simulation or hooking `CLLocation` — move **gradually** into
   the geofence so the approach looks organic.
3. Defeat authenticity checks — apps typically validate:

| Check | Counter |
|---|---|
| `horizontalAccuracy` too perfect | spoof realistic 5–20 m values |
| Timestamps too regular | derive from real fix intervals |
| Simulator-only providers (`CLPlacemark` mismatch) | hook on-device |
| Reverse-geocode mismatch | hook `CLGeocoder` replies to match the expected region |
| Speed/distance jumps | interpolate movement across several fixes |

4. Once inside the fence with all checks green, the flag releases —
   lab solved.

## Notes

The geofence + authenticity combo is the mobile version of "location
attestation": every derived signal (speed, accuracy, timestamps, placemark)
must agree.
