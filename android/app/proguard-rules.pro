# ============================================================
# Reglas ProGuard/R8 para Dulce Moment
# Necesarias para que el APK release funcione con Supabase
# ============================================================

# ---------- Supabase / Ktor / OkHttp ----------
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn io.ktor.**
-dontwarn okhttp3.**
-dontwarn okio.**

# ---------- Kotlin Serialization ----------
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.example.dulce_moment.**$$serializer { *; }
-keepclassmembers class com.example.dulce_moment.** {
    *** Companion;
}
-keepclasseswithmembers class com.example.dulce_moment.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ---------- Kotlin coroutines ----------
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ---------- Kotlin reflection (Ktor la usa internamente) ----------
-keep class kotlin.reflect.** { *; }
-dontwarn kotlin.reflect.**

# ---------- Conscrypt / TLS (SSL en Android) ----------
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# ---------- Flutter ----------
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ---------- General ----------
-keepattributes Signature
-keepattributes Exceptions
-keepattributes EnclosingMethod
