plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rishabh.upi_expense_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rishabh.upi_expense_tracker"
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

dependencies {
    testImplementation("junit:junit:4.13.2")

    // Pinned to the exact version already resolved transitively via
    // google_sign_in_android (verified against the real dependency tree and
    // the real decompiled API surface before writing any code against it —
    // AuthorizationClient/AuthorizationRequest/PICKER_OAUTH_TRIGGER all
    // exist in this version). Declared explicitly so the Drive/Sheets
    // authorization code below compiles against a version we've actually
    // inspected, not whatever the transitive graph happens to resolve to.
    implementation("com.google.android.gms:play-services-auth:21.5.1")
}

flutter {
    source = "../.."
}
