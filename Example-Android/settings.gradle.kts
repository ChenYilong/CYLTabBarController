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
// [EN] CollectionViewClassifyMenu's tag list (the demo's sectioned lists, docs/instructions/examples.md) is fetched at the commit pinned in
//      CrossPlatform/harmonyos-cyltabbar/classifymenu.pin into the git-ignored cylclassifymenu/ (scripts/fetch-classifymenu.sh android).
// [CN] CollectionViewClassifyMenu 的 TagList（演示中带分组的列表，docs/instructions/examples.md）按 classifymenu.pin 固定的提交拉取到不入库的
//      cylclassifymenu/（scripts/fetch-classifymenu.sh android）。
// [EN] `standalone`: this build is the root (the demo). Included in another build (CollectionViewClassifyMenu includes this folder from a sparse checkout
//      of Example-Android, Example-Shared and docs), only the three library modules it substitutes are included, and nothing outside this folder
//      is read or run (the pin file and the fetch script are not in a sparse checkout, and the fetch would be circular).
// [CN] `standalone`：本构建是根构建（演示）。被其他构建包含时（CollectionViewClassifyMenu 以 Example-Android、Example-Shared 与 docs 的稀疏检出包含本目录），
//      只包含它替换的三个库模块，并且不读取、不运行本目录之外的任何内容（稀疏检出中没有固定提交文件与拉取脚本，拉取也会循环依赖）。
val standalone = gradle.parent == null

if (standalone) {
    val classifyMenuPin = file("../CrossPlatform/harmonyos-cyltabbar/classifymenu.pin").readText().trim()
    val classifyMenuFetched = file("cylclassifymenu/.pinned-sha")
    if (!classifyMenuFetched.exists() || classifyMenuFetched.readText().trim() != classifyMenuPin) {
        val fetch = ProcessBuilder(listOf("C:/Program Files/Git/bin/bash.exe", "/usr/bin/bash").firstOrNull { file(it).exists() } ?: "bash", file("../scripts/fetch-classifymenu.sh").absolutePath, "android").inheritIO().start().waitFor()
        check(fetch == 0) { "scripts/fetch-classifymenu.sh android failed (needs bash, git and tar)" }
    }
}
if (standalone) {
    include(":tabpages", ":cylutils", ":cylbadge", ":cylanimateditem", ":classifymenu", ":cyltabbar", ":demokit", ":app", ":example-gif", ":example-pag", ":example-rive")
    project(":classifymenu").projectDir = file("cylclassifymenu")
} else {
    include(":tabpages", ":cylutils", ":cylbadge", ":cylanimateditem", ":cyltabbar")
}
