// The demo app: a bottom navigation bar built from the iOS library's configuration file, pages from page IDs.
// 演示 App：用 iOS 库的配置文件生成底部导航栏，页面由页面 ID 获得。
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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
    implementation(project(":tabpages"))
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.fragment:fragment-ktx:1.8.5")
    implementation("com.google.android.material:material:1.12.0")
}
