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
        // [EN] Google's mirror of Maven Central first: Maven Central answers HTTP 429 (Too Many Requests) to CI runners that fetch the
        //      large Robolectric runtime jars (`nativeruntime-dist-compat`), which fails the Android job. The mirror serves the same
        //      artifacts; Maven Central stays as the second repository.
        // [CN] 先用 Google 的 Maven Central 镜像：CI 下载体积较大的 Robolectric 运行时 jar（`nativeruntime-dist-compat`）时，Maven Central
        //      会返回 HTTP 429（请求过多），导致 Android 任务失败。镜像提供相同的构件；Maven Central 作为第二个仓库保留。
        maven("https://maven-central.storage-download.googleapis.com/maven2")
        mavenCentral()
        // [EN] SVGAPlayer-Android (com.github.yyued) is only on JitPack, for example-rive; so is CYLDeallocBlockExecutor (com.github.ChenYilong), a dependency of cyltabbar. [CN] SVGAPlayer-Android 只在 JitPack 上，供 example-rive 使用；CYLDeallocBlockExecutor（com.github.ChenYilong）也在 JitPack 上，是 cyltabbar 的依赖。
        maven("https://jitpack.io") { content { includeGroup("com.github.yyued"); includeGroup("com.github.ChenYilong"); includeGroup("com.github.ChenYilong.CYLDeallocBlockExecutor") } }
    }
}
rootProject.name = "CYLTabBarControllerAndroid"
include(":tabpages", ":cylanimateditem", ":cylliquidglass", ":cyltabbar", ":demokit", ":app", ":example-gif", ":example-pag", ":example-rive")
