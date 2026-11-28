// [EN] CYLBadge for Android: animated badges for any View, on top of `:cylutils`; sees no tab bar class (hosts adopt `CYLBadgeHosting`). docs/Animated-Item-Badge-CrossPlatform.md, step A3.
// [CN] Android 版 CYLBadge：任意 View 的带动画角标，位于 `:cylutils` 之上；看不到任何 TabBar 的类（宿主遵守 `CYLBadgeHosting`）。 见 docs/Animated-Item-Badge-CrossPlatform.md，步骤 A3。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
    signing
}

android {
    namespace = "com.cyl.badge"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
        consumerProguardFiles("consumer-rules.pro")
        // [EN] Badge debugging build option (docs/Badge-Debugging.md): `-PcylBadgeAnimationDisabled=true` turns badge animations off. Moved here from `:cyltabbar`.
        // [CN] 角标调试编译选项（docs/Badge-Debugging.md）：`-PcylBadgeAnimationDisabled=true` 关闭角标动画。从 `:cyltabbar` 移到这里。
        resValue("bool", "cyl_badge_animation_disabled",
            (project.findProperty("cylBadgeAnimationDisabled")?.toString() == "true").toString())
    }

    buildFeatures {
        resValues = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
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
}

dependencies {
    api(project(":cylutils"))
    implementation(libs.androidx.appcompat)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
}

tasks.withType<Test> {
    systemProperty("robolectric.dependency.repo.url", "https://maven-central.storage-download.googleapis.com/maven2")
}

val javadocJar by tasks.registering(Jar::class) {
    archiveClassifier.set("javadoc")
    from(rootProject.file("../docs")) {
        include("Animated-Item-Badge.md")
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                artifactId = "cyltabbarcontroller-badge"
                from(components["release"])
                artifact(javadocJar)
            }
        }
    }
}
