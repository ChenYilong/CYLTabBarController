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
    }
}
rootProject.name = "CYLTabBarControllerAndroid"
include(":tabpages", ":cyltabbar", ":demokit", ":app", ":example-gif", ":example-pag", ":example-rive")
