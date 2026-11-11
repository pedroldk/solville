# Keep RoomDatabase subclasses and their generated *_Impl no-arg constructors
# (instantiated via reflection by Room.getGeneratedImplementation, e.g. WorkManager's WorkDatabase_Impl).
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}

# Keep AndroidX Startup initializers instantiated via reflection.
-keep class * extends androidx.startup.Initializer {
    public <init>();
}

# Keep shared_preferences_android classes and Companion objects looked up by name via jnigen/JNI.
# Without keeping $Companion classes and Kotlin JNI helper types, R8 full mode renames
# SharedPreferencesPigeonOptions$Companion and StringListResult$Companion, breaking JNI lookups.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
-keep class kotlin.enums.EnumEntries { *; }

# Keep audioplayers_android plugin classes and enums (PlayerMode, ReleaseMode)
# resolved dynamically via enumValueOf in AudioplayersPlugin.
-keep class xyz.luan.audioplayers.** { *; }

# Keep in_app_purchase_android Pigeon codec/registrar classes and Play Billing client callbacks.
-keep class io.flutter.plugins.inapppurchase.** { *; }
-keep class com.android.billingclient.api.** { *; }

# Keep google_mobile_ads Flutter plugin classes and UMP consent wrappers.
-keep class io.flutter.plugins.googlemobileads.** { *; }
