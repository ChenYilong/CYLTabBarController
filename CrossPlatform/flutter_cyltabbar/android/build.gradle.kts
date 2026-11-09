group = "com.cyl.tabbar.flutter_cyltabbar"
version = "0.1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

// [EN] Inside the CYLTabBarController repository, compile the local Android library sources (Example-Android/cyltabbar and
//      tabpages), so a change there shows up in the Flutter example without publishing. Elsewhere (from pub.dev), use the
//      published library io.github.chenyilong:cyltabbarcontroller.
// [CN] 在 CYLTabBarController 仓库内，直接编译本地 Android 库源码（Example-Android/cyltabbar 与 tabpages），改动无需发布即可在
//      Flutter 示例中生效。在其他地方（从 pub.dev 安装）使用已发布的 io.github.chenyilong:cyltabbarcontroller。
val cylAndroidRoot = file(findProperty("cylAndroidRoot") ?: "$projectDir/../../../Example-Android")
val cylUseLocalSources = File(cylAndroidRoot, "cyltabbar/src/main/kotlin").exists()
val cylAndroidVersion = findProperty("cylAndroidVersion") ?: "1.100.0"

android {
    // [EN] The library sources use com.cyl.tabbar.R. [CN] 库源码使用 com.cyl.tabbar.R。
    namespace = if (cylUseLocalSources) "com.cyl.tabbar" else "com.cyl.tabbar.flutter_cyltabbar"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
            if (cylUseLocalSources) {
                java.srcDirs(
                    "$cylAndroidRoot/cyltabbar/src/main/java",
                    "$cylAndroidRoot/cyltabbar/src/main/kotlin",
                    "$cylAndroidRoot/tabpages/src/main/kotlin",
                )
                res.srcDirs("$cylAndroidRoot/cyltabbar/src/main/res")
            }
        }
    }

    defaultConfig {
        minSdk = 24
        // [EN] The library's sources are compiled here, not its module: its R8 rules (classes found by reflection, such as
        //      libpag's PAGView) must come along, or a minified release build removes them and the tabs show their images.
        // [CN] 这里编译的是库的源码而不是它的模块：必须一并带上库的 R8 规则（反射查找的类，如 libpag 的 PAGView），否则开启混淆的发布版会删除它们，
        //      Tab 只显示图片。
        if (cylUseLocalSources) consumerProguardFiles("$cylAndroidRoot/cyltabbar/consumer-rules.pro")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    if (cylUseLocalSources) {
        implementation("androidx.appcompat:appcompat:1.7.0")
        implementation("androidx.fragment:fragment-ktx:1.8.5")
    } else {
        implementation("io.github.chenyilong:cyltabbarcontroller:$cylAndroidVersion")
    }
}
