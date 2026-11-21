# [EN] The animation engine calls the animation libraries by reflection (by name) when the app has them. [CN] 动画引擎在 App 引入动画库时通过反射（按名称）调用它们。
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

# [EN] SVGAPlayer-Android, also called by reflection (CYLSVGATabBarItemAnimator). [CN] SVGAPlayer-Android，同样通过反射调用（CYLSVGATabBarItemAnimator）。
-keep class com.opensource.svgaplayer.** { public *; }
