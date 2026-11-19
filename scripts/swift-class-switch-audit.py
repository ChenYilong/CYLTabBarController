#!/usr/bin/env python3
"""
[EN] Class switch audit (docs/Swift-Migration.md, phase 2/3): every method and property CYLTabBarController.h declares on
     CYLTabBarController (the class and its categories), and whether Swift implements it publicly. Once the header no
     longer declares the class, each must be public Swift with the Swift name apps see today, or it disappears for them.
[CN] 类迁移审计：列出 CYLTabBarController.h 中为 CYLTabBarController（类及其分类）声明的每个方法与属性，以及 Swift 是否公开实现它。
     头文件不再声明该类后，每一项都必须是公开的 Swift 成员，且 Swift 名称与 App 现在看到的一致，否则 App 将无法使用。
"""
