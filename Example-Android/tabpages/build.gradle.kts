// Pure Kotlin (no Android): the page registry and the configuration rules, tested on the JVM.
// 纯 Kotlin（不依赖 Android）：页面注册表与配置规则，在 JVM 上测试。
plugins {
    alias(libs.plugins.kotlin.jvm)
    `maven-publish`
    signing
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    withSourcesJar()
    withJavadocJar()
}

// [EN] Published as io.github.chenyilong:cyltabbarcontroller-pages (scripts/publish-android.sh). [CN] 发布为 io.github.chenyilong:cyltabbarcontroller-pages。
publishing {
    publications {
        create<MavenPublication>("release") {
            artifactId = "cyltabbarcontroller-pages"
            from(components["java"])
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    // Android ships org.json; the JVM tests need it. Android 自带 org.json；JVM 测试需要引入。
    compileOnly(libs.json)
    testImplementation(libs.json)
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
    // The shared configuration file of the iOS library. iOS 库共用的配置文件。
    systemProperty("cyl.sharedConfiguration", rootProject.file("../CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations/cyl_tabbar_configuration.json").absolutePath)
}
