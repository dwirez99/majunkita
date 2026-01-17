plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.majunkita"
    compileSdk = flutter.compileSdkVersion
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
        applicationId = "com.example.majunkita"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Biasanya di sini ada dependencies tambahan, tapi jika kosong biarkan saja.
    // Flutter otomatis memanage dependencies-nya.
}

// ==================================================================
// FIX DARI MENTOR (STRATEGI PAKSA VERSI STABIL)
// ==================================================================
// Kode ini memaksa Gradle menggunakan versi library AndroidX yang
// kompatibel dengan AGP 8.7.0 milikmu, meskipun library lain meminta yang lebih baru.
// ==================================================================
configurations.all {
    resolutionStrategy {
        eachDependency {
            // Memaksa browser kembali ke versi stabil 1.8.0
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            // Memaksa activity kembali ke versi stabil 1.9.3
            if (requested.group == "androidx.activity") {
                if (requested.name.startsWith("activity")) {
                    useVersion("1.9.3")
                }
            }
            // Memaksa core kembali ke versi stabil 1.13.1
            if (requested.group == "androidx.core") {
                if (requested.name.startsWith("core")) {
                    useVersion("1.13.1")
                }
            }
        }
    }
}
