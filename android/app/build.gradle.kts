import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { fis ->
        keystoreProperties.load(fis)
    }
}

// Resolve keystore file path from key.properties, trying both module and root project directories
val storeFilePathProp = (keystoreProperties["storeFile"] as String?)
val resolvedStoreFile = storeFilePathProp?.let { path ->
    val appRelative = file(path)
    val rootRelative = rootProject.file(path)
    when {
        appRelative.exists() -> appRelative
        rootRelative.exists() -> rootRelative
        // Sometimes the keystore is kept at android/ while path is relative to app/
        file("../$path").exists() -> file("../$path")
        else -> null
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists() && resolvedStoreFile != null

android {
    namespace = "com.example.agrifinity"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    // Override to satisfy plugin requirements
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.agrifinity"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only configure if key.properties exists and the keystore file can be resolved
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = resolvedStoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use debug signing if no keystore is provided; otherwise use the release keystore
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
