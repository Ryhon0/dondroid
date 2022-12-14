#!/bin/sh
set -e

# ----- Config -----

# Name of the Android package
# Requires AndroidManifest.xml to be edited manually
PKGNAME="org.dlang.dondroid"

# Name of the library the native activity should load
# Requires AndroidManifest.xml to be edited manually
OUTLIBNAME="libnative-activity"

# Path to the library outputed by dub
LIBNAME="libdondroid"

# Path to the output .apk
APKFILE="debug.apk"

# Path to the Android SDK root
# Should contain the following directories: platform-tools, platforms 
SDK="/opt/android-sdk"
KS="debug.ks"
KSPASS="${KSPASS:-android}"

# ------------------
APKFILE=$(realpath $APKFILE)
KS=$(realpath $KS)


# ----- Building -----
rm -rf android/lib
# --- ARM64
dub build --compiler=ldc2 -c=android --arch=aarch64--linux-android
# dub has no output path option :(
# https://github.com/dlang/dub/issues/902
# https://forum.dlang.org/post/jamzphyzbhmtrbezbdbk@forum.dlang.org
mkdir -p android/lib/arm64-v8a
mv $LIBNAME.so android/lib/arm64-v8a/$OUTLIBNAME.so

# --- ARMv7
# dub build --compiler=ldc2 -c=android --arch=armv7a--linux-androideabi
# Same as above
# mkdir -p android/lib/armeabi-v7a
# mv $LIBNAME.so android/lib/armeabi-v7a/$OUTLIBNAME.so


# ----- Packaging -----
cd android
rm -f $APKFILE

# --- Creating the APK
aapt package -f -F $APKFILE -I $SDK/platforms/android-21/android.jar -M AndroidManifest.xml -S res -v --target-sdk-version 21
aapt add $APKFILE lib/arm64-v8a/$OUTLIBNAME.so
# aapt add $APKFILE lib/armeabi-v7a/$OUTLIBNAME.so

# --- Signing
# Create key with keytool, eg.
# keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.ks -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
apksigner sign --ks $KS --ks-pass=pass:$KSPASS $APKFILE

# ----- Installing -----
# adb install $APKFILE
# --- Launch the app
# adb shell monkey -p $PKGNAME 1