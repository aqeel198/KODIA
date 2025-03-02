plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.test_app"
    compileSdk = 34  // Updated compileSdk version

    defaultConfig {
        applicationId = "com.example.test_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34  // Updated targetSdk version
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            // Signing with the debug keys for now, so flutter run --release works.
            signingConfig = signingConfigs.getByName("debug")
            // Disable minification and resource shrinking to avoid R8 issues
            isMinifyEnabled = false
            isShrinkResources = false
            // If you wish to enable minification in the future, add your ProGuard rules here:
            // proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}