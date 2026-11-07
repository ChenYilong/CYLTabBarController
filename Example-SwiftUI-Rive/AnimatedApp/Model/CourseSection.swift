//
//  CourseSection.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-04-14.
//

import SwiftUI

struct CourseSection: Identifiable {
    var id = UUID()
    var title: String
    var caption: String
    var color: Color
    var image: Image
}

var courseSections = [
    CourseSection(title: "State Machine", caption: "Watch video - 15 mins", color: Color(hex: "9CC5FF"), image: Image("Topic 2")),
    CourseSection(title: "Animated Menu", caption: "Watch video - 10 mins", color: Color(hex: "6E6AE8"), image: Image("Topic 1")),
    CourseSection(title: "Tab Bar", caption: "Watch video - 8 mins", color: Color(hex: "005FE7"), image: Image("Topic 2")),
    CourseSection(title: "Button", caption: "Watch video - 9 mins", color: Color(hex: "BBA6FF"), image: Image("Topic 1"))
]
