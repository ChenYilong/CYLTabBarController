// CYLTabBarController for Android: the iOS library's public API, in Kotlin and Java (docs/Android-API-Map.md).
// Android 版 CYLTabBarController：iOS 库的公开 API，用 Kotlin 与 Java 实现（docs/Android-API-Map.md）。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.tabbar"
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

    testOptions {
        // Robolectric runs the view tests on the JVM. Robolectric 在 JVM 上运行视图测试。
        unitTests.isIncludeAndroidResources = true
    }
}

dependencies {
    // The page registry and the configuration rules (pure Kotlin). 页面注册表与配置规则（纯 Kotlin）。
    api(project(":tabpages"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(kotlin("test"))
}

tasks.withType<Test> {
    // The shared configuration file of the iOS library, and Robolectric's Android jars from Google's Maven Central mirror.
    // iOS 库共用的配置文件；Robolectric 的 Android jar 从 Google 的 Maven Central 镜像下载。
    systemProperty("cyl.sharedConfiguration", rootProject.file("../CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations/cyl_tabbar_configuration.json").absolutePath)
    systemProperty("robolectric.dependency.repo.url", "https://maven-central.storage-download.googleapis.com/maven2")
    systemProperty("robolectric.dependency.repo.id", "central-mirror")
}
