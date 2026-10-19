# Challenge 10 — FreeFall

> **Course:** [iOS Application Exploitation Challenges](https://academy.8ksec.io/course/ios-application-exploitation-challenges)
> **Focus:** Runtime score-validation bypass

## Goal

A ball game runs 60-second rounds with cheat-proof scoring. Manipulate the
runtime to bypass score validation and submit an impossible leaderboard
score.

## Solution

1. Play one round normally; capture the score submission (proxy or Frida
   log) — note the score field and any signature.
2. Hook the in-game score state at runtime:

```javascript
// find the score-holding class via UI inspection
ObjC.choose(ObjC.classes.UIViewController, {
  onMatch(inst) {
    try {
      inst.$ivars.forEach(iv => {
        const v = inst.$ivars[iv];
        if (typeof v === 'number' && v > 0) console.log(iv, '=', v);
      });
    } catch (e) {}
  },
  onComplete() {}
});
```

3. Identify the ivar/property holding the score (play twice, diff values),
   then set it to an impossible value right before submission.
4. If the score is signed/validated client-side, hook the validation
   method (`validateScore:`, `isHighScore`) to return the crafted value.
5. The leaderboard accepts the impossible score — lab solved.

## Notes

"Anti-cheat" that lives only in the client is decoration: the game state
runs in your process, and your process is yours.
