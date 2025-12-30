plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.bolaji.gasdetector"  // ✅ Must match google-services.json
    compileSdk = 36  // ✅ Updated to 36
    
    ndkVersion = "27.0.12077973"  // ✅ Updated NDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true  // ✅ Enable desugaring
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.bolaji.gasdetector"  // ✅ Must match google-services.json
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // ✅ Updated to 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // ✅ Add desugaring
}
