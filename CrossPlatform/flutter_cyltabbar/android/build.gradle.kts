group = "com.cyl.tabbar.flutter_cyltabbar"
version = "0.1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // [EN] CYLDeallocBlockExecutor (com.github.ChenYilong) is only on JitPack, a dependency of the cyltabbar sources below. [CN] CYLDeallocBlockExecutor（com.github.ChenYilong）只在 JitPack 上，是下面 cyltabbar 源码的依赖。
        maven("https://jitpack.io") { content { includeGroup("com.github.ChenYilong") } }
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
// [EN] An app whose build already has the :cylanimateditem module (e.g. through another library built on it, such as
//      CollectionViewClassifyMenu) uses that module instead of compiling its sources here: compiling them as well put
//      the component in the app twice ("2 files found with path 'META-INF/cylanimateditem/LICENSE'", then duplicate
//      classes), bug B9 in docs/Animated-Item.md.
// [CN] 构建中已有 :cylanimateditem 模块的 App（例如通过基于它的其他库，如 CollectionViewClassifyMenu）使用该模块，而不在这里编译其源码：
//      两者都有会让组件在 App 中出现两份（"2 files found with path 'META-INF/cylanimateditem/LICENSE'"，然后是重复的类），见 docs/Animated-Item.md 问题 B9。
val cylAnimatedItemModule = rootProject.findProject(":cylanimateditem")
// [EN] Or an included build that has it (its dependency substitution maps the published coordinate to that project).
// [CN] 或者包含它的 included build（其依赖替换会把发布坐标映射到该项目）。
// [EN] Found by its folder at the included build's root or by its settings file declaring ":cylanimateditem" (a
//      projectDir mapped elsewhere); or the app says so: `cylAnimatedItemProvided=true` in gradle.properties.
// [CN] 通过 included build 根目录下的文件夹，或其 settings 文件声明 ":cylanimateditem"（projectDir 指向别处）判断；或由 App 指定：
//      gradle.properties 中的 `cylAnimatedItemProvided=true`。
val cylAnimatedItemIncluded = findProperty("cylAnimatedItemProvided")?.toString() == "true" || gradle.includedBuilds.any { build ->
    File(build.projectDir, "cylanimateditem").isDirectory ||
        listOf("settings.gradle.kts", "settings.gradle").any { name -> File(build.projectDir, name).let { it.isFile && it.readText().contains(":cylanimateditem") } }
}
val cylCompilesAnimatedItem = cylUseLocalSources && cylAnimatedItemModule == null && !cylAnimatedItemIncluded

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
                    // [EN] cyltabbar depends on CYLAnimatedItem (the animated icon + title component and the animation
                    //      engine, no animation library). [CN] cyltabbar 依赖 CYLAnimatedItem（动效 icon + title 组件与动画引擎，不含动画库）。
                    "$cylAndroidRoot/tabpages/src/main/kotlin",
                )
                res.srcDirs("$cylAndroidRoot/cyltabbar/src/main/res")
                resources.srcDirs("$cylAndroidRoot/cyltabbar/src/main/resources")
                if (cylCompilesAnimatedItem) {
                    java.srcDirs("$cylAndroidRoot/cylanimateditem/src/main/java", "$cylAndroidRoot/cylanimateditem/src/main/kotlin")
                    res.srcDirs("$cylAndroidRoot/cylanimateditem/src/main/res")
                    resources.srcDirs("$cylAndroidRoot/cylanimateditem/src/main/resources")
                }
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
        if (cylCompilesAnimatedItem) consumerProguardFiles("$cylAndroidRoot/cylanimateditem/consumer-rules.pro")
        // [EN] The library's CYLBadge reads BuildConfig.CYL_BADGE_ANIMATION_DISABLED, the badge debugging build option
        //      (docs/Badge-Debugging.md): `-PcylBadgeAnimationDisabled=true` turns badge animations off.
        // [CN] 库的 CYLBadge 读取角标调试编译选项 BuildConfig.CYL_BADGE_ANIMATION_DISABLED（docs/Badge-Debugging.md）。
        if (cylUseLocalSources) buildConfigField("boolean", "CYL_BADGE_ANIMATION_DISABLED",
            (project.findProperty("cylBadgeAnimationDisabled")?.toString() == "true").toString())
    }

    buildFeatures {
        buildConfig = cylUseLocalSources
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
        // As in cyltabbar: CYLViewPager2Binding compiles against ViewPager2, which an app adds when it uses it.
        compileOnly("androidx.viewpager2:viewpager2:1.0.0")
        // [EN] As in cyltabbar (the layout block's callback registry), pinned to the same commit. TODO: replace the pin with a release once the library is on Maven Central.
        // [CN] 与 cyltabbar 相同（布局 block 的回调注册表），固定到同一提交。TODO：库发布到 Maven Central 后改为正式版本。
        implementation("com.github.ChenYilong.CYLDeallocBlockExecutor:cyl-dealloc-block-executor-core:9e141eafbff18a3644c7ea202bc4379c48dee499")
        if (cylAnimatedItemModule != null) implementation(cylAnimatedItemModule)
        else if (cylAnimatedItemIncluded) implementation("io.github.chenyilong:cyltabbarcontroller-animateditem:$cylAndroidVersion")
    } else {
        implementation("io.github.chenyilong:cyltabbarcontroller:$cylAndroidVersion")
    }
}
