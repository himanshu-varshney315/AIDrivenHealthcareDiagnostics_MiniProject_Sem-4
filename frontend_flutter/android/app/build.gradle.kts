import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val localProperties = Properties().apply {
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { load(it) }
        }
    }
    val keystoreProperties = Properties().apply {
        val keystorePropertiesFile = rootProject.file("key.properties")
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use { load(it) }
        }
    }
    val isReleaseBuild = gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true)
    }
    val hasReleaseSigning = listOf(
        "storeFile",
        "storePassword",
        "keyAlias",
        "keyPassword",
    ).all { !keystoreProperties.getProperty(it).isNullOrBlank() }

    if (isReleaseBuild && !hasReleaseSigning) {
        throw GradleException(
            "Missing Android release signing config. Copy android/key.properties.example " +
                "to android/key.properties, generate ayuva-release-key.jks, and fill all values."
        )
    }

    namespace = "com.ayuva.health"
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
        applicationId = "com.ayuva.health"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_RUNTIME_KEY"] =
            localProperties.getProperty("MAPS_RUNTIME_KEY", "")
        manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "false"
    }

    signingConfigs {
        create("release") {
            val releaseStoreFile = keystoreProperties.getProperty("storeFile")
            if (!releaseStoreFile.isNullOrBlank()) {
                storeFile = rootProject.file(releaseStoreFile)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "true"
        }

        release {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["USES_CLEARTEXT_TRAFFIC"] = "false"
        }
    }
}

flutter {
    source = "../.."
}
