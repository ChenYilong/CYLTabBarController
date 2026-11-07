// The demo app: a CYLTabBarController built from the iOS library's configuration file, pages from page IDs.
// 演示 App：用 iOS 库的配置文件创建 CYLTabBarController，页面由页面 ID 获得。
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar.demo"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cyl.tabbar.demo"
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

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            // The same configuration files as iOS, not a copy. 与 iOS 共用同一份配置文件，而不是副本。
            assets.srcDir("../../CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations")
        }
    }
}

dependencies {
    implementation(project(":cyltabbar"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.material)
    // [EN] The Lottie scene of the gallery; the library finds Lottie by reflection. [CN] 展示页的 Lottie 场景；库通过反射找到 Lottie。
    implementation(libs.lottie)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
}
