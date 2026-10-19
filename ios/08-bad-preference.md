# Challenge 08 — BadPreference

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Hidden debug mode via preference manipulation

## Goal

A debug mode is buried in the app's preferences — not exposed in the UI and
not visible in static strings. Enable it by manipulating internal settings
or runtime state.

## Solution

1. Dump all preferences of the running app:

```javascript
const defaults = ObjC.classes.NSUserDefaults.standardUserDefaults();
const dict = defaults.dictionaryRepresentation();
const keys = dict.allKeys();
for (let i = 0; i < keys.count(); i++) {
  const k = keys.objectAtIndex_(i);
  console.log(k, '=', dict.objectForKey_(k));
}
```

2. On-device (jailbroken):

```bash
plutil -p /var/mobile/Library/Preferences/<bundle-id>.plist
```

3. Look for suspicious keys: `debug`, `internal`, `admin`, `feature_flag`,
   `beta`, `hidden`, booleans defaulting to false/0.
4. Flip the candidate key at runtime:

```javascript
ObjC.classes.NSUserDefaults.standardUserDefaults()
  .setBool_forKey_(true, 'debug_mode_enabled');
```

or on device:

```bash
plutil -replace debug_mode_enabled -bool true <plist>
killall -9 TargetApp     # relaunch to re-read
```

5. The debug UI/menu unlocks — retrieve the flag — lab solved.

## Notes

Enumerate — don't guess: the key name comes from the runtime dump, not
from guessing strings statically (static strings are deliberately absent).
