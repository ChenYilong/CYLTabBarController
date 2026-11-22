// CYLTabBarController for Android: the iOS library's public API, in Kotlin and Java (docs/Android-API-Map.md).
// Android 版 CYLTabBarController：iOS 库的公开 API，用 Kotlin 与 Java 实现（docs/Android-API-Map.md）。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
    signing
}

android {
    namespace = "com.cyl.tabbar"
    compileSdk = 35

    defaultConfig {
        minSdk = 23
        consumerProguardFiles("consumer-rules.pro")
        // [EN] Badge debugging build option (docs/Badge-Debugging.md): `-PcylBadgeAnimationDisabled=true` turns badge animations off.
        // [CN] 角标调试编译选项（docs/Badge-Debugging.md）：`-PcylBadgeAnimationDisabled=true` 关闭角标动画。
        buildConfigField("boolean", "CYL_BADGE_ANIMATION_DISABLED",
            (project.findProperty("cylBadgeAnimationDisabled")?.toString() == "true").toString())
    }

    buildFeatures {
        buildConfig = true
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
        // Robolectric runs the view tests on the JVM. Robolectric 在 JVM 上运行视图测试。
        unitTests.isIncludeAndroidResources = true
    }
}

dependencies {
    // The page registry and the configuration rules (pure Kotlin). 页面注册表与配置规则（纯 Kotlin）。
    api(project(":tabpages"))
    api(project(":cylanimateditem"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.fragment.ktx)
    // [EN] The callback registry of the layout block, the same logic as iOS (CYLDeallocBlockExecutor), from JitPack, pinned to a commit.
    //      TODO: replace the commit pin with a release once the library is published to Maven Central. This core is published as
    //      io.github.chenyilong:cyltabbarcontroller, and its POM must not reference an unpublished artifact: the next Android release
    //      waits for that (it needs the owner's OK).
    // [CN] 布局 block 的回调注册表，与 iOS 逻辑相同（CYLDeallocBlockExecutor），来自 JitPack，固定到某次提交。
    //      TODO：库发布到 Maven Central 后，把提交固定改为正式版本。本核心发布为 io.github.chenyilong:cyltabbarcontroller，其 POM 不能引用
    //      尚未发布的构件：下一次 Android 发布要等它（需要所有者同意）。
    implementation(libs.cyldeallocblockexecutor)
    // [EN] Only for `cyl_setupWithViewPager2`: an app that uses it adds ViewPager2 itself. [CN] 仅用于 `cyl_setupWithViewPager2`：使用它的 App 自行添加 ViewPager2。
    compileOnly(libs.androidx.viewpager2)
    testImplementation(libs.androidx.viewpager2)
    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    // [EN] Only to test the Lottie animator found by reflection; apps add Lottie themselves. [CN] 仅用于测试通过反射找到的 Lottie animator；App 自行添加 Lottie。
    testImplementation(libs.lottie)
    // [EN] Only to test the system tab bar height read from Material themes. [CN] 仅用于测试从 Material 主题读取的系统 TabBar 高度。
    testImplementation(libs.material)
    testImplementation(libs.androidx.test.core)
    testImplementation(kotlin("test"))
}

tasks.withType<Test> {
    // The shared configuration file of the iOS library, and Robolectric's Android jars from Google's Maven Central mirror.
    // iOS 库共用的配置文件；Robolectric 的 Android jar 从 Google 的 Maven Central 镜像下载。
    systemProperty("cyl.sharedConfiguration", rootProject.file("../Example-Shared/Configurations/cyl_tabbar_configuration.json").absolutePath)
    systemProperty("robolectric.dependency.repo.url", "https://maven-central.storage-download.googleapis.com/maven2")
    systemProperty("robolectric.dependency.repo.id", "central-mirror")
}

// [EN] Published as io.github.chenyilong:cyltabbarcontroller (scripts/publish-android.sh). Maven Central needs a javadoc jar:
//      the Kotlin API is documented in docs/, so the jar carries those documents.
// [CN] 发布为 io.github.chenyilong:cyltabbarcontroller（scripts/publish-android.sh）。Maven Central 需要 javadoc jar：Kotlin API
//      的文档在 docs/ 中，因此该 jar 包含这些文档。
val javadocJar by tasks.registering(Jar::class) {
    archiveClassifier.set("javadoc")
    from(rootProject.file("../docs")) {
        include("Android-Library.md", "Android-API-Map.md", "Configuration-File.md")
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                artifactId = "cyltabbarcontroller"
                from(components["release"])
                artifact(javadocJar)
            }
        }
    }
}
