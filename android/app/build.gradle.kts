import java.io.StringReader
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    val raw = keystorePropertiesFile.readText(Charsets.UTF_8).trimStart('\uFEFF')
    keystoreProperties.load(StringReader(raw))
}

android {
    namespace = "pt.solal.solville"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "pt.solal.solville"
        // google_mobile_ads requires minSdk >= 23.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Solville AdMob App ID (overrideable via ADMOB_APP_ID env var).
        manifestPlaceholders["admobAppId"] =
            System.getenv("ADMOB_APP_ID")?.takeIf { it.isNotBlank() }
                ?: "ca-app-pub-3113832650326844~3293995632"
    }

    signingConfigs {
        create("release") {
            val envPath = System.getenv("ANDROID_KEYSTORE_PATH")
            val propPath = keystoreProperties.getProperty("storeFile")
            val resolvedPath = envPath?.takeIf { it.isNotBlank() } ?: propPath
            val resolvedAlias =
                System.getenv("ANDROID_KEY_ALIAS")?.takeIf { it.isNotBlank() }
                    ?: keystoreProperties.getProperty("keyAlias")
            val resolvedKeyPassword =
                System.getenv("ANDROID_KEY_PASSWORD")?.takeIf { it.isNotBlank() }
                    ?: keystoreProperties.getProperty("keyPassword")
            val resolvedStorePassword =
                System.getenv("ANDROID_KEYSTORE_PASSWORD")?.takeIf { it.isNotBlank() }
                    ?: keystoreProperties.getProperty("storePassword")

            if (!resolvedPath.isNullOrBlank() &&
                !resolvedAlias.isNullOrBlank() &&
                !resolvedKeyPassword.isNullOrBlank() &&
                !resolvedStorePassword.isNullOrBlank()
            ) {
                val candidateFile = file(resolvedPath)
                if (candidateFile.isFile) {
                    storeFile = candidateFile
                    keyAlias = resolvedAlias
                    keyPassword = resolvedKeyPassword
                    storePassword = resolvedStorePassword
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = if (releaseSigning?.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
