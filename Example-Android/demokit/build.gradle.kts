// [EN] The demo code shared by the Android demo apps (app, example-pag, example-gif, example-rive): the demo lists ported
//      from the iOS Example, the settings rows (iOS `CYLSettingsDemoTableViewController`), the gallery, the plus button badge.
// [CN] Android 演示 App（app、example-pag、example-gif、example-rive）共用的演示代码：移植自 iOS Example 的演示列表、设置行
//      （iOS `CYLSettingsDemoTableViewController`）、展示页、PlusButton 角标。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar.demokit"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
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
            // [EN] The same configuration files as iOS, not a copy. [CN] 与 iOS 共用同一份配置文件，而不是副本。
            assets.srcDir("../../Example-Shared/Configurations")
            // [EN] The library's iOS resource bundle (the holiday skin icons, the sample GIF), read by `DemoAssets`; the apps
            //      leave out its .lproj folders (`ignoreAssetsPatterns`).
            // [CN] 库的 iOS 资源 bundle（节日皮肤图标、示例 GIF），由 `DemoAssets` 读取；App 排除其中的 .lproj 目录（`ignoreAssetsPatterns`）。
            assets.srcDir("../../CYLTabBarController/Resources/CYLTabBarController.bundle")
        }
    }
}

dependencies {
    api(project(":cyltabbar"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.material)
}
