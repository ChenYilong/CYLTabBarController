//
//  ToastView.swift
//  Swift-UI-UIView
//
//  Created by 康洲 on 2019/5/21.
//  Copyright © 2019 易元江. All rights reserved.
//

import UIKit

//Toast默认停留时间
let toastDispalyDuration: CGFloat = 2.0
//Toast背景颜色
let ToastBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)

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
        contenButton.backgroundColor = ToastBackgroundColor
        contenButton.addSubview(label)
        contenButton.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
        super.init()
        contenButton.addTarget(self, action: #selector(toastTaped), for: .touchDown)
        //添加通知获取手机旋转状态.保证正确的显示效果
        NotificationCenter.default.addObserver(self, selector: #selector(toastTaped), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    @objc func toastTaped() {
        self.hideAnimation()
    }
    
    //移除
    @objc func dismissToast() {
        contenButton.removeFromSuperview()
    }
    
    //屏幕更改监听
    func deviceOrientationDidChanged(notify: NSNotification) {
        self.hideAnimation()
    }
    
    //设置时长
    func setDuration(duration: CGFloat) {
        self.duration = duration
    }
    //居中显示
    func show() {
        let window: UIWindow = UIApplication.shared.windows.last!
        contenButton.center = window.center
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    //顶部显示
    func showFromTopOffset(top: CGFloat) {
        let window: UIWindow = UIApplication.shared.windows.last!
        contenButton.center = CGPoint(x: window.center.x, y: top + contenButton.frame.size.height / 2)
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    //底部显示
    func showFromBottomOffset(bottom: CGFloat) {
        let window: UIWindow = UIApplication.shared.windows.last!
        contenButton.center = CGPoint(x: window.center.x, y: window.frame.size.height - (bottom + contenButton.frame.size.height/2))
        window.addSubview(contenButton)
        self.showAnimation()
        self.perform(#selector(hideAnimation), with: nil, afterDelay: TimeInterval(duration))
    }
    
    //MARK: 中间显示
    class func showCenterWithText(text: String) {
        let toast: ToastView = ToastView(text: text)
        toast.show()
    }
    class func showCenterWithText(text: String, duration: CGFloat) {
        let toast: ToastView = ToastView(text: text)
        toast.setDuration(duration: duration)
        toast.show()
    }
    
    // MARK: 上方显示
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
    
    // MARK: 下方显示
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
    
    //显示动画
    @objc func showAnimation() {
        UIView.beginAnimations("show", context: nil)
        //慢到快的进入
        UIView.setAnimationCurve(UIView.AnimationCurve.easeIn)
        UIView.setAnimationDuration(0.3)
        contenButton.alpha = 1
        UIView.commitAnimations()
    }
    
    //隐藏动画
    @objc func hideAnimation() {
        UIView.beginAnimations("hide", context: nil)
        //快到慢的退出
        UIView.setAnimationCurve(UIView.AnimationCurve.easeOut)
        UIView.setAnimationDelegate(self)
        UIView.setAnimationDidStop(#selector(dismissToast))
        UIView.setAnimationDuration(0.3)
        contenButton.alpha = 0.0
        UIView.commitAnimations()
    }
    
    
}
