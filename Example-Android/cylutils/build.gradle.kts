// [EN] CYLUtils for Android: the bottom module (geometry types, `CYLFont`, `CYLEnums`, `CYLLocalization`) and the only one that depends on the lifecycle library (D8). See docs/Animated-Item-Badge-CrossPlatform.md, step A3.
// [CN] Android 版 CYLUtils：最底层模块（几何类型、`CYLFont`、`CYLEnums`、`CYLLocalization`），也是唯一依赖生命周期库的模块（D8）。见 docs/Animated-Item-Badge-CrossPlatform.md，步骤 A3。
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    `maven-publish`
    signing
}

android {
    namespace = "com.cyl.utils"
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
}

dependencies {
    // [EN] D8: the only module that declares the lifecycle library (CYLDeallocBlockExecutor); every module above gets it through `api`.
    // [CN] D8：唯一声明生命周期库（CYLDeallocBlockExecutor）的模块；上面的所有模块经由 `api` 得到它。
    // [EN] TODO: replace the commit pin (JitPack) with a release once the library is published to Maven Central. The published POM must not reference an
    //      unpublished artifact: the next Android release waits for that (it needs the owner's OK). It moved here from `:cyltabbar` and `:cylanimateditem`.
    // [CN] TODO：库发布到 Maven Central 后，把提交固定（JitPack）改为正式版本。发布的 POM 不能引用尚未发布的构件：下一次 Android 发布要等它
    //      （需要所有者同意）。它从 `:cyltabbar` 与 `:cylanimateditem` 移到这里。
    api(libs.cyldeallocblockexecutor)
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
                artifactId = "cyltabbarcontroller-utils"
                from(components["release"])
                artifact(javadocJar)
            }
        }
    }
}
