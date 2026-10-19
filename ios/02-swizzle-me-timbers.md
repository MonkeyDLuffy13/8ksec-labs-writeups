# Challenge 02 — SwizzleMeTimbers

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Objective-C runtime method swizzling

## Goal

A flag-gating method always returns `false`. Swizzle it at runtime so it
returns `true` and unlocks the flag.

## Approach

### 1 — Find the class & method

```bash
# static (allowed here):
class-dump Payload/App.app/App | grep -i flag
```

or at runtime:

```javascript
if (ObjC.available) {
  ObjC.enumerateLoadedClassesSync().forEach(([framework, classes]) => {
    classes.forEach(c => {
      if (c.toLowerCase().includes('flag') || c.toLowerCase().includes('pirate'))
        console.log(framework, c);
    });
  });
}
```

### 2 — Swizzle with Frida

```javascript
ObjC.classes.ClassWithFlagGate['- isFlagUnlocked'].implementation =
  function () {
    return true;   // the gate now always opens
  };
```

(The method name in the dump is the source of truth — match the exact
selector.)

### 3 — Trigger the UI path

Interact with the app (press the pirate button / navigate) so the swizzled
method runs — the flag unlocks — lab solved.

## Mitigation

Runtime swizzling defeats naive boolean gates; validate sensitive state
server-side and harden with selectors integrity checks
(though determined attackers will hook above any client-side control).
