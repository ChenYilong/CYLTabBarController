// [EN] CYLAnimatedItem: the animation engine (animators, registry, factory, players) and CYLAnimatedItemView, an animated
//      icon + title view to subclass. No dependency on the tab bar (`:cyltabbar` depends on this module, not the reverse).
// [CN] CYLAnimatedItem：动画引擎（animator、注册表、工厂、播放器）与 CYLAnimatedItemView（可继承的动效 icon + title 视图）。
//      不依赖 TabBar（`:cyltabbar` 依赖本模块，反之不成立）。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
    signing
}

android {
    namespace = "com.cyl.animateditem"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
        consumerProguardFiles("consumer-rules.pro")
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
    implementation(libs.androidx.appcompat)
    // [EN] The animated item posts `cyl.animation.didStart` / `didPause` / `didResume` / `didStop` through CYLDeallocBlockExecutor (docs/Lifecycle-Library.md).
    // [CN] 动效 item 通过 CYLDeallocBlockExecutor 发出 `cyl.animation.didStart` / `didPause` / `didResume` / `didStop`（docs/Lifecycle-Library.md）。
    implementation(libs.cyldeallocblockexecutor)
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
        include("Animated-Item.md")
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                artifactId = "cyltabbarcontroller-animateditem"
                from(components["release"])
                artifact(javadocJar)
            }
        }
    }
}
