import com.android.build.api.dsl.ApplicationExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Runs the Django backend inside the app process.
    id("com.chaquo.python")
}

// ── TripGo in-app backend ────────────────────────────────────────────────
// The Django project lives in backend/ and is the single source of truth for both
// the desktop server and the APK. It is synced into the build directory and handed
// to Chaquopy as an extra Python source root, so nothing has to be duplicated.
val backendDir: Directory = rootProject.layout.projectDirectory.dir("../../backend")
val syncedPythonDir: Provider<Directory> = layout.buildDirectory.dir("tripgo-python")

// Chaquopy's Python 3.13 runtime is 64-bit only. Flutter widens ndk.abiFilters to
// android-arm, android-arm64 and android-x64, so the list is re-asserted once the
// Android DSL is finalised - otherwise the build fails on the unsupported 32-bit ABI
// and the APK carries two ABIs nobody can use.
val tripgoAbis = listOf("arm64-v8a", "x86_64")

val syncTripgoBackend = tasks.register<Sync>("syncTripgoBackend") {
    group = "tripgo"
    description = "Copies the Django backend into the Chaquopy source set."
    from(backendDir) {
        include("manage.py")
        include("config/**")
        include("apps/**")
        exclude("**/__pycache__/**", "**/*.pyc", "**/*.pyo")
    }
    into(syncedPythonDir)
}

// Chaquopy registers its pip/extraction tasks lazily, so make sure they - and the
// asset merge that reads the Python source root - always see a fresh copy.
tasks.configureEach {
    if (name != "syncTripgoBackend") {
        dependsOn(syncTripgoBackend)
    }
}

android {
    namespace = "com.example.tripgo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.tripgo"
        // Chaquopy requires API 24 or newer.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.clear()
            abiFilters += tripgoAbis
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

androidComponents {
    // Runs after every plugin (including the Flutter one) has finished widening the
    // ABI list, but before Chaquopy validates the variants.
    finalizeDsl { extension: ApplicationExtension ->
        extension.defaultConfig.ndk.abiFilters.apply {
            clear()
            addAll(tripgoAbis)
        }
    }
}

chaquopy {
    defaultConfig {
        // Must match the major.minor of the Python used on the build machine.
        version = "3.13"

        pip {
            install("-r", "requirements-android.txt")
        }
    }

    sourceSets {
        getByName("main") {
            srcDir(syncedPythonDir)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
