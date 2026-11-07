// [EN] The Android port of Example-Rive: Rive tab icons (rive-android) from the course's icons.riv, a Start plus button, a Rive view outside the tab bar. [CN] Example-Rive 的 Android 版：来自课程 icons.riv 的 Rive Tab 图标（rive-android）、Start PlusButton、TabBar 之外的 Rive 视图。
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar.example.rive"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cyl.tabbar.example.rive"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // R8 shrinks and obfuscates the release build. R8 压缩并混淆 release 包。
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    sourceSets {
        getByName("main") {
            // [EN] The .riv files of Example-Rive / Example-SwiftUI-Rive, not a copy. [CN] Example-Rive / Example-SwiftUI-Rive 的 .riv 文件，而不是副本。
            assets.srcDir("../../Example-SwiftUI-Rive/AnimatedApp/RiveAssets")
        }
    }
}

dependencies {
    implementation(project(":demokit"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.material)
    // [EN] The library plays Rive through rive-android, found by reflection. [CN] 库通过反射找到 rive-android 播放 Rive。
    implementation(libs.rive)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
}
