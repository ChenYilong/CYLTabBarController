//
//  CustomTextField.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-04-11.
//

import SwiftUI

struct CustomTextField: ViewModifier {
    var image: Image
    func body(content: Content) -> some View {
        content
            .padding(15)
            .padding(.leading, 36)
            .background(.white)
            .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(lineWidth: 1).fill(.black.opacity(0.1)))
            .overlay(image.frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8))
    }
}

extension View {
    func customTextField(image: Image) -> some View {
        modifier(CustomTextField(image: image))
    }
}
