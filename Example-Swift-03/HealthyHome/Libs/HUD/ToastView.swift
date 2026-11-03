//
//  ToastView.swift
//  Swift-UI-UIView
//
//  Created by 康洲 on 2019/5/21.
//  Copyright © 2019 易元江. All rights reserved.
//

import UIKit

// [CN] Toast默认停留时间
// [EN] Default Toast display duration
let toastDispalyDuration: CGFloat = 2.0
// [CN] Toast背景颜色
// [EN] Toast background color
let toastBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)

class ToastView: NSObject {
    
    var contenButton: UIButton
    var duration: CGFloat = toastDispalyDuration
    
    init(text: String) {
        let rect = text.boundingRect(with: CGSize(width: 250, height: CGFloat.greatestFiniteMagnitude), options: [NSStringDrawingOptions.truncatesLastVisibleLine,NSStringDrawingOptions.usesFontLeading,NSStringDrawingOptions.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: rect.width + 40, height: rect.height + 20))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = text
        
        contenButton = UIButton(frame: CGRect(x: 0, y: 0, width: label.frame.size.width, height: label.frame.size.height))
        contenButton.layer.cornerRadius = 2.0
        contenButton.backgroundColor = toastBackgroundColor
        contenButton.addSubview(label)
        contenButton.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
        super.init()
        contenButton.addTarget(self, action: #selector(toastTaped), for: .touchDown)
        // [CN] 添加通知获取手机旋转状态.保证正确的显示效果
        // [EN] Add a notification to get the device rotation state, to ensure correct display
        NotificationCenter.default.addObserver(self, selector: #selector(toastTaped), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    @objc func toastTaped() {
        self.hideAnimation()
    }
    
    // [CN] 移除
    // [EN] Remove
    @objc func dismissToast() {
        contenButton.removeFromSuperview()
    }
    
    // [CN] 屏幕更改监听
    // [EN] Screen change observer
    func deviceOrientationDidChanged(notify _: NSNotification) {
        self.hideAnimation()
    }
    
    // [CN] 设置时长
    // [EN] Set the duration
    func setDuration(duration: CGFloat) {
        self.duration = duration
    }
    // [CN] 居中显示
    // [EN] Show in the center
    func show() {
        guard let window = ToastView.lastWindow else { return }
        contenButton.center = window.center
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    // [CN] 顶部显示
    // [EN] Show at the top
    func showFromTopOffset(top: CGFloat) {
        guard let window = ToastView.lastWindow else { return }
        contenButton.center = CGPoint(x: window.center.x, y: top + contenButton.frame.size.height / 2)
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    // [CN] 底部显示
    // [EN] Show at the bottom
    func showFromBottomOffset(bottom: CGFloat) {
        guard let window = ToastView.lastWindow else { return }
        contenButton.center = CGPoint(x: window.center.x, y: window.frame.size.height - (bottom + contenButton.frame.size.height/2))
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    
    // [CN] MARK: 中间显示
    // [EN] MARK: Show in the center
    class func showCenterWithText(text: String) {
        let toast: ToastView = ToastView(text: text)
        toast.show()
    }
    class func showCenterWithText(text: String, duration: CGFloat) {
        let toast: ToastView = ToastView(text: text)
        toast.setDuration(duration: duration)
        toast.show()
    }
    
    // [CN] MARK: 上方显示
    // [EN] MARK: Show at the top
    class func showTopWithText(text: String) {
        ToastView.showTopWithText(text: text, topOffset: 100.0, duration: toastDispalyDuration)
    }
    class func showTopWithText(text: String, duration: CGFloat) {
        ToastView.showTopWithText(text: text, topOffset: 100, duration: duration)
    }
    class func showTopWithText(text: String, topOffset: CGFloat) {
        ToastView.showTopWithText(text: text, topOffset: topOffset, duration: toastDispalyDuration)
    }
    class func showTopWithText(text: String, topOffset: CGFloat, duration: CGFloat) {
        let toast = ToastView(text: text)
        toast.setDuration(duration: duration)
        toast.showFromTopOffset(top: topOffset)
    }
    
    // [CN] MARK: 下方显示
    // [EN] MARK: Show at the bottom
    class func showBottomWithText(text: String) {
        ToastView.showBottomWithText(text: text, bottomOffset: 100.0, duration: toastDispalyDuration)
    }
    class func showBottomWithText(text: String, duration: CGFloat) {
        ToastView.showBottomWithText(text: text, bottomOffset: 100.0, duration: duration)
    }
    class func showBottomWithText(text: String, bottomOffset: CGFloat) {
        ToastView.showBottomWithText(text: text, bottomOffset: bottomOffset, duration: toastDispalyDuration)
    }
    class func showBottomWithText(text: String, bottomOffset: CGFloat, duration: CGFloat) {
        let toast = ToastView(text: text)
        toast.setDuration(duration: duration)
        toast.showFromBottomOffset(bottom: bottomOffset)
    }
    
    /// Last window of the connected scenes (replaces `UIApplication.shared.windows`, deprecated in iOS 15).
    private static var lastWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .last
    }

    // [CN] 显示动画
    // [EN] Show animation
    @objc func showAnimation() {
        // [CN] 慢到快的进入
        // [EN] Enter from slow to fast
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.contenButton.alpha = 1
        }
    }
    
    // [CN] 隐藏动画
    // [EN] Hide animation
    @objc func hideAnimation() {
        // [CN] 快到慢的退出
        // [EN] Exit from fast to slow
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.contenButton.alpha = 0.0
        }, completion: { _ in
            self.dismissToast()
        })
    }
    
    
}
