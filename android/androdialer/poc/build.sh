#!/usr/bin/env bash
set -euo pipefail

# عدّل هذا المسار إن لزم، أو صدّر ANDROID_HOME قبل التشغيل
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -n1)"
PLATFORM_JAR="$(ls -d "$SDK"/platforms/android-* | sort -V | tail -n1)/android.jar"

echo "[*] build-tools : $BT"
echo "[*] platform    : $PLATFORM_JAR"

rm -rf build
mkdir -p build

echo "[*] 1/5 تجميع الموارد"
"$BT/aapt2" compile --dir res -o build/res.zip
"$BT/aapt2" link -I "$PLATFORM_JAR" --manifest AndroidManifest.xml \
    --java build/gen -o build/base.apk build/res.zip

echo "[*] 2/5 تجميع الجافا"
javac -source 8 -target 8 -nowarn -classpath "$PLATFORM_JAR" -d build/classes \
    build/gen/com/poc/androdialer/R.java \
    src/com/poc/androdialer/MainActivity.java

echo "[*] 3/5 توليد classes.dex"
"$BT/d8" --lib "$PLATFORM_JAR" --release \
    --output build build/classes/com/poc/androdialer/*.class

echo "[*] 4/5 حزم الـ APK"
(cd build && zip -qj base.apk classes.dex)

echo "[*] 5/5 المحاذاة والتوقيع"
"$BT/zipalign" -f 4 build/base.apk build/aligned.apk

if [ ! -f debug.keystore ]; then
    keytool -genkeypair -keystore debug.keystore -alias androiddebugkey \
        -storepass android -keypass android -keyalg RSA -keysize 2048 \
        -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
fi
"$BT/apksigner" sign --ks debug.keystore --ks-pass pass:android \
    --key-pass pass:android --out AndroDialerPoC.apk build/aligned.apk

echo "[✓] جاهز: AndroDialerPoC.apk"
echo "    adb install -r AndroDialerPoC.apk"
