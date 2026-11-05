plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
}

// Every dependency is locked (gradle.lockfile in each module): rebuilds resolve the same versions.
// 锁定所有依赖（每个模块的 gradle.lockfile）：每次构建解析到相同的版本。
// Update with: gradle :tabpages:dependencies :app:dependencies --write-locks
subprojects {
    dependencyLocking {
        lockAllConfigurations()
    }
}
