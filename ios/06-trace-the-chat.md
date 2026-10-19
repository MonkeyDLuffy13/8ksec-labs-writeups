# Challenge 06 — TraceTheChat

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Runtime message-dispatch hooking in an obfuscated class

## Goal

A messaging app hides its logic in an **obfuscated class**. Hook message
dispatch at runtime to read message contents and the recipient live —
static extraction is prohibited.

## Solution

1. Find the chat view controller at runtime (UI is live even when names are
   obfuscated):

```javascript
ObjC.choose(ObjC.classes.UIViewController, {
  onMatch: function (instance) {
    console.log(instance.$className);
  },
  onComplete() {}
});
```

2. Hook message dispatch — two reliable layers:

```javascript
// (a) every ObjC message to the obfuscated class
ObjC.classes.ObfuscatedClassName.$ownMethods.forEach(m => {
  try { traceObjCMethod('ObfuscatedClassName', m); } catch (e) {}
});

// (b) the low-level dispatch itself, filtered by selector name
Interceptor.attach(ObjC.classes.NSString['- stringByAppendingString'].implementation, {...});
```

Practical approach: hook `objc_msgSend` broadly for a few seconds while the
app renders a message, dump every selector + first argument, and identify
the message-delivery selector from the logged contents.

3. Read the live traffic: the recipient + message body pass through the
   identified method — log `args` on every send while chatting.

4. Extract the target message/recipient as required by the challenge —
   lab solved.

## Notes

Since static extraction is prohibited, everything happens at runtime:
class enumeration → selector tracing → argument dumping.
