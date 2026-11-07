//
//  SideMenu.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-04-20.
//

import SwiftUI

struct SideMenu: View {
    @State var isDarkMode = false
    @AppStorage("selectedMenu") var selectedMenu: SelectedMenu = .home
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person")
                    .padding(12)
                    .background(.white.opacity(0.2))
                    .mask(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meng To")
                    Text("UI Designer")
                        .font(.subheadline)
                        .opacity(0.7)
                }
                Spacer()
            }
            .padding()
            
            Text("BROWSE")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .opacity(0.7)
            
            browse
            
            Text("HISTORY")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .opacity(0.7)
            
            history
            
            Spacer()
            
            HStack(spacing: 14) {
                menuItems3[0].icon.view()
                    .frame(width: 32, height: 32)
                    .opacity(0.6)
                    .onChange(of: isDarkMode) { newValue in
                        if newValue {
                            menuItems3[0].icon.play()
                        } else {
                            menuItems3[0].icon.stop()
                        }
                    }
                Text(menuItems3[0].text)
                
                Toggle("", isOn: $isDarkMode)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(8)
        }
        .foregroundColor(.white)
        .frame(maxWidth: 288, maxHeight: .infinity)
        .background(Color(hex: "17203A"))
        .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color(hex: "17203A").opacity(0.3), radius: 40, x: 0, y: 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var browse: some View {
        menuSection(menuItems)
    }

    var history: some View {
        menuSection(menuItems2)
    }

    /// [EN] One section of the menu: a row per item; tapping a row selects it and plays its icon.
    /// [CN] 菜单的一个分区：每项一行；点击一行即选中该项并播放其图标。
    private func menuSection(_ items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                Rectangle()
                    .frame(height: 1)
                    .opacity(0.1)
                    .padding(.horizontal, 16)

                HStack(spacing: 14) {
                    item.icon.view()
                        .frame(width: 32, height: 32)
                        .opacity(0.6)
                    Text(item.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.blue)
                        .frame(maxWidth: selectedMenu == item.menu ? .infinity : 0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
                .background(Color("Background 2"))
                .onTapGesture {
                    withAnimation(.timingCurve(0.2, 0.8, 0.2, 1)) {
                        selectedMenu = item.menu
                    }
                    // [EN] "active" is YES for 2 seconds (the icon's "duration" option). [CN] "active" 为 YES 两秒（图标的 "duration" 选项）。
                    item.icon.play()
                }
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        SideMenu()
    }
}

struct MenuItem: Identifiable {
    var id = UUID()
    var text: String
    var icon: RiveAnimation
    var menu: SelectedMenu
}

/// [EN] An icon of the course's icons.riv, played through CYLTabBarController's Rive support (state machine input "active").
/// [CN] 课程 icons.riv 中的图标，通过 CYLTabBarController 的 Rive 支持播放（状态机输入 "active"）。
private func menuIcon(_ artboard: String, _ stateMachine: String, duration: String = "2") -> RiveAnimation {
    RiveAnimation("icons", [.riveArtboard: artboard, .riveStateMachine: stateMachine, .riveInput: "active", .riveActiveDuration: duration])
}

var menuItems = [
    MenuItem(text: "Home", icon: menuIcon("HOME", "HOME_interactivity"), menu: .home),
    MenuItem(text: "Search", icon: menuIcon("SEARCH", "SEARCH_Interactivity"), menu: .search),
    MenuItem(text: "Favorites", icon: menuIcon("LIKE/STAR", "STAR_Interactivity"), menu: .favorites),
    MenuItem(text: "Help", icon: menuIcon("CHAT", "CHAT_Interactivity"), menu: .help)
]

var menuItems2 = [
    MenuItem(text: "History", icon: menuIcon("TIMER", "TIMER_Interactivity"), menu: .history),
    MenuItem(text: "Notifications", icon: menuIcon("BELL", "BELL_Interactivity"), menu: .notifications)
]

var menuItems3 = [
    MenuItem(text: "Dark Mode", icon: menuIcon("SETTINGS", "SETTINGS_Interactivity", duration: "0"), menu: .darkmode)
]

enum SelectedMenu: String {
    case home
    case search
    case favorites
    case help
    case history
    case notifications
    case darkmode
}
