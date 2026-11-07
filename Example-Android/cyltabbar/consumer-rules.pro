# [EN] CYLPlusButton subclasses and CYLTabBarPage classes are found by name / reflection. [CN] CYLPlusButton 子类与 CYLTabBarPage 类按名称 / 反射查找。
-keep class * extends com.cyl.tabbar.CYLPlusButton { *; }
-keep class * implements com.cyl.tabbar.pages.TabPageFactory { *; }
# [EN] The classes of the animation libraries the library calls by reflection (by name), when the app has them. [CN] 库通过反射（按名称）调用的动画库类（App 引入时）。
-keep class com.airbnb.lottie.LottieAnimationView { public *; }
-keep class com.airbnb.lottie.LottieListener { *; }
-keep class com.airbnb.lottie.LottieProperty { *; }
-keep class com.airbnb.lottie.model.KeyPath { public *; }
-keep class com.airbnb.lottie.value.LottieValueCallback { public *; }
-keep class org.libpag.PAGView { public *; }
-keep class app.rive.runtime.kotlin.RiveAnimationView { public *; }
