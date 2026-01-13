# Flutter-specific ProGuard rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# BLE (flutter_blue_plus) related
-keep class com.boskokg.flutter_blue_plus.** { *; }
-keep class android.bluetooth.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# HTTP related
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# WebSocket
-keep class io.netty.** { *; }
-dontwarn io.netty.**

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Package info
-keep class io.flutter.plugins.packageinfo.** { *; }

# WiFi IoT
-keep class com.alternadom.wifiiot.** { *; }

# Network info
-keep class dev.fluttercommunity.plus.network_info.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Font Awesome
-keep class com.joanzapata.iconify.** { *; }

# General Android keeps
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
