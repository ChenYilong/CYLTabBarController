plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
}

// Every dependency is locked (gradle.lockfile in each module): rebuilds resolve the same versions.
// 锁定所有依赖（每个模块的 gradle.lockfile）：每次构建解析到相同的版本。
// Update with: gradle dependencies :tabpages:dependencies :app:dependencies --write-locks
allprojects {
    dependencyLocking {
        lockAllConfigurations()
    }
}

// MARK: - Publishing (scripts/publish-android.sh) 发布
// [EN] The two library modules are published with the same group and version: `tabpages` (pure Kotlin) and `cyltabbar`
//      (the Android library, which depends on it). The version follows the iOS pod (CYLTabBarController.podspec) unless
//      -PcylVersion is given; the group is -PcylGroup or io.github.chenyilong. Signing uses SIGNING_KEY / SIGNING_PASSWORD
//      (an ASCII-armored key) or gpg (-Psigning.gnupg.keyName), and is skipped without a key (local builds).
// [CN] 两个库模块以相同的 group 与版本发布：`tabpages`（纯 Kotlin）与依赖它的 `cyltabbar`（Android 库）。版本默认与 iOS pod
//      （CYLTabBarController.podspec）一致，可用 -PcylVersion 指定；group 为 -PcylGroup 或 io.github.chenyilong。签名使用 SIGNING_KEY /
//      SIGNING_PASSWORD（ASCII 格式的私钥）或 gpg（-Psigning.gnupg.keyName），没有私钥时跳过（本地构建）。
val podspecVersion: String = Regex("""s\.version\s*=\s*["']([^"']+)["']""")
    .find(rootProject.file("../CYLTabBarController.podspec").readText())?.groupValues?.get(1) ?: "0.0.0-SNAPSHOT"
val cylVersion: String = providers.gradleProperty("cylVersion").orNull ?: podspecVersion
val cylGroup: String = providers.gradleProperty("cylGroup").orNull ?: "io.github.chenyilong"

subprojects {
    if (name != "tabpages" && name != "cyltabbar") return@subprojects
    group = cylGroup
    version = cylVersion
    plugins.withId("maven-publish") {
        configure<PublishingExtension> {
            publications.withType<MavenPublication>().configureEach {
                pom {
                    name.set(if (project.name == "tabpages") "CYLTabBarController pages" else "CYLTabBarController")
                    description.set(if (project.name == "tabpages")
                        "The page registry and configuration rules of CYLTabBarController for Android (pure Kotlin)."
                        else "CYLTabBarController for Android: the iOS library's tab bar controller, plus button, badges, themes, animated tab icons and configuration files.")
                    url.set("https://github.com/ChenYilong/CYLTabBarController")
                    licenses {
                        license {
                            name.set("MIT License")
                            url.set("https://github.com/ChenYilong/CYLTabBarController/blob/master/LICENSE")
                        }
                    }
                    developers {
                        developer {
                            id.set("ChenYilong")
                            name.set("ChenYilong")
                            url.set("https://github.com/ChenYilong")
                        }
                    }
                    scm {
                        url.set("https://github.com/ChenYilong/CYLTabBarController")
                        connection.set("scm:git:https://github.com/ChenYilong/CYLTabBarController.git")
                        developerConnection.set("scm:git:ssh://git@github.com/ChenYilong/CYLTabBarController.git")
                    }
                }
            }
            repositories {
                // [EN] The Maven Central bundle is built from this folder. [CN] Maven Central 的上传包由此目录生成。
                maven {
                    name = "staging"
                    url = uri(rootProject.layout.buildDirectory.dir("staging-deploy"))
                }
                maven {
                    name = "GitHubPackages"
                    url = uri("https://maven.pkg.github.com/" + (System.getenv("GITHUB_REPOSITORY") ?: "ChenYilong/CYLTabBarController"))
                    credentials {
                        username = System.getenv("GITHUB_ACTOR")
                        password = System.getenv("GITHUB_TOKEN")
                    }
                }
            }
        }
        plugins.withId("signing") {
            configure<SigningExtension> {
                val key = System.getenv("SIGNING_KEY")
                when {
                    !key.isNullOrBlank() -> useInMemoryPgpKeys(key, System.getenv("SIGNING_PASSWORD") ?: "")
                    providers.gradleProperty("signing.gnupg.keyName").isPresent -> useGpgCmd()
                    else -> return@configure
                }
                sign(the<PublishingExtension>().publications)
            }
        }
    }
}
