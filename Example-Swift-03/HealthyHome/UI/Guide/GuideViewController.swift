//
//  GuideViewController.swift
//  HealthyHome
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

typealias endBlock = () -> Void

class GuideViewController: UIViewController,UIScrollViewDelegate {

    var numOfPages = 3 // [CN] 图片数
    // [EN] Number of images
    var disTimer: DispatchSourceTimer? // [CN] 计时器
    // [EN] Timer
    var time: NSInteger = 5 // [CN] 时长
    // [EN] Duration
    var timeEndBlock: endBlock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // [CN] 背景色设置
        // [EN] Background color settings
        self.view.backgroundColor = .white
        
        let frame = self.view.bounds
        
        let scrollView = UIScrollView()
        scrollView.frame = frame;
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: frame.size.width * CGFloat(numOfPages), height: frame.size.height)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        
        for i in 0 ..< numOfPages {
//            let imgFile = barHeight == 64 ? "guideImage_\(i + 1)_750x1334" : "guide_XR_\(i + 1)"
            let imgFile = "guideImage_\(i + 1)_750x1334"
            let imageView = UIImageView(image: UIImage(named: imgFile))
            imageView.frame = CGRect(x: frame.size.width * CGFloat(i), y: 0, width: frame.size.width, height: frame.size.height)
            scrollView.addSubview(imageView)
        }
        
        self.view.addSubview(scrollView)
        
        let timeBtn = UIButton.init(frame: CGRect(x: frame.size.width - CGFloat(70), y: CGFloat(statusBarHeight), width: CGFloat(55), height: CGFloat(35)))
        timeBtn.backgroundColor = .lineColor()
        timeBtn.setTitle(String(time) + " " + cylDemoLocalizedString("跳过"), for: .normal)
        timeBtn.setTitleColor(.blue, for: .normal)
        timeBtn.layer.masksToBounds = true
        timeBtn.layer.cornerRadius = 8
        timeBtn.addTarget(self, action: #selector(timeClicked), for: .touchUpInside)
        self.view.addSubview(timeBtn)
        
        // [CN] 设置定时器⏲
        // 直接在主队列计时：避免后台 tick 堆积多个 main.async，在 disTimer 置 nil 后再次 cancel 导致崩溃
        // [EN] Set up the timer ⏲
        //      Count directly on the main queue: avoids piling up multiple main.async calls from background ticks,
        //      which would cancel again after disTimer is set to nil and crash
        let disTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        self.disTimer = disTimer
        /**
         [CN] 设置timer的计时参数
         wallDeadline: 什么时候开始
         leeway: 调用频率,即多久调用一次
         [EN] Set the timer's timing parameters
              wallDeadline: when to start
              leeway: call frequency, i.e. how often it is called
         */
        // [CN] 循环执行，马上开始，间隔为1s,误差允许10微秒
        // [EN] Repeat, start immediately, 1s interval, 10 microseconds of allowed leeway
        disTimer.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.microseconds(10))
        // [CN] 执行disTimer事件
        // [EN] Handle the disTimer event
        disTimer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.time -= 1
            timeBtn.setTitle(String(self.time) + " " + cylDemoLocalizedString("跳过"), for: .normal)
            if self.time <= 0 {
                self.timeClicked()
            }
        }
        // [CN] 执行disTimer
        // [EN] Run disTimer
        disTimer.resume()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = CGFloat(numOfPages - 1) * self.view.bounds.width
        // [CN] 最后一个继续滑动跳转到主页面
        // [EN] Swiping further on the last page jumps to the main page
        if scrollView.contentOffset.x > width {
            
            timeClicked()
        }
    }
    
    
    @objc func timeClicked() {
        // [CN] 跳过按钮、滑动到底、倒计时结束都会走这里：只停一次计时器、只回调一次
        // [EN] The skip button, swiping to the end and the countdown finishing all end up here:
        //      stop the timer only once and call back only once
        disTimer?.cancel()
        disTimer = nil
        guard let block = timeEndBlock else { return }
        timeEndBlock = nil
        block()
    }
    
    
}
