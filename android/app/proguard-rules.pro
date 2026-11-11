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
