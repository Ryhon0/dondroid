# D on Droid
Android native activity written in D, using zero Java.  

Tested using:
* LDC v1.30
* Android NDK r21 (>=r22 uses a different linker and does not work with this project)
* Android SDK 21
* AAPT(1) v0.2
* apksigner v0.9

## Building
* Download the Android SDK 21 and NDK r21  
* Install `aapt` (version 1, not 2) and `apksigner` and Java `keytool`
* Generate a signing key with `keytool`  
* [Set up LDC for Android cross-compiling](https://wiki.dlang.org/Build_D_for_Android#Cross-compilation_setup)  
* Modify [apk.sh](/apk.sh) and [android/AndroidManifest.xml](android/AndroidManifest.xml) to your liking.  
* Run `./apk.sh`  

## How does it work?
LDC cross-compiles the app for Android using the clang compiler from the NDK.  
`aapt` is used to create the `.apk` file and signed using `apksigner`.  
The main activity is a `NativeActivity`, it loads the native library and calls C functions, which are handled by [android-native-glue](libs/android-native-glue/source/android_native_app_glue.d) and call `android_main` defined in the app code, this function contains the main loop


## References
https://wiki.dlang.org/Build_D_for_Android  
https://wiki.dlang.org/Cross-compiling_with_LDC  
https://github.com/Diewi/android  
https://github.com/cnlohr/rawdrawandroid