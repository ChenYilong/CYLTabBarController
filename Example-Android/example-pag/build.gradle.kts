// [EN] The Android port of Example-PAG: PAG tab icons (libpag), a plus button with a background image and a title. [CN] Example-PAG 的 Android 版：PAG Tab 图标（libpag）、带背景图与标题的 PlusButton。
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar.example.pag"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cyl.tabbar.example.pag"
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
            // [EN] The PAG files of Example-PAG, downloaded by scripts/fetch-animation-resources.py (see Example-Shared/PAGResources). [CN] Example-PAG 的 PAG 文件，由 scripts/fetch-animation-resources.py 下载（见 Example-Shared/PAGResources）。
            assets.srcDir("../../Example-Shared/PAGResources/tab-icons")
        }
    }
}

dependencies {
    implementation(project(":demokit"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.material)
    // [EN] The library plays PAG through libpag, found by reflection. [CN] 库通过反射找到 libpag 播放 PAG。
    implementation(libs.libpag)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
}

// [EN] The PAG files are not in the repository (see Example-Shared/PAGResources): they are downloaded before the first build,
//      as `pod install` does for Example-PAG. Without python3 or the network the build goes on and the tabs show their images.
// [CN] PAG 文件不在仓库中（见 Example-Shared/PAGResources）：首次构建前下载，与 Example-PAG 的 `pod install` 相同。没有 python3 或网络时构建继续，
//      Tab 显示其图片。
val fetchPAGResources by tasks.registering(Exec::class) {
    val tabIcons = rootProject.file("../Example-Shared/PAGResources/tab-icons/tab_home.pag")
    onlyIf { !tabIcons.exists() }
    workingDir = rootProject.file("..")
    commandLine("python3", "scripts/fetch-animation-resources.py", "PAGResources")
    isIgnoreExitValue = true
}
tasks.named("preBuild") { dependsOn(fetchPAGResources) }
