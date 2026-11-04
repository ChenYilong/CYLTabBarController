//
//  SwiftUITabViews.swift
//  HealthyHome (SwiftUI)
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import SwiftUI

// [EN] The SwiftUI content of each tab. The titles and icons of the tab bar items come from
//      `TabBarCommon.tabBarItemsAttributesForController()`, in the same order.
// [CN] 每个 Tab 的 SwiftUI 内容。TabBarItem 的标题和图标来自 `TabBarCommon.tabBarItemsAttributesForController()`，顺序相同。
enum SwiftUITab: CaseIterable {
    case home, healthy, friends, me

    /// [EN] The tab's identifier (`CYLTabBarItemIdentifier`, #408). [CN] Tab 的标识（`CYLTabBarItemIdentifier`，#408）。
    var identifier: String {
        switch self {
        case .home: return "home"
        case .healthy: return "healthy"
        case .friends: return "friends"
        case .me: return "me"
        }
    }

    var title: String {
        switch self {
        case .home: return CYLLocalizedString("首页")
        case .healthy: return CYLLocalizedString("健康")
        case .friends: return CYLLocalizedString("朋友圈")
        case .me: return CYLLocalizedString("我的")
        }
    }

    @ViewBuilder var content: some View {
        switch self {
        case .home: HomeTabView()
        case .healthy: PlaceholderTabView(tab: self, systemImage: "heart.text.square")
        case .friends: PlaceholderTabView(tab: self, systemImage: "person.2")
        case .me: PlaceholderTabView(tab: self, systemImage: "person.crop.circle")
        }
    }
}

// MARK: - Home

/// [EN] The home tab: drives the tab bar from SwiftUI through `TabBarBridge`.
/// [CN] 首页 Tab：通过 `TabBarBridge` 在 SwiftUI 中控制 TabBar。
struct HomeTabView: View {
    @EnvironmentObject private var bridge: TabBarBridge

    var body: some View {
        List {
            Section {
                Button("Show \"3\" on the second tab") { bridge.showBadge("3", onTab: SwiftUITab.healthy.identifier) }
                Button("Show a red dot on the third tab") { bridge.showBadge("", onTab: SwiftUITab.friends.identifier) }
                Button("Clear both badges") {
                    bridge.clearBadge(onTab: SwiftUITab.healthy.identifier)
                    bridge.clearBadge(onTab: SwiftUITab.friends.identifier)
                }
            } header: {
                Text("Badges")
            }
            Section {
                ForEach(SwiftUITab.allCases.filter { $0 != .home }, id: \.identifier) { tab in
                    Button("Select \"\(tab.identifier)\"") { bridge.select(tab.identifier) }
                }
            } header: {
                Text("Select a tab by identifier")
            }
            Section {
                Button("Push a SwiftUI page (tab bar hidden)") {
                    bridge.push(DetailView(), title: "Detail")
                }
            } header: {
                Text("Navigation")
            }
            Section {
                if bridge.plusButton != nil {
                    Toggle("Show the touchable area", isOn: $bridge.showsTouchableArea)
                    VStack(alignment: .leading) {
                        Text(String(format: "Scale: %.1fx", bridge.touchableAreaScale))
                        Slider(value: $bridge.touchableAreaScale, in: 1...3, step: 0.1)
                    }
                } else {
                    Text("This tab bar has no PlusButton")
                }
            } header: {
                Text("PlusButton touchable area (#91)")
            } footer: {
                Text("Shows the plus button's touchable area and scales it, from SwiftUI.")
            }
        }
    }
}

// MARK: - Other tabs

/// [EN] A simple SwiftUI tab. [CN] 一个简单的 SwiftUI Tab。
struct PlaceholderTabView: View {
    let tab: SwiftUITab
    let systemImage: String
    @EnvironmentObject private var bridge: TabBarBridge

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(tab.title).font(.title2)
            Button("Back to the home tab") { bridge.select(SwiftUITab.home.identifier) }
            Button("Clear this tab's badge") { bridge.clearBadge(onTab: tab.identifier) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// [EN] A page pushed from SwiftUI; the tab bar is hidden while it shows.
/// [CN] 从 SwiftUI push 的页面；显示期间 TabBar 隐藏。
struct DetailView: View {
    var body: some View {
        Text("A SwiftUI page pushed onto the tab's UINavigationController.")
            .multilineTextAlignment(.center)
            .padding()
    }
}

/// [EN] The plus button's page (`+plusChildViewController`), in SwiftUI.
/// [CN] PlusButton 对应的页面（`+plusChildViewController`），使用 SwiftUI 编写。
struct PublishView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("The plus button's child view controller is a UIHostingController.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
