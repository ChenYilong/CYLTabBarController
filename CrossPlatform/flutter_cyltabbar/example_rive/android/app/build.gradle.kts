plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// [EN] The demo takes its images and animation files from the iOS example itself, as Example-Android does: this
//      repository's folders become assets, and demokit's DemoAssets (copied below) reads an asset catalog by image name.
// [CN] Demo 直接从 iOS 示例获取图片与动画文件，与 Example-Android 相同：本仓库的目录作为 assets，demokit 的 DemoAssets（在下面复制）按图片名读取资源目录。
val cylRepository = file("$projectDir/../../../../..")
val cylDemoAssetsDir = file("${layout.buildDirectory.get().asFile}/generated/cyl-demokit")
val copyCYLDemoAssets by tasks.registering(Copy::class) {
    from("$cylRepository/Example-Android/demokit/src/main/kotlin/com/cyl/tabbar/demo") { include("DemoAssets.kt") }
    into("$cylDemoAssetsDir/com/cyl/tabbar/demo")
}
tasks.named("preBuild") { dependsOn(copyCYLDemoAssets) }

android {
    namespace = "com.cyl.tabbar.flutter_cyltabbar_example_rive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cyl.tabbar.flutter_cyltabbar_example_rive"
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

    sourceSets {
        getByName("main") {
            assets.srcDir("$cylRepository/Example-SwiftUI-Rive/AnimatedApp/RiveAssets")
            assets.srcDir("$cylRepository/Example-SwiftUI-Rive/AnimatedApp/Assets.xcassets")
            // [EN] Issue #415: the SVGA tab icons of Example-SwiftUI-Rive (not a copy) and this demo's SVGA configuration file
            //      (assets/svga/cyl_tabbar_configuration_svga.json, route "bundle:svga?name=cyl_tabbar_configuration_svga").
            // [CN] Issue #415：Example-SwiftUI-Rive 的 SVGA Tab 图标（不是副本）与本 Demo 的 SVGA 配置文件。
            assets.srcDir("$cylRepository/Example-SwiftUI-Rive/AnimatedApp/SVGAAssets")
            assets.srcDir("../../configurations")
            java.srcDir(cylDemoAssetsDir)
        }
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
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
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
    // [EN] The library plays the animation files through this library, found by reflection. [CN] 库通过反射找到该库播放动画文件。
    implementation(libs.rive.android)
    // [EN] Issue #415: SVGA through SVGAPlayer-Android (JitPack), found by reflection. [CN] Issue #415：通过反射找到 SVGAPlayer-Android（JitPack）播放 SVGA。
    implementation(libs.svgaplayer)
}
