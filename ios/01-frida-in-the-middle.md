# Challenge 01 — FridaInTheMiddle

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Frida detection evasion · Swift runtime hooking
> **Constraint:** static analysis prohibited — dynamic analysis only

## Goal

The app detects Frida at runtime (open ports, loaded dylibs, hooked
functions) and exits. Keep Frida attached **and** call
`dummyFunction(flag:)` to obtain the flag.

## Approach

1. **Launch stealthily** — attach instead of spawn where possible
   (`frida -n AppName`), or use a gadget-based setup so the detection
   routines don't see the default Frida agent.
2. **Neutralize the detection layers**:
   - **Port scan** (Frida default 27042): hook `connect()`/`getaddrinfo`
     and return failures for scanning attempts, or run the server on a
     non-default port (`frida-server -l 0.0.0.0:1337`) and connect with
     `frida -H`.
   - **Dylib enumeration**: hook `dladdr`, `_dyld_image_count`,
     `_dyld_get_image_name` and filter entries containing
     `FridaGadget`/`frida`.
   - **Hook detection**: Interceptor-on-Interceptor — restore replaced
     function prologues, or use a stealthier runtime (e.g. medusa/other
     injectors).
3. **Find the Swift function**: the class/method names may be mangled —
   list them at runtime:

```javascript
for (const { name, address } of Module.enumerateSymbols('TargetApp')) {
  if (name.includes('dummyFunction')) console.log(name, address);
}
```

4. **Hook and invoke** `dummyFunction(flag:)` — Swift functions are called
   directly (no objc_msgSend), so build the call against the resolved
   address with the right argument layout, or swizzle at the Swift/ObjC
   boundary if the class inherits NSObject.

## Result

The app stays alive with Frida attached and `dummyFunction(flag:)` returns
the flag — lab solved.

## Techniques used

Port hiding, dylib filtering, hook-detection evasion, Swift symbol
resolution, runtime invocation.
