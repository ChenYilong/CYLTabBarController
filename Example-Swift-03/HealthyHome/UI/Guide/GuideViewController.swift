//
//  GuideViewController.swift
//  HealthyHome
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

typealias endBlock = () -> Void

class GuideViewController: UIViewController,UIScrollViewDelegate {

    var numOfPages = 3 //图片数
    var disTimer: DispatchSourceTimer! //计时器
    var time: NSInteger = 5 //时长
    var timeEndBlock: endBlock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //背景色设置
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
        timeBtn.setTitle(String(time) + " 跳过", for: .normal)
        timeBtn.setTitleColor(.blue, for: .normal)
        timeBtn.layer.masksToBounds = true
        timeBtn.layer.cornerRadius = 8
        timeBtn.addTarget(self, action: #selector(timeClicked), for: .touchUpInside)
        self.view.addSubview(timeBtn)
        
        //设置定时器⏲
        disTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        /**
         设置timer的计时参数
         wallDeadline: 什么时候开始
         leeway: 调用频率,即多久调用一次
         */
        //循环执行，马上开始，间隔为1s,误差允许10微秒
        disTimer.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.microseconds(10))
        //执行disTimer事件
        disTimer.setEventHandler {
            // 回到了主线程
            DispatchQueue.main.async {
                self.time -= 1
                if self.time <= 0 {
                    self.disTimer.cancel()
                    self.disTimer = nil
                    self.timeClicked()
                }
                timeBtn.setTitle(String(self.time) + " 跳过", for: .normal)
            }
        }
        //执行disTimer
        disTimer.resume()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = CGFloat(numOfPages - 1) * self.view.bounds.width
        //最后一个继续滑动跳转到主页面
        if scrollView.contentOffset.x > width {
            
            timeClicked()
        }
    }
    
    
    @objc func timeClicked() {
        if self.timeEndBlock != nil {
            self.timeEndBlock()
        }
    }
    
    
}
