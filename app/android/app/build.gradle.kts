plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Credentials are supplied by the local build environment, never committed.
val releaseKeyPath = System.getenv("ELEKTRALOG_KEYSTORE_PATH")
val releaseKeyAlias = System.getenv("ELEKTRALOG_KEY_ALIAS")
val releaseStorePassword = System.getenv("ELEKTRALOG_STORE_PASSWORD")
val releaseKeyPassword = System.getenv("ELEKTRALOG_KEY_PASSWORD")
val hasReleaseKey = listOf(
    releaseKeyPath, releaseKeyAlias, releaseStorePassword, releaseKeyPassword
).all { !it.isNullOrBlank() }

if (!hasReleaseKey && gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true)
    }) {
    error("Release signing requires all ELEKTRALOG_KEYSTORE_* / ELEKTRALOG_* variables")
}

android {
    namespace = "de.elektralog.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "de.elektralog.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseKeyPath!!)
                keyAlias = releaseKeyAlias!!
                storePassword = releaseStorePassword!!
                keyPassword = releaseKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
