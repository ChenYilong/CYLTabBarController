// CollectionViewClassifyMenu's Android library (com.cyl.classifymenu), fetched at the pinned commit by scripts/fetch-classifymenu.sh
// into Example-Android/cylclassifymenu (git-ignored); this file is copied there as its build file. The demo's sectioned lists use its
// tag list (docs/instructions/examples.md). Its CYLAnimatedItemView dependency is this repository's :cylanimateditem.
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.cyl.classifymenu"
    compileSdk = 35
    defaultConfig { minSdk = 23 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    api(project(":cylanimateditem"))
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.customview)
    implementation(libs.androidx.recyclerview)
}
