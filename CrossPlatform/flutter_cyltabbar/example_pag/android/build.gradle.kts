allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// [EN] The root project, the app and the flutter_cyltabbar plugin lock their dependencies (gradle.lockfile next to each
//      build file). LENIENT: a new Flutter SDK or plugin version updates the build instead of failing it; refresh with
//      `./gradlew dependencies :app:dependencies :flutter_cyltabbar:dependencies --write-locks`.
// [CN] 根工程、App 与 flutter_cyltabbar 插件锁定依赖（各构建文件旁的 gradle.lockfile）。LENIENT：Flutter SDK 或插件升级时继续构建而不是失败；
//      用 `./gradlew dependencies :app:dependencies :flutter_cyltabbar:dependencies --write-locks` 更新。
allprojects {
    if (this == rootProject || name == "app" || name == "flutter_cyltabbar") {
        dependencyLocking {
            lockAllConfigurations()
            lockMode.set(LockMode.LENIENT)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    group = "build"
    description = "Deletes the build folder of the example and its plugins."
    delete(rootProject.layout.buildDirectory)
}
