// [EN] The Android port of Example-GIF: GIF tab icons that play once when selected, next to a GIF that loops as an image. [CN] Example-GIF 的 Android 版：选中时播放一次的 GIF Tab 图标，以及作为图片循环播放的 GIF。
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar.example.gif"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cyl.tabbar.example.gif"
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

    androidResources {
        // [EN] The iOS folders an app does not need: app icons and the bundle's translations. [CN] App 不需要的 iOS 目录：App 图标与 bundle 的翻译。
        ignoreAssetsPatterns += listOf("!<dir>AppIcon.appiconset", "!<dir>*.lproj", "!<dir>Configurations", "!Info.plist")
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    sourceSets {
        getByName("main") {
            // [EN] Example-GIF's own GIF files, not a copy. [CN] Example-GIF 自己的 GIF 文件，而不是副本。
            assets.srcDir("../../Example-GIF/GIFApp/Resources")
            // [EN] Example-GIF's image sets and colors, read by DemoAssets. [CN] Example-GIF 的图片集与颜色，由 DemoAssets 读取。
            assets.srcDir("../../Example-GIF/GIFApp/Assets.xcassets")
        }
    }
}

dependencies {
    implementation(project(":demokit"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.material)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
}
