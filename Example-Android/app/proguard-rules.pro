# Factories found by ServiceLoader (META-INF/services) are created by name: keep them and their constructor.
# ServiceLoader（META-INF/services）按类名创建工厂：保留这些类及其构造方法。
-keep class * implements com.cyl.tabbar.pages.TabPageFactory { public <init>(); }
# [EN] okio (from Lottie) references optional javax.annotation classes, as its own R8 rules note. [CN] okio（来自 Lottie）引用可选的 javax.annotation 类，与其自身 R8 规则的说明一致。
-dontwarn javax.annotation.**
