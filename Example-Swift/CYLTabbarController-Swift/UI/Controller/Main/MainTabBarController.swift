//
//  MainTabBarController.swift
//

import UIKit

class MainTabBarController: CYLTabBarController  {
  // names of storyboards
  let storyboardNames = ["Home","Connection","Message","Personal"]
  // titles of tabbar
  let titles = ["首页","人脉","消息","我的"]
  // selected images of tabbar
  let selectedImages = ["tab_5th_h","tab_2nd_h","tab_4th_h","tab_3rd_h"]
  // unselected images of tabbar
  let images = ["tab_5th_n","tab_2nd_n","tab_4th_n","tab_3rd_n"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var tabBarItemsAttributes = [[NSObject:AnyObject]]()
    var viewControllers = [UIViewController]()
    
    for i in 0 ..< titles.count {
      let dict: [NSObject : AnyObject] = [
        CYLTabBarItemTitle: titles[i],
        CYLTabBarItemImage: images[i],
        CYLTabBarItemSelectedImage: selectedImages[i]
      ]
      let vc = UIStoryboard(name: storyboardNames[i], bundle: nil).instantiateInitialViewController()
      
      tabBarItemsAttributes.append(dict)
      viewControllers.append(vc!)
    }
    
    self.tabBarItemsAttributes = tabBarItemsAttributes
    self.viewControllers = viewControllers
  }
}

class PlusButtonSubclass : CYLPlusButton,CYLPlusButtonSubclassing{
  class func plusButton() -> AnyObject! {
    let button:PlusButtonSubclass =  PlusButtonSubclass()
    button.setImage(UIImage(named: "icon_middle_add"), forState: UIControlState.Normal)
    button.titleLabel!.textAlignment = NSTextAlignment.Center;
    button.adjustsImageWhenHighlighted = false;
    button.addTarget(button, action: #selector(PlusButtonSubclass.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    
    // set button frame
    button.frame.size.width = 100
    button.frame.size.height = 40
    return button
  }
  
  // button click action
  func buttonClicked(sender:CYLPlusButton) {
    print("hello middle")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    // tabbar UI layout setup
    let imageViewEdge   = self.bounds.size.width * 0.6
    let centerOfView    = self.bounds.size.width * 0.5
    let labelLineHeight = self.titleLabel!.font.lineHeight
    let centerOfTitleLabel = imageViewEdge  + labelLineHeight + 2
    
    //imageView position layout
    self.imageView!.bounds = CGRectMake(0, 0, 40, 40)
    self.imageView!.center = CGPointMake(centerOfView, 0)
    
    //title position layout
    self.titleLabel!.bounds = CGRectMake(0, 0, self.bounds.size.width, labelLineHeight)
    self.titleLabel!.center = CGPointMake(centerOfView, centerOfTitleLabel)
  }
}
