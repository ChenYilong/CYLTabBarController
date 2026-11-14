# [EN] CYLPlusButton subclasses and CYLTabBarPage classes are found by name / reflection. [CN] CYLPlusButton 子类与 CYLTabBarPage 类按名称 / 反射查找。
-keep class * extends com.cyl.tabbar.CYLPlusButton { *; }
-keep class * implements com.cyl.tabbar.pages.TabPageFactory { *; }
# [EN] The classes of the animation libraries the library calls by reflection (by name), when the app has them. [CN] 库通过反射（按名称）调用的动画库类（App 引入时）。
-keep class com.airbnb.lottie.LottieAnimationView { public *; }
-keep class com.airbnb.lottie.LottieListener { *; }
-keep class com.airbnb.lottie.LottieProperty { *; }
-keep class com.airbnb.lottie.model.KeyPath { public *; }
-keep class com.airbnb.lottie.value.LottieValueCallback { public *; }
# [EN] libpag's native code looks its Java classes up by name as well: the rule libpag documents.
# [CN] libpag 的 native 代码同样按名称查找其 Java 类：即 libpag 文档给出的规则。
-keep class org.libpag.** { *; }
-keep class androidx.exifinterface.** { *; }
-keep class app.rive.runtime.kotlin.RiveAnimationView { public *; }
-keep class app.rive.runtime.kotlin.core.Rive { public *; }
-keep enum app.rive.runtime.kotlin.core.Fit { *; }

# [EN] Theme values tell the CYLThemeItemDecoration of a RecyclerView through these methods (found by reflection).
# [CN] 主题值通过这些方法（反射查找）通知 RecyclerView 的 CYLThemeItemDecoration。
-keepclassmembers class androidx.recyclerview.widget.RecyclerView {
    public int getItemDecorationCount();
    public ** getItemDecorationAt(int);
    public void invalidateItemDecorations();
}

# [EN] cyl_setupWithViewPager2 compiles against ViewPager2; apps without it never call it.
# [CN] cyl_setupWithViewPager2 编译时依赖 ViewPager2；没有 ViewPager2 的 App 不会调用它。
-dontwarn androidx.viewpager2.**
