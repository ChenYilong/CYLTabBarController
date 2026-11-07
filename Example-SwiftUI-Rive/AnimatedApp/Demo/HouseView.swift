//
//  HouseView.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-04-11.
//

import SwiftUI

struct HouseView: View {
    // [EN] A state machine without inputs: Rive's current runtime plays it. [CN] 没有输入的状态机：由 Rive 当前的运行时播放。
    let animation = RiveAnimation("house", [.riveStateMachine: "State Machine 1"])
    @State var rooms: Float = 3
    
    var body: some View {
        VStack {
            Stepper(value: $rooms, in: 3...6) {
                Text(String(format: "%.0f", rooms))
            }
            .padding(20)

            animation.view()
        }
        .onChange(of: rooms) { newValue in
            changeValue()
        }
        .onAppear {
            changeValue()
        }
    }
    
    func changeValue() {
        // [EN] Intentionally empty in the course: the house demo does not drive the animation with `rooms` yet.
        // [CN] 课程中有意留空：这个 house 示例尚未用 `rooms` 驱动动画。
    }
}

struct HouseView_Previews: PreviewProvider {
    static var previews: some View {
        HouseView()
    }
}
