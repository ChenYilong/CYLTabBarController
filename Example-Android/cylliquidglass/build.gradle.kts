// [EN] CYLLiquidGlass for Android: Liquid Glass as a base library, like CYLAnimatedItem: the AGSL glass the tab bar draws
//      (backdrop, effects, highlight, springs), the availability rule `CYLLiquidGlass.isActive()` and `CYLLiquidGlassView`, a
//      glass background for any view. No dependency on the tab bar (`:cyltabbar` depends on this module, not the reverse).
// [CN] Android 的 CYLLiquidGlass：作为基础库的液态玻璃，与 CYLAnimatedItem 一样：TabBar 绘制的 AGSL 玻璃（背景、效果、高光、弹簧）、
//      可用性判断 `CYLLiquidGlass.isActive()` 与 `CYLLiquidGlassView`（任意视图的玻璃背景）。不依赖 TabBar（`:cyltabbar` 依赖本模块，反之不成立）。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
    signing
}

android {
    namespace = "com.cyl.liquidglass"
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

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }
}

dependencies {
    // [EN] `androidx.annotation` (`@RequiresApi`) comes with AppCompat. [CN] `androidx.annotation`（`@RequiresApi`）随 AppCompat 提供。
    implementation(libs.androidx.appcompat)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(kotlin("test"))
}

tasks.withType<Test> {
    systemProperty("robolectric.dependency.repo.url", "https://maven-central.storage-download.googleapis.com/maven2")
    systemProperty("robolectric.dependency.repo.id", "central-mirror")
}

val javadocJar by tasks.registering(Jar::class) {
    archiveClassifier.set("javadoc")
    from(rootProject.file("../docs")) {
        include("Liquid-Glass-Component.md")
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                artifactId = "cyltabbarcontroller-liquidglass"
                from(components["release"])
                artifact(javadocJar)
            }
        }
    }
}
