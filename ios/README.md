# 8kSec iOS Application Exploitation Challenges

Write-up guides for the 11 challenges of the free
[8kSec iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
course — runtime instrumentation, method swizzling, location spoofing,
deeplink abuse, and screenshot exfiltration.

> Each guide documents the challenge design, the technique, and a working
> approach. Pair them with the Frida pack in
> [ios-mobile-pentesting/scripts](https://github.com/MonkeyDLuffy13/ios-mobile-pentesting/tree/main/scripts).

| # | Challenge | Focus | Guide |
|---|-----------|-------|-------|
| 1 | FridaInTheMiddle | Frida detection evasion, Swift hooking | [01](01-frida-in-the-middle.md) |
| 2 | SwizzleMeTimbers | Objective-C method swizzling | [02](02-swizzle-me-timbers.md) |
| 3 | TraceTheMap | GPS spoofing + anti-cheat bypass | [03](03-trace-the-map.md) |
| 4 | ClearRoute | Traffic interception of an outgoing POST | [04](04-clear-route.md) |
| 5 | TrustFall | Deeplink manipulation vs domain filtering | [05](05-trust-fall.md) |
| 6 | TraceTheChat | Hooking message dispatch in an obfuscated class | [06](06-trace-the-chat.md) |
| 7 | WhereAmIReally | Geofence + authenticity validation bypass | [07](07-where-am-i-really.md) |
| 8 | BadPreference | Hidden debug mode via preference manipulation | [08](08-bad-preference.md) |
| 9 | BackSync | Remote-config abuse → sandbox file read | [09](09-back-sync.md) |
| 10 | FreeFall | Score validation bypass (runtime) | [10](10-free-fall.md) |
| 11 | SekureBrowzer | Screenshot exfiltration, non-jailbroken device | [11](11-sekure-browzer.md) |
