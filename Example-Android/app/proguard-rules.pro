# Factories found by ServiceLoader (META-INF/services) are created by name: keep them and their constructor.
# ServiceLoader（META-INF/services）按类名创建工厂：保留这些类及其构造方法。
-keep class * implements com.cyl.tabbar.pages.TabPageFactory { public <init>(); }
