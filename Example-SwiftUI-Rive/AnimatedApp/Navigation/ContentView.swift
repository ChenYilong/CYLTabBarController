//
//  ContentView.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-03-29.
//

import SwiftUI

struct ContentView: View {
    @State var show = false
    @State var isOpen = false
    // [EN] The state machine input "isOpen" stays as set ("duration" 0) until it is set back.
    // [CN] 状态机输入 "isOpen" 保持设置的值（"duration" 为 0），直到再次设置。
    let button = RiveAnimation("menu_button", [.riveStateMachine: "State Machine", .riveInput: "isOpen", .riveActiveDuration: "0"])
    
    var body: some View {
        ZStack {
            Color(hex: "17203A").ignoresSafeArea()
            
            SideMenu()
                .padding(.top, 50)
                .opacity(isOpen ? 1 : 0)
                .offset(x: isOpen ? 0 : -300)
                .rotation3DEffect(.degrees(isOpen ? 0 : 30), axis: (x: 0, y: 1, z: 0))
                .ignoresSafeArea(.all, edges: .top)
            
            // [EN] The home screen and its tab bar: a CYLTabBarController with the course's Rive icons (TabBar.swift).
            // [CN] 首页及其 TabBar：使用课程 Rive 图标的 CYLTabBarController（TabBar.swift）。
            TabBar()
                .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .rotation3DEffect(.degrees(isOpen ? 30 : 0), axis: (x: 0, y: -1, z: 0), perspective: 1)
                .offset(x: isOpen ? 265 : 0)
                .scaleEffect(isOpen ? 0.9 : 1)
                .scaleEffect(show ? 0.92 : 1)
                .ignoresSafeArea()
            
            button.view()
                .frame(width: 44, height: 44)
                .mask(Circle())
                .shadow(color: Color("Shadow").opacity(0.2), radius: 5, x: 0, y: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .offset(x: isOpen ? 216 : 0)
                .onTapGesture {
                    // [EN] As the course did with `setInput("isOpen", value: isOpen)`. [CN] 与课程中的 `setInput("isOpen", value: isOpen)` 相同。
                    if isOpen {
                        button.play()
                    } else {
                        button.stop()
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isOpen.toggle()
                    }
                }
            
            Image(systemName: "person")
                .frame(width: 36, height: 36)
                .background(.white)
                .mask(Circle())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .shadow(color: Color("Shadow").opacity(0.2), radius: 5, x: 0, y: 5)
                .padding()
                .offset(y: 4)
                .offset(x: isOpen ? 100 : 0)
                .onTapGesture {
                    withAnimation(.spring()) {
                        show.toggle()
                    }
                }
            
            if show {
                OnboardingView(show: $show)
                    .background(.white)
                    .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 40)
                    .ignoresSafeArea(.all, edges: .top)
                    .offset(y: show ? -10 : 0)
                    .zIndex(1)
                    .transition(.move(edge: .top))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
