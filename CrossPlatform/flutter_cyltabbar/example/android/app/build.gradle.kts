plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// [EN] The Lottie tab icons of the Objective-C example (Example/Classes/Other/LottieResources), read as assets.
// [CN] Objective-C 示例的 Lottie Tab 图标（Example/Classes/Other/LottieResources），作为 assets 读取。
val cylRepository = file("$projectDir/../../../../..")

android {
    namespace = "com.cyl.tabbar.flutter_cyltabbar_example"
    sourceSets {
        getByName("main") {
            assets.srcDir("$cylRepository/Example/Classes/Other/LottieResources")
        }
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cyl.tabbar.flutter_cyltabbar_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // [EN] R8 shrinks and obfuscates the release build (Flutter adds its rules and this folder's proguard-rules.pro).
            // [CN] R8 压缩并混淆 release 包（Flutter 会加入自己的规则与本目录的 proguard-rules.pro）。
            isMinifyEnabled = true
            isShrinkResources = true
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

dependencies {
    // [EN] The Lottie tab icons (the library plays them when lottie-android is present). [CN] Lottie Tab 图标（引入 lottie-android 时库会播放）。
    implementation(libs.lottie)
}
