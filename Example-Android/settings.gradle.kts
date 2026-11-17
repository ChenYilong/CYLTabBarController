// Android demo of CYLTabBarController's page registry: the same configuration file as iOS, the same page IDs.
// CYLTabBarController 页面注册表的 Android 演示：与 iOS 使用同一份配置文件、同样的页面 ID。
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // [EN] SVGAPlayer-Android (com.github.yyued) is only on JitPack, for example-rive. [CN] SVGAPlayer-Android 只在 JitPack 上，供 example-rive 使用。
        maven("https://jitpack.io") { content { includeGroup("com.github.yyued") } }
    }
}
rootProject.name = "CYLTabBarControllerAndroid"
include(":tabpages", ":cylanimateditem", ":cyltabbar", ":demokit", ":app", ":example-gif", ":example-pag", ":example-rive")
