# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin / OkHttp
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# AndroidX Security, Crypto & SharedPreferences (used for auth token persistence)
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**
-keep class androidx.preference.** { *; }
-dontwarn androidx.preference.**

# Google Play Core (fix missing classes error)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**