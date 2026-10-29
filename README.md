<p align="center"><a href="https://github.com/ChenYilong/CYLTabBarController"><img src="https://repository-images.githubusercontent.com/44896762/c1d6e880-a8d8-11e9-8bb4-2da8ebc06f0a"></a></p>


# [CN]CYLTabBarController【一行代码实现 Lottie 动画 TabBar】iOS27+ Tested
# [EN]CYLTabBarController [An animated tabBar supported by Lottie with one line of code]


<p align="center">
<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/CYLTabBarController.podspec"><img src="https://img.shields.io/badge/Pod-GetLatestVersion-green.svg?style=flat"></a>
<a href=""><img src="https://img.shields.io/badge/Swift-compatible-orange.svg"></a>
<a href=""><img src="https://img.shields.io/badge/platform-iOS%2012.0%2B-ff69b5152950834.svg"></a>
<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>

</p>


<p align="center">
<a href="https://github.com/ChenYilong/iOSBlog/issues/21"><img src="https://img.shields.io/static/v1.svg?label=QQ%E3%80%81Telegram%20Group&color=blue&message=%E7%82%B9%E5%87%BB%E8%8E%B7%E5%8F%96QQ%E3%80%81Telegram%E7%BE%A4%E4%BF%A1%E6%81%AF&color=green"></a>
</p>

<p align="center">
<a href="https://github.com/ChenYilong/CYLTabBarController/releases.atom"><img src="https://img.shields.io/badge/RSS feed (full text feed)-订阅仓库版本更新-yellow.svg"></a>
</p>

<p align="center">
<a href="https://github.com/ChenYilong/iOSBlog/releases.atom"><img src="https://img.shields.io/badge/RSS feed (full text feed)-订阅我的博客更新-yellow.svg"></a>
</p>


<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="http://ww4.sinaimg.cn/large/006tNc79ly1g5zsnmaw40g30go04ck08.gif"></a></p>

<p align="center">
 <a href="http://ww2.sinaimg.cn/large/006tNc79ly1g5et6q6sm5j30go0goaar.jpg"><img src="http://ww1.sinaimg.cn/large/006tNc79ly1g5esb5j4oaj300w00rdfn.jpg"></a>
<a href="http://weibo.com/luohanchenyilong"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6um2edt3jj300w00q3y9.jpg"></a>
<a href="https://twitter.com/iOSChenYilong"><img src="http://ww3.sinaimg.cn/large/006tNc79ly1g5erhikv2kj300w00wgld.jpg"></a>
<a href="https://github.com/ChenYilong"><img src="http://ww3.sinaimg.cn/large/006tNc79gy1g5ercvzgxzj300w00wmwx.jpg"></a>
<a href="https://qm.qq.com/cgi-bin/qm/qr?k=SEdIYBh52YzquCEo8cmPwgkko1VgSAlw&authKey=sGcG%2BGB81DW%2Ba8v3dCufFSNoxhykAU61Uz%2B%2BqDiKQN2BGHP2xHYVI2tc0Cah2lpu"><img src="http://ww1.sinaimg.cn/large/006tNc79ly1g5euf38fedj300w00wjr5.jpg"></a>
<a href="https://t.me/iosobjc"><img src="http://ww2.sinaimg.cn/large/006tNc79ly1g5eus39934j300w00w0r1.jpg"></a>
<a href="http://s.zhihu.com/BU5Mp"><img src="http://ww4.sinaimg.cn/large/006tNc79ly1g5eu9melwaj300w00w3ya.jpg"></a>
</p>


--------------------------------------------

## [CN]阅读须知
## [EN]Before Reading

| 中文 | English |
|:---|:---|
| `[CN]` 表示中文内容。 | `[CN]` indicates Chinese content. |
| `[EN]` 表示英文内容。 | `[EN]` indicates English content. |
| [点此获取 QQ 群、Telegram 群交流信息](https://github.com/ChenYilong/iOSBlog/issues/21)。 | [Join the QQ or Telegram groups](https://github.com/ChenYilong/iOSBlog/issues/21). |

## [CN]最新版本预览
## [EN]Preview of the latest version

Preview of the latest version on iOS 27+




### [CN]iOS 27 和 iPhone Duo 适配
### [EN]iOS 27 and iPhone Duo support

CYLTabBarController 现已适配 iOS 27，新增如下功能：
CYLTabBarController now supports iOS 27 with the following improvements:
<img width="1206" height="768" alt="Image" src="https://github.com/user-attachments/assets/9b6acbb4-d9dd-461e-bc3b-ea8916e97d6d" />

现在已适配 iPhone Duo 的横向布局与竖向布局，请更新至 CYLTabBarController 1.99.66 查看。
It also supports both landscape and portrait layouts on iPhone Duo. Update to CYLTabBarController 1.99.66 to try it.

CYLTabBarController 现已适配 iOS 27 和 iPhone Duo，更新内容如下：
CYLTabBarController now supports iOS 27 and iPhone Duo with the following features:

| 中文 | English |
|:---|:---|
| ✅ 支持横向布局与竖向布局 | ✅ Supports landscape and portrait layouts. |
| ✅ 支持扁平样式与液态玻璃样式 | ✅ Supports flat and Liquid Glass styles. |
| ✅ 所有样式均支持加号按钮居中显示。 | ✅ The plus button can be centered in every style. |
| ✅ 零代码适配：已经接入 CYLTabBar 液态玻璃样式或扁平样式的代码，无需修改代码，更新版本即可适配 iPhone Duo。 | ✅ Zero-code adaptation: apps already using the CYLTabBar Liquid Glass or flat style require no code changes to support iPhone Duo. |
| ✅ 审核友好，适配代码均为纯原生公开 API，无审核风险。 | ✅ Review-friendly: the adaptation uses only public native APIs. |

请更新 CYLTabBarController 1.99.66 查看演示：
Update to CYLTabBarController 1.99.66 to see the demo:



<img width="1556" height="1080" alt="Image" src="https://github.com/user-attachments/assets/fad2a853-124f-4152-b18b-9db379077797" />

<img width="1556" height="1080" alt="Image" src="https://github.com/user-attachments/assets/30c636a7-819c-495f-9906-eb99427a8706" />

| 中文 | English |
|:---|:---|
| ✅ iOS 27 下无需新增代码即可启用扁平风格；保留 `UIDesignRequiresCompatibility` 时会自动切换到扁平样式。 | ✅ Enable the flat style on iOS 27 without adding code; `UIDesignRequiresCompatibility` automatically selects the flat style. |
| ✅ 扁平风格作为独立组件集成，降低耦合并减小包体积。 | ✅ The flat style is integrated as an independent component for lower coupling and a smaller package size. |
| ✅ 扁平风格与液态玻璃样式共享 API，只需修改样式属性即可切换。 | ✅ The flat and Liquid Glass styles share the same APIs; switch styles by changing the appearance property. |
| ✅ 支持运行期间在两种样式之间切换，适合 A/B 测试和灰度发布。 | ✅ Switch between styles at runtime for A/B testing and staged rollout. |
| ✅ 液态玻璃样式继承自 `UITabBar`，支持系统样式设置，并提供 PlusButton。 | ✅ The Liquid Glass style inherits from `UITabBar`, supports system appearance settings, and adds PlusButton support. |
| ✅ 支持同时展示 Lottie 动画、液态玻璃效果和红点角标动画。 | ✅ Display Lottie animations, Liquid Glass effects, and animated badges together. |
| ✅ 建议升级到 1.99.41 或更高版本进行 iOS 27 适配。 | ✅ Upgrade to 1.99.41 or later for iOS 27 support. |
CYLTabBarController 现已支持在 iOS 26 上实现以下效果，请更新至 1.99.39 或更高版本。
CYLTabBarController supports the following features on iOS 26. Update to version 1.99.39 or later:

| 中文 | English |
|:---|:---|
| ✅ 同时展示 Lottie 动画与液态玻璃效果。 | ✅ Display Lottie animations and the Liquid Glass effect together. |
| ✅ 支持将 PlusButton 居中显示在液态玻璃效果上，并保留旧版本的按钮逻辑。 | ✅ Center PlusButton over the Liquid Glass effect while preserving the previous button behavior. |
| ✅ 液态玻璃效果不使用私有 API，适合 Apple 审核。 | ✅ Liquid Glass uses no private APIs and is suitable for App Store review. |
| ✅ 使用纯原生液态玻璃效果，支持系统对相关属性的设置。 | ✅ Use a native Liquid Glass effect and support the system appearance settings. |
| ✅ 面向企业生产环境的开源解决方案。 | ✅ An open-source solution suitable for production environments. |
| ✅ 对现有集成友好，升级通常只需少量代码修改。 | ✅ Existing integrations can usually be upgraded with minimal code changes. |
| ✅ 不依赖 UI 兼容模式，适合 iOS 27 审核。 | ✅ Does not depend on UI compatibility mode and is review-friendly on iOS 27. |
| ✅ GitHub：<https://github.com/ChenYilong/CYLTabBarController> | ✅ GitHub: <https://github.com/ChenYilong/CYLTabBarController> |



<img width="1320" height="477" alt="Image" src="https://github.com/user-attachments/assets/a0e89aba-3f3b-4583-bb5e-0c291b76856a" />
<img width="1320" height="519" alt="Image" src="https://github.com/user-attachments/assets/a867a1a3-fcf2-411c-8b01-f56711016034" />



![Image](https://github.com/user-attachments/assets/eb8fc2c1-1998-4280-92ac-15d26732904c)

![Image](https://github.com/user-attachments/assets/5895c2af-0be7-46e9-8a69-a5576922877b)
![Image](https://github.com/user-attachments/assets/6bc78f3b-5b78-4083-bb3f-28c8a9a1edcc)
![Image](https://github.com/user-attachments/assets/c196f44e-ce4b-4de0-b6be-6cafe5b93292)
![Image](https://github.com/user-attachments/assets/5c2f0a09-6c2b-4506-a3b9-87ca3f1fe779)
![Image](https://github.com/user-attachments/assets/3a2f2c8a-db70-4513-8b7f-0fcff077baec)
1.99.39 版本现已支持在 iOS 26 运行期间增加或删除加号按钮。效果见下方演示，欢迎访问 [Demo](https://github.com/ChenYilong/CYLTabBarController) 进行尝试：
Version 1.99.39 supports adding or removing the plus button at runtime on iOS 26. See the demo below or visit the [Demo](https://github.com/ChenYilong/CYLTabBarController) to try it:

<img width="1320" height="2868" alt="Image" src="https://github.com/user-attachments/assets/4825a10c-df23-42ae-b8d6-322646b090e4" />
<img width="883" height="1917" alt="Image" src="https://github.com/user-attachments/assets/8e6aeca5-8e36-46d0-9626-c6de94edbef3" />

# [CN]谁在使用？已上架 App 列表
# [EN]Who is using it? Published apps




APP name link icon | image  |APP name link icon | image
:-------------:|:-------------:|:-------------:|:-------------:
海底捞  [App Store Link](https://itunes.apple.com/cn/app/%E6%B5%B7%E5%BA%95%E6%8D%9E/id553115181?l=en&mt=8)  ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple123/v4/3f/8c/b2/3f8cb27c-8a47-82b2-fa08-25ca075cee59/AppIcon-1x_U007emarketing-85-220-0-9.png/690x0w.jpg) |  ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple128/v4/20/78/c4/2078c481-aa68-c263-ee3b-22b797ec2209/pr_source.jpg/690x0w.jpg) | C家 [App Store Link](https://itunes.apple.com/cn/app/c%E5%AE%B6/id1123394197?l=en&mt=8) ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple113/v4/cf/9c/35/cf9c35c2-68fa-8d3a-e612-e2560501899b/AppIcon-0-1x_U007emarketing-0-0-85-220-0-5.png/690x0w.jpg) | Lottie 效果  ![](http://ww3.sinaimg.cn/large/006tNc79ly1g3aavtlekdg30ai0l2b2b.gif) |
淘必中-淘宝推出的一款具有营销购物功能的APP [App Store Link](https://itunes.apple.com/cn/app/%E6%B7%98%E5%BF%85%E4%B8%AD/id399737960?l=en&mt=8) ![enter image description here](https://is2-ssl.mzstatic.com/image/thumb/Purple125/v4/f2/8d/58/f28d5806-bf9d-b77b-4e41-5986d96d250b/AppIcon-1x_U007emarketing-85-220-4.png/690x0w.jpg ) | ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple125/v4/67/04/be/6704be9c-de16-fcdd-0376-7bf66a3e3f82/pr_source.png/690x0w.png) | 慧诊健康  [App Store Link](https://itunes.apple.com/cn/app/%E6%85%A7%E8%AF%8A%E5%81%A5%E5%BA%B7/id1434271846?mt=8) ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple124/v4/b4/ae/d3/b4aed30e-996e-2fcc-0234-ebff091c861d/AppIcon-0-1x_U007emarketing-0-0-85-220-0-10.png/690x0w.jpg)|![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple118/v4/6d/f3/33/6df33378-da60-45b3-1c2a-9d286f12ce55/mzl.vgjiebgy.png/690x0w.jpg)
究竟大学 [App Store Link](https://itunes.apple.com/us/app/%E7%A9%B6%E7%AB%9F%E5%A4%A7%E5%AD%A6/id1334531245?mt=8)  ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple123/v4/d8/4a/95/d84a9596-3d02-881e-7646-e90954ffa8bc/AppIcon-0-1x_U007emarketing-0-0-85-220-6.png/690x0w.jpg) | ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple123/v4/ca/4f/f4/ca4ff420-ec42-cc9d-7c8f-d7df388a184d/pr_source.png/690x0w.jpg) | 蕉片 - 短视频拍摄剪辑出电影大片   [App Store Link](https://itunes.apple.com/us/app/%E8%95%89%E7%89%87-%E7%9F%AD%E8%A7%86%E9%A2%91%E6%8B%8D%E6%91%84%E5%89%AA%E8%BE%91%E5%87%BA%E7%94%B5%E5%BD%B1%E5%A4%A7%E7%89%87/id1235972800?mt=8)  ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/2c/14/68/2c1468de-5807-253d-baa4-54cd4b43d7a3/AppIcon-1x_U007emarketing-85-220-4.png/230x0w.jpg)|![](http://ww1.sinaimg.cn/large/006tNc79ly1g3aaq6rnekj30j615hq5m.jpg)
闪剧 - 可以玩的短视频 [App Store Link](https://itunes.apple.com/us/app/%E9%97%AA%E5%89%A7-%E5%8F%AF%E4%BB%A5%E7%8E%A9%E7%9A%84%E7%9F%AD%E8%A7%86%E9%A2%91/id1360997439?mt=8) ![enter image description here](https://is2-ssl.mzstatic.com/image/thumb/Purple113/v4/e6/26/e0/e626e01e-b00d-c36c-fa3c-98c59e5b95b1/AppIcon-0-1x_U007emarketing-0-0-GLES2_U002c0-512MB-sRGB-0-0-0-85-220-0-0-0-7.png/690x0w.jpg)| ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple113/v4/23/70/57/23705710-9ee4-f7f0-9763-1ad2e5cb7cf6/pr_source.jpg/690x0w.jpg) | 土狗云商城 [App Store Link](https://itunes.apple.com/cn/app/%E5%9C%9F%E7%8B%97%E4%BC%98%E4%BA%AB/id1239005385?mt=8)  ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple113/v4/1c/06/93/1c0693ef-db45-de8c-5b39-1b966d58c930/AppIcon-0-1x_U007emarketing-0-0-85-220-0-7.png/690x0w.jpg)|![](http://ww4.sinaimg.cn/large/006tNc79ly1g3aaqwf078j30u01sxx6r.jpg)
Analyst.ai [App Store Link](https://itunes.apple.com/us/app/analyst-ai/id1345754742?mt=8) ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple113/v4/33/89/1d/33891d65-022e-88a3-b495-7fea6fe77a32/AppIcon-0-1x_U007emarketing-0-0-85-220-0-5.png/690x0w.jpg)| ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple123/v4/35/33/77/35337725-e80d-7b4c-6422-0cac61039917/pr_source.png/690x0w.jpg) | 美膳校园  [App Store Link](https://itunes.apple.com/us/app/%E7%BE%8E%E8%86%B3%E6%A0%A1%E5%9B%AD/id1447211131?mt=8)  ![enter image description here](https://is2-ssl.mzstatic.com/image/thumb/Purple113/v4/de/f7/be/def7be95-abc6-df2e-78c5-8318eae418be/AppIcon-0-1x_U007emarketing-0-0-85-220-0-2.png/690x0w.jpg)| ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple128/v4/e0/e8/aa/e0e8aadf-6692-d974-7962-778160e7eb5f/pr_source.png/690x0w.png)
 全聚星 [App Store Link](https://itunes.apple.com/us/app/%E5%85%A8%E8%81%9A%E6%98%9F/id1140827531?mt=8) ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/4d/a2/57/4da25727-eda7-c7f8-8ce5-3b44591f3863/AppIcon-1x_U007emarketing-85-220-4.png/690x0w.jpg) |![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple118/v4/be/5f/0c/be5f0cbb-0265-b34d-bc34-ab9859f97350/mzl.bwmxymgk.jpg/690x0w.jpg) | Yesoul  [App Store Link](https://itunes.apple.com/us/app/yesoul/id1144444969?mt=8) ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple113/v4/3f/0b/80/3f0b80df-e7fd-7c86-c3d2-472393304509/AppIcon-0-1x_U007emarketing-0-0-sRGB-85-220-0-7.png/690x0w.jpg) | ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple123/v4/bb/96/9f/bb969f5e-48e8-b721-2db3-cf26d7b916f8/pr_source.png/460x0w.jpg)
贵州充电通 [App Store Link](https://itunes.apple.com/us/app/%E8%B4%B5%E5%B7%9E%E5%85%85%E7%94%B5%E9%80%9A/id1455932848?mt=8&app=itunes&ign-mpt=uo%3D4) ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple113/v4/d5/db/44/d5db4437-d409-ff48-3c19-1feabbd7b2a1/AppIcon-0-1x_U007emarketing-0-0-sRGB-85-220-0-7.png/690x0w.jpg) | ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple123/v4/17/51/23/17512338-5bf2-3f4a-bda8-c4986dfe5be6/pr_source.png/690x0w.jpg) | 卓尔购  [App Store Link](https://itunes.apple.com/cn/app/%E5%8D%93%E5%B0%94%E8%B4%AD-%E6%89%B9%E5%8F%91%E9%87%87%E8%B4%AD%E8%BF%9B%E8%B4%A7%E9%A6%96%E9%80%89/id1063104387?mt=8)  ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple114/v4/3c/36/e5/3c36e51e-47e9-0526-5652-bbc6acf3739c/mzl.emuqqmck.png/690x0w.jpg) | ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple125/v4/fc/eb/e2/fcebe232-3a72-93fc-ed3a-2942ac22ab79/pr_source.png/690x0w.png)
卓越管家 [App Store Link](https://itunes.apple.com/cn/app//id1268483803?mt=8) ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple123/v4/b9/6a/d8/b96ad81a-3805-b1c8-3a56-83940fed4b01/AppIcon-0-1x_U007emarketing-0-85-220-5.png/690x0w.jpg) | ![enter image description here](https://is3-ssl.mzstatic.com/image/thumb/Purple113/v4/ca/f8/f8/caf8f846-ddc9-2ada-99c3-9758fc099288/pr_source.png/690x0w.jpg) | 悦守护 [App Store Link](https://itunes.apple.com/cn/app/%E6%82%A6%E5%AE%88%E6%8A%A4/id1347678565?mt=8) | ![](http://ww2.sinaimg.cn/large/006tNc79ly1g3a9upgmmjj30j615iads.jpg)
筑集采采购端 [App Store Link](https://itunes.apple.com/cn/app//id1041802973?mt=8)  ![enter image description here](https://is2-ssl.mzstatic.com/image/thumb/Purple123/v4/f4/d2/1d/f4d21df2-57da-e0a0-5de2-2c9437553fcb/AppIcon-0-1x_U007emarketing-0-0-85-220-7.png/690x0w.jpg) | ![](http://ww1.sinaimg.cn/large/006tNc79ly1g3aa9fncl1j30j60y3adb.jpg) |  筑集采供应端  [App Store Link](https://itunes.apple.com/fr/app//id1035221629?mt=8) ![enter image description here](https://is1-ssl.mzstatic.com/image/thumb/Purple113/v4/8f/ba/6e/8fba6ec9-97e2-e008-f2f2-a30a1641cfa6/AppIcon-0-1x_U007emarketing-0-0-85-220-7.png/690x0w.jpg) |  ![](http://ww3.sinaimg.cn/large/006tNc79ly1g3aaa6itrcj30j60y30xl.jpg) |
桂富宝  [App Store Link](https://itunes.apple.com/nz/app/e%E8%81%94%E7%9B%9F%E5%95%86%E5%9F%8E/id979819957)  ![enter image description here](https://is2-ssl.mzstatic.com/image/thumb/Purple113/v4/6f/62/22/6f6222c7-e54e-2ea7-feb7-ce481e562248/AppIcon-0-1x_U007emarketing-0-0-85-220-0-10.png/690x0w.jpg) | ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple123/v4/4c/80/90/4c8090af-17b4-c152-2ba3-3037d5e7e905/pr_source.png/690x0w.jpg) |  小猪奔奔  [App Store Link](https://itunes.apple.com/cn/app/%E5%B0%8F%E7%8C%AA%E5%A5%94%E5%A5%94-%E7%94%A8%E6%88%B7%E7%89%88/id1124274649?mt=8) ![enter image description here](https://is5-ssl.mzstatic.com/image/thumb/Purple62/v4/78/b6/fd/78b6fde6-084b-3503-b2eb-3e85fa30beb0/AppIcon-1x_U007emarketing-85-220-4.png/690x0w.jpg) | ![enter image description here](https://is4-ssl.mzstatic.com/image/thumb/Purple118/v4/c8/d5/5e/c8d55e4d-9a39-0f12-d121-1bb15d8fed56/mzl.iizreksh.png/690x0w.jpg)
娃娃坞(开发中)![](http://ww3.sinaimg.cn/large/006tNc79ly1g3aaruxhn1j30j60j60t3.jpg) |  ![](http://ww1.sinaimg.cn/large/006tNc79ly1g3aaf0s1yhj30l005iwer.jpg) | 更多APP请访问 [《使用 CYLTabBarController 做的 APP，来这里报道下吧》]( https://github.com/ChenYilong/CYLTabBarController/issues/314 )  | 如果你正在使用也请提交到这里 [《使用 CYLTabBarController 做的 APP，来这里报道下吧》]( https://github.com/ChenYilong/CYLTabBarController/issues/314 )



## [CN]导航
## [EN]CONTENTS

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [与其他自定义TabBarController的区别](#%E4%B8%8E%E5%85%B6%E4%BB%96%E8%87%AA%E5%AE%9A%E4%B9%89tabbarcontroller%E7%9A%84%E5%8C%BA%E5%88%AB)
- [集成后的效果：](#%E9%9B%86%E6%88%90%E5%90%8E%E7%9A%84%E6%95%88%E6%9E%9C)
- [项目结构](#%E9%A1%B9%E7%9B%AE%E7%BB%93%E6%9E%84)
- [使用CYLTabBarController](#%E4%BD%BF%E7%94%A8cyltabbarcontroller)
  - [第一步：使用CocoaPods导入CYLTabBarController](#%E7%AC%AC%E4%B8%80%E6%AD%A5%E4%BD%BF%E7%94%A8cocoapods%E5%AF%BC%E5%85%A5cyltabbarcontroller)
  - [第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组](#%E7%AC%AC%E4%BA%8C%E6%AD%A5%E8%AE%BE%E7%BD%AEcyltabbarcontroller%E7%9A%84%E4%B8%A4%E4%B8%AA%E6%95%B0%E7%BB%84%E6%8E%A7%E5%88%B6%E5%99%A8%E6%95%B0%E7%BB%84%E5%92%8Ctabbar%E5%B1%9E%E6%80%A7%E6%95%B0%E7%BB%84)
  - [第三步：将CYLTabBarController设置为window的RootViewController](#%E7%AC%AC%E4%B8%89%E6%AD%A5%E5%B0%86cyltabbarcontroller%E8%AE%BE%E7%BD%AE%E4%B8%BAwindow%E7%9A%84rootviewcontroller)
  - [第四步（可选）：创建自定义的形状不规则加号按钮](#%E7%AC%AC%E5%9B%9B%E6%AD%A5%E5%8F%AF%E9%80%89%E5%88%9B%E5%BB%BA%E8%87%AA%E5%AE%9A%E4%B9%89%E7%9A%84%E5%BD%A2%E7%8A%B6%E4%B8%8D%E8%A7%84%E5%88%99%E5%8A%A0%E5%8F%B7%E6%8C%89%E9%92%AE)
- [补充说明](#%E8%A1%A5%E5%85%85%E8%AF%B4%E6%98%8E)
  - [自定义 `TabBar` 样式](#%E8%87%AA%E5%AE%9A%E4%B9%89-tabbar-%E6%A0%B7%E5%BC%8F)
    - [捕获 TabBar 点击事件](#%E6%8D%95%E8%8E%B7-tabbar-%E7%82%B9%E5%87%BB%E4%BA%8B%E4%BB%B6)
  - [点击 TabBarButton 时添加动画](#%E7%82%B9%E5%87%BB-tabbarbutton-%E6%97%B6%E6%B7%BB%E5%8A%A0%E5%8A%A8%E7%94%BB)
  - [横竖屏适配](#%E6%A8%AA%E7%AB%96%E5%B1%8F%E9%80%82%E9%85%8D)
  - [访问初始化好的 CYLTabBarController 对象](#%E8%AE%BF%E9%97%AE%E5%88%9D%E5%A7%8B%E5%8C%96%E5%A5%BD%E7%9A%84-cyltabbarcontroller-%E5%AF%B9%E8%B1%A1)
  - [点击 PlusButton 跳转到指定 UIViewController](#%E7%82%B9%E5%87%BB-plusbutton-%E8%B7%B3%E8%BD%AC%E5%88%B0%E6%8C%87%E5%AE%9A-uiviewcontroller)
  - [让TabBarItem仅显示图标，并使图标垂直居中](#%E8%AE%A9tabbaritem%E4%BB%85%E6%98%BE%E7%A4%BA%E5%9B%BE%E6%A0%87%E5%B9%B6%E4%BD%BF%E5%9B%BE%E6%A0%87%E5%9E%82%E7%9B%B4%E5%B1%85%E4%B8%AD)
  - [多TabBar嵌套，并指定PlusButton位置](#%E5%A4%9Atabbar%E5%B5%8C%E5%A5%97%E5%B9%B6%E6%8C%87%E5%AE%9Aplusbutton%E4%BD%8D%E7%BD%AE)
  - [在 Swift 项目中使用 CYLTabBarController](#%E5%9C%A8-swift-%E9%A1%B9%E7%9B%AE%E4%B8%AD%E4%BD%BF%E7%94%A8-cyltabbarcontroller)
  - [搭配 Storyboard 使用 CYLTabBarController](#%E6%90%AD%E9%85%8D-storyboard-%E4%BD%BF%E7%94%A8-cyltabbarcontroller)
  - [源码实现原理](#%E6%BA%90%E7%A0%81%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86)
- [FAQ](#faq)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## [CN]与其他自定义 TabBarController 的区别
## [EN]Comparison with other libraries

| 中文 | English |
|:---|:---|
| **一行代码支持 Lottie 动画 TabBar**<br>[使用方法](https://github.com/ChenYilong/CYLTabBarController/issues/341) | **One line of code enables an animated TabBar with Lottie.**<br>[Usage](https://github.com/ChenYilong/CYLTabBarController/issues/341) |
| **低耦合，易删除**<br>TabBar 配置与业务代码完全分离；PlusButton 由独立子类管理。 | **Loosely coupled and easy to remove.**<br>TabBar configuration is independent from business code, and PlusButton is managed by a separate subclass. |
| **使用系统原生控件**<br>`TabBar` 和 `TabBarItem` 保持系统行为，并支持外观 API。 | **Uses native system controls.**<br>`TabBar` and `TabBarItem` preserve system behavior and support the appearance APIs. |
| **自动管理 PlusButton**<br>自动检测 PlusButton、计算位置并完成布局；按钮样式和 frame 由自定义类实现。 | **Automatically manages PlusButton.**<br>The library detects the PlusButton, calculates its position, and lays it out automatically. |
| **支持动态更新**<br>可以动态添加或删除 PlusButton，并更新 TabBar 样式。 | **Supports runtime updates.**<br>Add or remove the PlusButton and update the TabBar appearance at runtime. |
| **支持超出 TabBar 区域点击**<br>PlusButton 超出 TabBar 的部分仍可响应点击。 | **Supports taps outside the TabBar bounds.**<br>The portion of PlusButton extending beyond the TabBar can still receive taps. |
| **支持指定 PlusButton 位置**<br>可指定 PlusButton 的位置，并支持 Airbnb 风格布局。 | **Supports a custom PlusButton position.**<br>Place the PlusButton at a custom index and support Airbnb-style layouts. |
| **仅显示图标并垂直居中**<br>不设置标题即可只显示图标，并可自定义 TabBar 高度。 | **Icon-only, vertically centered items.**<br>Omit the title to show only icons and customize the TabBar height. |
| **支持自定义角标 View**<br>可以使用自定义 View 展示角标。 | **Supports custom badge views.**<br>Use a custom view to display badges. |
| **支持多 TabBar 嵌套**<br>可嵌套多个 TabBar，并指定 PlusButton 所属的 context。 | **Supports nested TabBars.**<br>Nest multiple TabBars and associate a PlusButton with a specific context. |
| **支持 CocoaPods 和 Swift**<br>易于集成，并兼容 Swift 项目。 | **Supports CocoaPods and Swift.**<br>Easy to integrate and compatible with Swift projects. |
| **支持横竖屏**<br>自动适配不同屏幕方向。 | **Supports portrait and landscape orientations.**<br>Layout adapts to both orientations. |

学习交流群：515295083
Learning group: 515295083.



## [CN]集成后的效果
## [EN]Results after integration

| 中文 | English |
|:---|:---|
| 默认样式<br>![Default style](https://tva1.sinaimg.cn/large/006y8mN6ly1g6uqwf0dm7j30ku048glt.jpg) | Default style<br>![Default style](https://tva1.sinaimg.cn/large/006y8mN6ly1g6uqwf0dm7j30ku048glt.jpg) |
| 自定义不规则 PlusButton<br>![Custom PlusButton](https://tva1.sinaimg.cn/large/006y8mN6ly1g6uqwv5bptj30ku04a74i.jpg) | Custom irregular PlusButton<br>![Custom PlusButton](https://tva1.sinaimg.cn/large/006y8mN6ly1g6uqwv5bptj30ku04a74i.jpg) |

Supports portrait and landscape orientations.

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6us68c57ig30fe0ggwj3.gif"></a></p>


| 中文 | English |
|:---|:---|
| 本仓库配套 Demo 的效果<br>![Demo](https://tva1.sinaimg.cn/large/006y8mN6ly1g6usablffxg30ac0j1e81.gif) | Demo included in this repository<br>![Demo](https://tva1.sinaimg.cn/large/006y8mN6ly1g6usablffxg30ac0j1e81.gif) |
| 另一个 Demo：[CYLTabBarControllerDemoForWeib](https://github.com/ChenYilong/CYLTabBarControllerDemoForWeib)<br>![Demo](https://tva1.sinaimg.cn/large/006y8mN6ly1g6usaqu6ulg30ac0j1ttj.gif) | Another demo: [CYLTabBarControllerDemoForWeib](https://github.com/ChenYilong/CYLTabBarControllerDemoForWeib)<br>![Demo](https://tva1.sinaimg.cn/large/006y8mN6ly1g6usaqu6ulg30ac0j1ttj.gif) |


## [CN]项目结构
## [EN]Project structure

![https://github.com/ChenYilong](https://tva1.sinaimg.cn/large/006y8mN6ly1g6uqzog2wmj30ae0a8js5.jpg)

说明：
The directory structure is organized as follows:

 ```Objective-C

├── CYLTabBarController  # 核心库文件夹；不使用 CocoaPods 时可直接拖入项目
└── Example
    └── Classes
        ├── Module       # 模块类文件夹 / Module classes
        │   ├── Home
        │   ├── Message
        │   ├── Mine
        │   └── SameCity
        └── View         # CYLPlusButton 子类；演示自定义不规则 PlusButton


 ```


## [CN]使用 [CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController)
## [EN]Using [CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController)

四步完成主流 App 框架搭建：
Build a mainstream app structure in four steps:

  1. [第一步 / Step 1：使用 CocoaPods 导入 CYLTabBarController](#第一步使用-cocoapods-导入-cyltabbarcontroller)
  2. [第二步 / Step 2：设置控制器和 TabBar 属性数组](#第二步设置-cyltabbarcontroller-的两个数组)
  3. [第三步 / Step 3：设置 RootViewController](#第三步将-cyltabbarcontroller-设置为-window-的-rootviewcontroller)
  4. [第四步 / Step 4（可选）：创建自定义 PlusButton](#第四步可选创建自定义的不规则加号按钮)


### [CN]第一步：使用 CocoaPods 导入 CYLTabBarController
### [EN]Step 1: Import CYLTabBarController with CocoaPods

#### [CN]1. 安装 CocoaPods
#### [EN]1. Install CocoaPods

如果您的机器上已经安装了 CocoaPods，直接进入下一步即可。
If CocoaPods is already installed, continue to the next step.

如果网络环境允许直接访问 RubyGems，请在终端运行：
If RubyGems is directly accessible, run:

  ```
  sudo gem install cocoapods
  ```

如果无法直接访问 RubyGems，可以使用 Ruby China 镜像：
If RubyGems is unavailable, use the Ruby China mirror:

  在终端依次运行以下命令：

  ```
  gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
 
  sudo gem install cocoapods
  ```

#### [CN]2. 查询 CocoaPods 源
#### [EN]2. Search the CocoaPods repository

  在终端中运行以下命令：

  ```
  pod search CYLTabBarController
  ```

注意：该命令搜索的是本机缓存，并不会联网查询。
Note: this command searches the local cache and does not query the network.

如果没有找到库或版本不是最新，请更新本地源：
If the library is missing or outdated, update the local repository:

  ```
  pod repo update
  ```

#### [CN]3. 使用 CocoaPods 导入
#### [EN]3. Integrate with CocoaPods

进入工程目录并初始化 Podfile：
Open your project directory and initialize a Podfile:

  ```
  pod init
  ```

如果尚未安装 CocoaPods，也可以运行：
If CocoaPods is not installed, run:

 ```
 gem install cocoapods
 ```

打开 Podfile，在目标 target 中加入以下内容。版本号请以 [podspec](https://github.com/ChenYilong/CYLTabBarController/blob/master/CYLTabBarController.podspec) 为准。
Open the Podfile and add the following line to your target. Check the [podspec](https://github.com/ChenYilong/CYLTabBarController/blob/master/CYLTabBarController.podspec) for the latest version.

  在文件 `Podfile` 中加入以下内容：

 ```
 pod 'CYLTabBarController', '~> 1.24.0'
 ```

安装依赖：
Install the dependency:

 ```
 pod install
 ```

如果不希望更新 spec 仓库，可使用：
To avoid updating the spec repository, use:

 ```
 # 禁止升级 CocoaPods 的 spec 仓库，否则会卡在 Analyzing dependencies，非常慢
 pod update --verbose --no-repo-update
 ```

如果提示找不到库，请移除 `--no-repo-update`。
If the library cannot be found, remove `--no-repo-update`.

安装完成后，CocoaPods 会在工程根目录生成 `.xcworkspace` 文件。请使用该文件打开工程，而不是 `.xcodeproj`。
After installation, CocoaPods creates an `.xcworkspace` file in the project root. Open the project with this file instead of the `.xcodeproj`.

### [CN]CocoaPods 使用说明
### [EN]CocoaPods usage notes

#### [CN]指定 CYLTabBarController 版本
#### [EN]Pinning the CYLTabBarController version

可以使用以下版本约束：
You can use the following version constraints:

`>= 1.n.X` 会根据您本地的 CocoaPods 源列表，导入不低于 `1.(n+1).X` 版本的 CYLTabBarController。

`~> 1.n.X` 会根据您本地的 CocoaPods 源列表，介于 1.n.X~1.(n+1).0 之前版本的 CYLTabBarController。

建议锁定版本，便于团队协作。
Pinning a version is recommended for consistent team builds.

（此处示例可能是旧版本，使用时请替换为最新版，最新版信息可以从这里获取：<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/CYLTabBarController.podspec"><img src="https://img.shields.io/badge/Pod-GetLatestVersion-green.svg?style=flat"></a>）


```
pod 'CYLTabBarController', '~> 1.24.0'
```


#### [CN]升级本地 CocoaPods 源
#### [EN]Update the local CocoaPods repository

CocoaPods 会在本地缓存源服务器上的版本。如果搜索不到最新版本，请运行：
CocoaPods caches versions locally. Run the following command when the latest version is unavailable:

 ```
 pod repo update
 ```

#### [CN]升级工程中的 CYLTabBarController 版本
#### [EN]Upgrade CYLTabBarController in the project

修改 Podfile 中的版本后运行：
After changing the version in the Podfile, run:

 ```
 pod update
 ```


#### [CN]清除 CocoaPods 本地缓存
#### [EN]Clear the CocoaPods cache

如果下载文件损坏，可以删除 `~/Library/Caches/CocoaPods/Pods/Release` 后重新导入。
If downloaded files are corrupted, remove `~/Library/Caches/CocoaPods/Pods/Release` and integrate again.

#### [CN]查看当前使用的版本
#### [EN]Check the installed version

在 `Podfile.lock` 中可以查看项目使用的版本。
The installed version is recorded in `Podfile.lock`.

更多信息请参考 [CocoaPods 文档](https://cocoapods.org/)。
For more information, see the [CocoaPods documentation](https://cocoapods.org/).

### [CN]使用 Carthage 导入 CYLTabBarController（可选）
### [EN]Import CYLTabBarController with Carthage (optional)

除了 CocoaPods 和 Swift Package Manager，也可以通过 [Carthage](https://github.com/Carthage/Carthage) 集成本库。在 `Cartfile` 中添加：

```
github "ChenYilong/CYLTabBarController"
```

然后执行：

```
carthage update --use-xcframeworks
```

构建完成后，将生成的 `CYLTabBarController.xcframework` 拖入工程，并在 "Frameworks, Libraries, and Embedded Content" 中设置为 `Embed & Sign`。

> 说明：Carthage 构建的是不含 Lottie 动画相关文件（`LottieSwift` 目录）的核心功能集，与 CocoaPods 的 `Core`子规范（subspec）范围一致。

### [CN]第二步：设置 CYLTabBarController 的两个数组
### [EN]Step 2: Configure the view controller and tab bar item attribute arrays

 ```Objective-C
 //MainTabBarController

@interface MainTabBarController : CYLTabBarController
@end


- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    /**
     * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     */
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;//UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    UIOffset titlePositionAdjustment = UIOffsetMake(0, -3.5);
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithViewControllers:self.viewControllers
                                                                               tabBarItemsAttributes:self.tabBarItemsAttributesForController
                                                                                         imageInsets:imageInsets
                                                                             titlePositionAdjustment:titlePositionAdjustment
                                                                                             context:nil
                                             ];
    [self customizeTabBarAppearance:tabBarController];
    self.navigationController.navigationBar.hidden = YES;
    return (self = (MainTabBarController *)tabBarController);
}

- (NSArray *)viewControllers {
    CYLHomeViewController *firstViewController = [[CYLHomeViewController alloc] init];
    UIViewController *firstNavigationController = [[CYLBaseNavigationController alloc]
                                                   initWithRootViewController:firstViewController];
    [firstViewController cyl_setHideNavigationBarSeparator:YES];
    CYLSameCityViewController *secondViewController = [[CYLSameCityViewController alloc] init];
    UIViewController *secondNavigationController = [[CYLBaseNavigationController alloc]
                                                    initWithRootViewController:secondViewController];
    [secondViewController cyl_setHideNavigationBarSeparator:YES];
    NSArray *viewControllers = @[
                                 firstNavigationController,
                                 secondNavigationController,
                                 ];
    return viewControllers;
}

- (NSArray *)tabBarItemsAttributesForController {
    NSDictionary *firstTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle : @"首页",
                                                 CYLTabBarItemImage : self.darkMode ? @"home_highlight" : @"home_normal",  /* NSString and UIImage are supported*/
                                                 CYLTabBarItemSelectedImage : @"home_highlight",  /* NSString and UIImage are supported*/
                                                 };
    NSDictionary *secondTabBarItemsAttributes = @{
                                                  CYLTabBarItemTitle : @"同城",
                                                  CYLTabBarItemImage : self.darkMode ? @"fishpond_highlight" : @"fishpond_normal",
                                                  CYLTabBarItemSelectedImage : @"fishpond_highlight",
                                                  };


    NSArray *tabBarItemsAttributes = @[
                                       firstTabBarItemsAttributes,
                                       secondTabBarItemsAttributes,
                                       ];
    return tabBarItemsAttributes;
}
 ```

在这个字典中，`CYLTabBarItemImage` 和 `CYLTabBarItemSelectedImage` 支持 `NSString`、`UIImage` 两种格式。
不设置 `CYLTabBarItemTitle` 时，只显示图标并自动居中。

The `CYLTabBarItemImage` and `CYLTabBarItemSelectedImage` values support both `NSString` and `UIImage`.
Omit `CYLTabBarItemTitle` to display and center the icon only.

### [CN]第三步：将 CYLTabBarController 设置为 window 的 RootViewController
### [EN]Step 3: Set CYLTabBarController as the window's root view controller


 ```Objective-C
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 /* *省略部分：   * */
    [self.window setRootViewController:self.tabBarController];
 /* *省略部分：   * */
    return YES;
}
 ```

也可以将 CYLTabBarController 的子类设置为 RootViewController，或将其 NavigationViewController 设置为 RootViewController。
Demo 使用后者，便于动态更新。

You can also use a CYLTabBarController subclass, or its NavigationViewController, as the root view controller.
The demo uses the latter so the hierarchy can be updated dynamically.


### [CN]第四步（可选）：创建自定义的不规则加号按钮
### [EN]Step 4 (optional): Create a custom irregular plus button


创建一个继承自 `CYLPlusButton` 的类，并按以下步骤配置：
Create a `CYLPlusButton` subclass and follow these steps:


1. 实现 `CYLPlusButtonSubclassing` 协议。
   Conform to `CYLPlusButtonSubclassing`.

2. 注册子类：调用 `[YourClass registerPlusButton]`。建议在 RootViewController 的 `viewDidLoad` 或 `application:didFinishLaunchingWithOptions:` 中注册。
   Register the subclass with `[YourClass registerPlusButton]` from `viewDidLoad` or `application:didFinishLaunchingWithOptions:`.

不要在子类的 `+load` 方法中注册，否则在 iOS 10 上可能发生崩溃。
Do not register it from `+load`, because this may crash on iOS 10.

 ```Objective-C
 + (void)load {
    [super registerPlusButton];
 }
 ```

协议提供以下可选方法：
The protocol provides the following optional methods:

 ```Objective-C
+ (NSUInteger)indexOfPlusButtonInTabBar;
+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;
+ (UIViewController *)plusChildViewController;
+ (BOOL)shouldSelectPlusChildViewController;
 ```

这些方法的作用如下：
Their roles are described below.

 ```Objective-C
 + (NSUInteger)indexOfPlusButtonInTabBar;
 ```

用于自定义 PlusButton 的位置。未实现时默认居中；当 TabBarItem 数量为奇数时必须实现，否则会抛出异常。

Use this method to customize the PlusButton index. It defaults to the center, but must be implemented when the number of TabBarItems is odd.

主要适用于如下情景：

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6gy1g92nics1hvj30a906u3ym.jpg"></a></p>


Airbnb app 效果 / Airbnb-style layout:

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6gy1g92nir57tmg308w0fsapi.gif"></a></p>

 ```Objective-C
+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;
 ```

该方法用于调整自定义按钮中心点在 Y 轴上的位置，适用于按钮超出 `TabBar` 边界的场景。
返回值为按钮中心点 Y 坐标与 `TabBar` 高度的比值；不实现时使用自动布局。

Use this method to adjust the button center on the Y axis, especially when it extends beyond the `TabBar`.
The return value is the button center Y coordinate divided by the `TabBar` height. Automatic positioning is used when it is not implemented.

内部实现时，会使用该返回值来设置 PlusButton 的 centerY 坐标，公式如下：

`PlusButtonCenterY = multiplierOfTabBarHeight * taBarHeight + constantOfPlusButtonCenterYOffset;`

当 `constantOfPlusButtonCenterYOffset` 为 0 且 `multiplierOfTabBarHeight` 为 0.5 时，PlusButton 居中；小于 0.5 时向上，大于 0.5 时向下。

With an offset of 0, a multiplier of 0.5 centers the PlusButton. Values below 0.5 move it upward; values above 0.5 move it downward.


 ```Objective-C
+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight;
 ```

参考 `+multiplierOfTabBarHeight:` 中的公式：

`PlusButtonCenterY = multiplierOfTabBarHeight * taBarHeight + constantOfPlusButtonCenterYOffset;`

`constantOfPlusButtonCenterYOffset` 大于 0 时向下偏移，小于 0 时向上偏移。
Positive values move the button downward; negative values move it upward.

如果只实现该方法而未实现 `+multiplierOfTabBarHeight:`，偏移量会叠加到默认布局逻辑上。
If only this method is implemented, the offset is applied on top of the default layout.

详见 Demo 中 `CYLPlusButtonSubclass` 的实现。
See `CYLPlusButtonSubclass` in the demo for a complete implementation.

 ```Objective-C
+ (UIViewController *)plusChildViewController;
 ```

详见 [点击 PlusButton 跳转到指定 UIViewController](#点击-plusbutton-跳转到指定-uiviewcontroller)。
See [Navigating to a UIViewController by tapping the PlusButton](#点击-plusbutton-跳转到指定-uiviewcontroller).


另外，如果加号按钮超出了边界，一般需要手动调用如下代码取消 tabbar 顶部默认的阴影，可在 AppDelegate 类中调用：


 ```Objective-C
    //去除 TabBar 自带的顶部阴影
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
 ```

// iOS 10 and later: use -[CYLTabBarController hideTabBarShadowImageView].
// See the AppDelegate example.

#### [CN]调整 PlusButton 与 TabBarItem 的宽度
#### [EN]Customize the PlusButton and TabBarItem widths

`CYLTabBarController` 使用以下计算方式：
`CYLTabBarController` uses the following formula:

 ```Objective-C
 TabBarItem 宽度 ＝  ( TabBar 总宽度 －  PlusButton 宽度  ) / (TabBarItem 个数)
 ```

因此只需修改 PlusButton 的宽度即可改变各 TabBarItem 的宽度。
Change the PlusButton width to customize the width of the other TabBarItems.

例如，在 Demo 的 `CYLPlusButtonSubclass.m` 中：
For example, in `CYLPlusButtonSubclass.m`:

把

 ```Objective-C
 [button sizeToFit];
 ```

改为

 ```Objective-C
 button.frame = CGRectMake(0.0, 0.0, 250, 100);
 button.backgroundColor = [UIColor redColor];
 ```

效果如下：
The result is shown below:
1.24.0

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6ur17yxa3j30yi0c6abk.jpg"></a></p>


你也可以测试 `CYLTabBarController` 的以下特性：
You can also test this feature:

> 即使 PlusButton 超出 TabBar 区域，超出部分仍可响应点击事件。
> The portion of PlusButton outside the TabBar bounds can still receive taps.

你还可以在任意位置读取 `CYLPlusButtonWidth`，该 extern 定义在 `CYLTabBarController.h` 中。
参考 `+[CYLTabBarControllerConfig customizeTabBarAppearance:]` 的用法。

The PlusButton width is also available through the `CYLPlusButtonWidth` extern declared in `CYLTabBarController.h`.
See `+[CYLTabBarControllerConfig customizeTabBarAppearance:]` for an example.



## [CN]补充说明
## [EN]Additional notes



### [CN]自定义 `TabBar` 样式
### [EN]Customizing the `TabBar` appearance

可以在 `-application:didFinishLaunchingWithOptions:` 中进一步自定义 `TabBar` 样式。
Customize the `TabBar` appearance from `-application:didFinishLaunchingWithOptions:`:

 ```Objective-C
 /**
 *  tabBarItem 的选中和不选中文字属性、背景图片
 */
- (void)customizeInterface {

    // 普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor grayColor];

    // 选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor darkGrayColor];

    // 设置文字属性
    UITabBarItem *tabBar = [UITabBarItem appearance];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [tabBar setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];

    // 设置背景图片
    UITabBar *tabBarAppearance = [UITabBar appearance];
    [tabBarAppearance setBackgroundImage:[UIImage imageNamed:@"tabbar_background"]];
}

 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 /* *省略部分：   * */
    [self.window makeKeyAndVisible];
    [self customizeInterface];
    return YES;
}
 ```

#### [CN]捕获 TabBar 点击事件
#### [EN]Handling TabBar selection events

实现以下代理方法即可捕获点击事件。
Implement the following delegate methods to observe selections.

下面的方法可以捕获 `TabBar` 上被点击的控件，包括 `UITabBarButton`、PlusButton 或其他 `UIControl`。
如果 PlusButton 自身添加了点击事件，点击它时不会触发该代理方法。

This method reports the selected control, including `UITabBarButton`, PlusButton, or any other `UIControl`.
It is not called for PlusButton when PlusButton has its own action.

 ```Objective-C
//CYLTabBarController.h

@protocol CYLTabBarControllerDelegate <NSObject>

/*!
 * @param tabBarController The tab bar controller containing viewController.
 * @param control Selected UIControl in TabBar.
 * @attention If PlusButton also add an action, then this delegate method will not be invoked when the PlusButton is selected.
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control;

@end

 ```

下面的方法可以捕获跳转前的控制器和即将跳转到的目标控制器。
The following method receives the current and destination view controllers.

 ```Objective-C
//UITabBarController.h
@protocol UITabBarControllerDelegate <NSObject>
@optional
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController NS_AVAILABLE_IOS(3_0);
@end

 ```

注意：调用该方法时应始终调用
`[[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];`
以确保 PlusButton 的选中状态正确。

Always call the following method to keep the PlusButton selection state synchronized:

 ```Objective-C
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    return YES;
}
 ```

完整用法请参考 Demo。
See the demo for a complete example.

协议声明方式如下：
Declare the protocols as follows:


 ```Objective-C
@interface AppDelegate ()<UITabBarControllerDelegate, CYLTabBarControllerDelegate>

@end

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //...
        tabBarControllerConfig.tabBarController.delegate = self;
    //...
    return YES;
}
 ```

### [CN]点击 TabBarButton 时添加动画
### [EN]Adding animations when a TabBar button is tapped

Demo 效果：
Demo preview:


<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://ww1.sinaimg.cn/large/006tNbRwly1fg9hu6qnwbg308v0gctcc.gif"></a></p>

实现该代理方法即可获取选中的控件，并直接为其添加动画。
Implement this delegate method to access the selected control and animate it.


 ```Objective-C
//CYLTabBarController.h

@protocol CYLTabBarControllerDelegate <NSObject>

/*!
 * @param tabBarController The tab bar controller containing viewController.
 * @param control Selected UIControl in TabBar.
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control;

@end

 ```

Demo 中的示例代码如下：
The demo uses the following code:

遵循协议：
Conform to the protocols:


 ```Objective-C
@interface AppDelegate ()<UITabBarControllerDelegate, CYLTabBarControllerDelegate>

@end
 ```


 ```Objective-C
 //AppDelegate.m
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
    UIView *animationView;
    // If PlusButton has its own action, this delegate is not called for it.
    if ([control isKindOfClass:[CYLExternPlusButton class]]) {
        UIButton *button = CYLExternPlusButton;
        animationView = button.imageView;
    } else if ([control isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
        for (UIView *subView in control.subviews) {
            if ([subView isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) {
                animationView = subView;
            }
        }
    }

    if ([self cyl_tabBarController].selectedIndex % 2 == 0) {
        [self addScaleAnimationOnView:animationView];
    } else {
        [self addRotateAnimationOnView:animationView];
    }
}

// 缩放动画 / Scale animation
- (void)addScaleAnimationOnView:(UIView *)animationView {
    // Customize the keyframe animation as needed.
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.0,@1.3,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}

// 旋转动画 / Rotation animation
- (void)addRotateAnimationOnView:(UIView *)animationView {
    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        animationView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    } completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.70 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            animationView.layer.transform = CATransform3DMakeRotation(2 * M_PI, 0, 1, 0);
        } completion:nil];
    });
}
 ```

### [CN]横竖屏适配
### [EN]Supporting portrait and landscape orientations

当 TabBar 中包含 PlusButton，且布局依赖 TabBarItem 宽度时，不建议使用系统的 `UIDeviceOrientationDidChangeNotification`。
请使用 `CYLTabBarItemWidthDidChangeNotification` 更新布局，例如根据屏幕方向切换选中 TabBarItem 的背景图。

When a PlusButton is present and your layout depends on TabBarItem width, do not rely on
`UIDeviceOrientationDidChangeNotification`. Use `CYLTabBarItemWidthDidChangeNotification` instead.
The demo shows how to update the selected background image when the orientation changes.


`CYLTabBarController.h` 提供了 `CYLTabBarItemWidth` extern 常量，并会在宽度变化时更新。
`CYLTabBarController.h` exposes the `CYLTabBarItemWidth` extern, which is updated whenever the item width changes.

 ```Objective-C
- (void)updateTabBarCustomizationWhenTabBarItemWidthDidUpdate {
    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
        [self tabBarItemWidthDidUpdate];
};
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemWidthDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:deviceOrientationDidChangeBlock];
}

- (void)tabBarItemWidthDidUpdate {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
        NSLog(@"Landscape Left or Right !");
    } else if (orientation == UIDeviceOrientationPortrait){
        NSLog(@"Landscape portrait!");
    }
    CGSize selectionIndicatorImageSize = CGSizeMake(CYLTabBarItemWidth, [self cyl_tabBarController].tabBar.bounds.size.height);
    [[self cyl_tabBarController].tabBar setSelectionIndicatorImage:[[self class]
                                                                    imageFromColor:[UIColor yellowColor]
                                                                    forSize:selectionIndicatorImageSize
                                                                    withCornerRadius:0]];
}
 ```


<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6us68c57ig30fe0ggwj3.gif"></a></p>



### [CN]访问初始化好的 CYLTabBarController 对象
### [EN]Accessing the initialized CYLTabBarController instance

对于任意 `NSObject` 对象：
For any `NSObject`:

`CYLTabBarController.h` 为 `NSObject` 提供了 `-cyl_tabBarController` 分类属性。
因此可以在任意对象中用一行代码访问已初始化的 CYLTabBarController。

`CYLTabBarController.h` adds `-cyl_tabBarController` to `NSObject`.
It provides one-line access to the initialized CYLTabBarController, similar to retrieving a shared instance.

接口如下：
The interface is:

 ```Objective-C
// CYLTabBarController.h

@interface NSObject (CYLTabBarController)

/**
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, readonly) CYLTabBarController *cyl_tabBarController;

@end
 ```

用法：
Usage:


 ```Objective-C
//导入 CYLTabBarController.h
#import "CYLTabBarController.h"

- (void)viewDidLoad {
    [super viewDidLoad];
    CYLTabBarController *tabbarController = [self cyl_tabBarController];
    /*...*/
}
 ```

### [CN]点击 PlusButton 跳转到指定 UIViewController
### [EN]Navigating to a UIViewController by tapping the PlusButton

通过协议方法即可实现该功能。
Use the protocol methods below to enable this behavior.

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6urdwrhhjj30mx0gjq5r.jpg"></a></p>


实现后，点击 PlusButton 的效果与点击其他 TabBar 按钮一致，并跳转到指定的 UIViewController。
After implementation, tapping PlusButton behaves like tapping another TabBar button and navigates to the specified view controller.

注意：必须同时实现 `+indexOfPlusButtonInTabBar` 指定 PlusButton 的位置。
You must also implement `+indexOfPlusButtonInTabBar` to define its position.

协议示例：
Protocol example:


 ```Objective-C
#pragma mark - CYLPlusButtonSubclassing

+ (UIViewController *)plusChildViewController {
    UIViewController *plusChildViewController = [[UIViewController alloc] init];
    plusChildViewController.view.backgroundColor = [UIColor redColor];
    plusChildViewController.navigationItem.title = @"PlusChildViewController";
    UIViewController *plusChildNavigationController = [[UINavigationController alloc]
                                                   initWithRootViewController:plusChildViewController];
    return plusChildNavigationController;
}

+ (NSUInteger)indexOfPlusButtonInTabBar {
    return 2;
}

+ (BOOL)shouldSelectPlusChildViewController {
    BOOL isSelected = CYLExternPlusButton.selected;
    return YES;
}

+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight {
    return  0.3;
}

+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight {
    return (CYL_IS_IPHONE_X ? - 6 : 4);
}

//+ (NSString *)tabBarContext {
//    return NSStringFromClass([self class]);
//}

 ```


也可以通过下面的方法获取 PlusButton 的点击状态：
Use the following method to inspect the PlusButton selection state:

```Objective-C
+ (BOOL)shouldSelectPlusChildViewController;
```

用法如下：
Usage:


```Objective-C
+ (BOOL)shouldSelectPlusChildViewController {
    BOOL isSelected = CYLExternPlusButton.selected;
    if (isSelected) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is selected");
    } else {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"PlusButton is not selected");
    }
    return YES;
}

```

### [CN]让 TabBarItem 仅显示图标并使图标垂直居中
### [EN]Display only icons in TabBarItems and center them vertically

要实现该效果，只需在 `tabBarItemsAttributes` 中省略 `title`。
To enable this behavior, omit `title` from `tabBarItemsAttributes`.

例如，在 Demo 中注释掉下图红框部分：
For example, comment out the highlighted code in the demo:

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6urbcuckkj30ly0erdil.jpg"></a></p>


注释前 / Before | 注释后 / After
-------------|-------------
![https://github.com/ChenYilong](https://tva1.sinaimg.cn/large/006y8mN6ly1g6urbvymxij30yi05g74r.jpg)|![https://github.com/ChenYilong](https://tva1.sinaimg.cn/large/006y8mN6ly1g6urc80bdoj30yi05iq3b.jpg)

这样即可实现 Airbnb app 风格：
This produces an Airbnb-style layout:

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6gy1g92nir57tmg308w0fsapi.gif"></a></p>


如需手动设置偏移量，可在 `-setViewControllers:` 前设置 `imageInsets` 和 `titlePositionAdjustment`。
To adjust the offset manually, set `imageInsets` and `titlePositionAdjustment` before `-setViewControllers:`.

注意：这两个属性会应用于所有 TabBarItem，并优先于自动居中逻辑。
These properties apply to every TabBarItem and take precedence over the automatic centering logic.

Demo 中已提供完整示例。
See the demo for a complete example.

要实现完整的 Airbnb app 效果，还需要设置 `CYLTabBarController` 的 `tabBarHeight`。
可在 Demo 的 `CYLTabBarControllerConfig.m` 的 `-customizeTabBarAppearance:` 中设置。

For the complete Airbnb-style layout, also customize `tabBarHeight` in
`-customizeTabBarAppearance:` from `CYLTabBarControllerConfig.m`.

注：这里的“图标”属于系统私有类 `UITabBarSwappableImageView`，因此相关接口名称包含 `SwappableImageView`。
使用该特性需要将依赖更新到 1.5.5 或更高版本。

Note: the icon is backed by the private system class `UITabBarSwappableImageView`, which explains
the `SwappableImageView` naming. This feature requires version 1.5.5 or later.


### [CN]多 TabBar 嵌套并指定 PlusButton 位置
### [EN]Nesting multiple TabBars and specifying the PlusButton position

旧版本可能不支持此功能，建议使用最新版本。
Older versions may not support this feature; use the latest release.

效果图 / Preview:

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://ws4.sinaimg.cn/large/006tNc79ly1fmn3005isfg308r0iltl6.gif"></a></p>



实现以下协议方法，为 PlusButton 指定 context：
Implement the following protocol method to assign a context:

 ```Objective-C
//CYLPlusButtonSubclassing
+ (NSString *)tabBarContext;

 ```

当 PlusButton 的 context 与 TabBarController 的 context 匹配时，PlusButton 才会展示。
如果两者都未设置 context，则默认视为匹配。

The PlusButton is shown when its context matches the TabBarController context.
If neither value is set, they are considered equal by default.

当前每次只展示一个 PlusButton，不限嵌套层级；如果匹配多个 TabBarController，则展示在第一个匹配的控制器上。
Only one PlusButton is displayed at a time, regardless of nesting depth. If multiple controllers match, it is shown on the first match.



### [CN]在 Swift 项目中使用 CYLTabBarController
### [EN]Using CYLTabBarController in a Swift project

| 中文 | English |
|:---|:---|
| 仓库提供了 Swift Demo，目录为 `Example-Swift`。 | The repository includes a Swift demo in `Example-Swift`. |

| 中文 | English |
|:---|:---|
| 在 Swift 项目中作为静态库使用： | To use the library as a static library in a Swift project: |

| 中文 | English |
|:---|:---|
| CocoaPods 1.5.0+ (with Xcode 9+)： | CocoaPods 1.5.0+ (with Xcode 9+): |

 ```Objective-C
 platform :ios, '8.0'
# Uncomment the next line when you want all Pods as static framework
# use_modular_headers!
pod 'CYLTabBarController', '~> 1.29.0', :modular_headers => true
 ```

| 中文 | English |
|:---|:---|
| 作为动态库使用： | To use it as a dynamic framework: |

 ```Objective-C
platform :ios, '8.0'
use_frameworks!
 ```

| 中文 | English |
|:---|:---|
| 感谢 [@WeMadeCode](https://github.com/WeMadeCode) 提供 Swift Demo，原仓库：[WeMadeCode/CYLTabBarController-Swift](https://github.com/WeMadeCode/CYLTabBarController-Swift)。 | Thanks to [@WeMadeCode](https://github.com/WeMadeCode) for the Swift demo. Original repository: [WeMadeCode/CYLTabBarController-Swift](https://github.com/WeMadeCode/CYLTabBarController-Swift). |

| 中文 | English |
|:---|:---|
| 具体步骤可参考教程：[从头开始 Swift 2.1：主流 Tabbed 框架搭建](http://www.jianshu.com/p/c5bc2eae0f55?nomobile=yes)。 | For step-by-step instructions, see [Building a mainstream Tabbed framework with Swift 2.1](http://www.jianshu.com/p/c5bc2eae0f55?nomobile=yes). |

| 中文 | English |
|:---|:---|
| 注意：教程早期版本的示例缺少 PlusButton 尺寸设置，可能导致点击事件失效。当前教程已更新。 | Note: an early version of the tutorial omitted the PlusButton size, which could disable taps. The tutorial has since been updated. |

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6ur43ri5uj30ko0jmdjc.jpg"></a></p>

### [CN]搭配 Storyboard 使用 CYLTabBarController
### [EN]Using CYLTabBarController with Storyboard

| 中文 | English |
|:---|:---|
| 参考： | References: |

| 中文 | English |
|:---|:---|
| [Issue 讨论](https://github.com/ChenYilong/CYLTabBarController/issues/170) | [Issue discussion](https://github.com/ChenYilong/CYLTabBarController/issues/170) |
| [CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor) 中的 `CYLTabBarControllerTestDemo` 演示了如何与 Storyboard 配合使用。 | The `CYLTabBarControllerTestDemo` directory demonstrates Storyboard integration. |

### [CN]源码实现原理
### [EN]Implementation details

| 中文 | English |
|:---|:---|
| 参考：[《[Note] CYLTabBarController》](http://www.jianshu.com/p/8758d8014f86) | See [Note: CYLTabBarController](http://www.jianshu.com/p/8758d8014f86). |

| 中文 | English |
|:---|:---|
| 更多文档请查看 [CocoaDocs: CYLTabBarController](http://cocoadocs.org/docsets/CYLTabBarController/1.2.1/index.html)。 | For additional documentation, see [CocoaDocs: CYLTabBarController](http://cocoadocs.org/docsets/CYLTabBarController/1.2.1/index.html). |

## [CN]常见问题
## [EN]FAQ

| 中文 | English |
|:---|:---|
| 更多问答请查看 [Issue FAQ](https://github.com/ChenYilong/CYLTabBarController/issues?utf8=✓&q=+label%3AQ-A+)。 | For more questions and answers, see the [Issue FAQ](https://github.com/ChenYilong/CYLTabBarController/issues?utf8=✓&q=+label%3AQ-A+). |

### [CN]为什么放置 6 个 TabBarItem 会显示异常？
### [EN]Why does placing six TabBarItems behave unexpectedly?

| 中文 | English |
|:---|:---|
| Apple 规定，一个 `TabBar` 最多显示 5 个 `TabBarItem`，第六个及之后的项目不会显示。 | Apple allows a maximum of five `TabBarItem` instances in a `TabBar`; additional items are hidden. |

| 中文 | English |
|:---|:---|
| Apple 检测的是 `UITabBarItem` 及其子类。由于 PlusButton 是 `UIButton`，它不计入这五个项目。 | Because PlusButton is a `UIButton`, it is not counted as one of those five items. |

| 中文 | English |
|:---|:---|
| 因此，一个 TabBar 最多可以放置 5 个 TabBarItem 和 1 个 PlusButton。 | The practical limit is therefore five TabBarItems plus one PlusButton. |

### [CN]按钮响应区域发生偏移
### [EN]The button hit area is offset

| 中文 | English |
|:---|:---|
| 我把 Demo 两侧的 item 各去掉一个后，按钮的响应区域变成了下图的样子： | After removing one item from each side of the demo, the button hit area looked like this: |

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://cloud.githubusercontent.com/assets/12152553/10725491/62600172-7c07-11e5-9e0a-0ec7d795d1e3.jpeg"></a></p>

| 中文 | English |
|:---|:---|
| v1.5.5 已修复该问题，不会再出现点击区域无响应或响应区域偏移。 | This was fixed in v1.5.5; the hit area should no longer be offset. |

### [CN]如何添加选中背景色？
### [EN]How can I add a selected background color?

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://cloud.githubusercontent.com/assets/7238866/10777333/5d7811c8-7d55-11e5-88be-8cb11bbeaf90.png"></a></p>

| 中文 | English |
|:---|:---|
| Demo 中已提供实现代码，详见 `CYLTabBarControllerConfig` 的以下方法： | The demo includes an implementation in `CYLTabBarControllerConfig`: |

 ```Objective-C
/**
 *  更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性
 */
- (void)customizeTabBarAppearance:(CYLTabBarController *)tabBarController;

 ```

| 中文 | English |
|:---|:---|
| 效果如下： | The result is shown below: |

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://cloud.githubusercontent.com/assets/2911921/10779397/34956b0a-7d6b-11e5-82d9-fa75aa34e8d0.png"></a></p>

### [CN]ViewController 标题与 TabBar 标题不一致
### [EN]The ViewController title does not match the TabBar title

| 中文 | English |
|:---|:---|
| 当 `ViewController` 的 `self.title` 与 `tabBarItemsAttributes` 中的 `title` 不一致时，可能导致排序异常。 | If `self.title` differs from the corresponding `tabBarItemsAttributes` title, the order may appear incorrect. |

| 中文 | English |
|:---|:---|
| v1.0.7 已修复相关 bug，但仍建议不要使用 `self.title` 设置导航栏标题。 | This bug was fixed in v1.0.7, but do not use `self.title` to set the navigation bar title. |

| 中文 | English |
|:---|:---|
| 请使用 `self.navigationItem.title = @"同城";`： | Use `self.navigationItem.title = @"同城";`: |

| 中文 | English |
|:---|:---|
| `self.title = @"同城";  ` 这种方式，如果和 `tabBarItemsAttributes` 中对应的 `title` 不一致的时候可能会导致如下现象（不算 bug，但看起来也很奇怪）： | If `self.title = @"同城";` differs from the corresponding `tabBarItemsAttributes` title, the following strange-looking behavior may occur (this is not technically a bug): |

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6ur9yhnqej30ac01pq2z.jpg"></a></p>

| 中文 | English |
|:---|:---|
| 推荐规则如下： | Recommended usage: |

 ```Objective-C

    self.navigationItem.title = @"同城";    //✅sets navigation bar title.The right way to set the title of the navigation
    self.tabBarItem.title = @"同城";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in  tabbar.
    self.title = @"同城1";                  //❌sets both of these. Do not do this‼️‼️ This may cause something strange like this : http://i68.tinypic.com/282l3x4.jpg

 ```

### [CN]调用 `cyl_popSelectTabBarChildViewControllerAtIndex:` 时出现黑边
### [EN]Black borders appear when calling `cyl_popSelectTabBarChildViewControllerAtIndex:`

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6ur5d01x6j30af0ijmy6.jpg"></a></p>

| 中文 | English |
|:---|:---|
| 这是早期 iOS 系统的问题，测试表明 iOS 9.3 已修复。 | This was an issue on older iOS versions; testing shows that it was fixed in iOS 9.3. |
| 在受影响的旧版本上，可以将根窗口背景色设置为白色： | On affected older iOS versions, set the root window background color to white: |

 ```Objective-C
//#import "CYLTabBarController.h"
    [[self cyl_tabBarController] rootWindow].backgroundColor = [UIColor whiteColor];
 ```
### [CN]凸起的图标超出 49pt 后无法响应
### [EN]A raised icon does not respond above 49pt

| 中文 | English |
|:---|:---|
| 库会自动处理，但只能保证 `UIButton` frame 内的区域可以响应。 | The library handles this automatically, but only the `UIButton` frame is guaranteed to receive taps. |

| 中文 | English |
|:---|:---|
| 请给 button 设置明显的背景色以确认实际 frame。红色区域可以响应，超出 button frame 的图片区域不能响应。 | Use a visible background color to inspect the button frame. The button area receives taps; image pixels outside the frame do not. |

<p align="center"><a href="https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw"><img src="https://tva1.sinaimg.cn/large/006y8mN6ly1g6ur67tddnj30yi0c6abk.jpg"></a></p>

| 中文 | English |
|:---|:---|
| 这是因为响应链中的 `UIControl` 可以响应点击，而 `UIImage` 不能。 | This is because `UIControl` participates in hit testing, while `UIImage` does not. |

### [CN]为什么 iOS 10 会崩溃而 iOS 9 不会？
### [EN]Why does it crash on iOS 10 but not iOS 9?

| 中文 | English |
|:---|:---|
| 注册 PlusButton 时，必须在 `-application:didFinishLaunchingWithOptions:` 中调用 `[YourClass registerPlusButton]`。 | Register the PlusButton by calling `[YourClass registerPlusButton]` from `-application:didFinishLaunchingWithOptions:`. |

| 中文 | English |
|:---|:---|
| 不要在子类的 `+load` 方法中调用，否则在 iOS 10 上可能崩溃。 | Do not call it from the subclass `+load` method, as this may crash on iOS 10. |

 ```Objective-C
 + (void)load {
    [super registerPlusButton];
}
 ```

### [CN]PlusButton 选中后无法恢复为 normal
### [EN]PlusButton remains selected after selecting another tab

| 中文 | English |
|:---|:---|
| 通常有两种原因： | There are two common causes: |

| 中文 | English |
|:---|:---|
| `tabBar` 设置了自定义 delegate，覆盖了默认状态切换逻辑。请在 delegate 中手动同步状态。 | A custom `tabBar` delegate may override the default selection handling. Synchronize the state manually: |

 ```Objective-C
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    return YES;
}
 ```

| 中文 | English |
|:---|:---|
| PlusButton 添加了自定义点击事件或手势，与库内置逻辑冲突。请移除自定义 `addTarget` 或手势。 | A custom action or gesture may conflict with the library. Remove the custom `addTarget` or gesture. |

### [CN]PlusButton 与其他 TabBarItem 的间距不均匀
### [EN]The PlusButton is not evenly spaced

| 中文 | English |
|:---|:---|
| 对应 [issue #36](https://github.com/ChenYilong/CYLTabBarController/issues/36#issuecomment-269165471)。 | See [issue #36](https://github.com/ChenYilong/CYLTabBarController/issues/36#issuecomment-269165471). |

| 中文 | English |
|:---|:---|
| 将 Demo 中的： | Replace this in the demo: |

 ```Objective-C
[button sizeToFit];
 ```

| 中文 | English |
|:---|:---|
| 改为： | Replace it with: |

 ```Objective-C
button.frame = CGRectMake(0.0, 0.0, w, h);
 ```

| 中文 | English |
|:---|:---|
| 如果只放置一个相机图标，尺寸应以设计稿为准。 | For a camera-only icon, use the size specified by your design. |

| 中文 | English |
|:---|:---|
| 通常可以使用与其他 TabBarItem 相同的宽度： | In most cases, use the same width as the other TabBarItems: |

 ```Objective-C
 [UIScreen mainScreen].bounds.size.width / [CYLTabBarController allItemsInTabBarCount]
 ```

### [CN]如何兼容 Lottie 动画？
### [EN]How do I integrate Lottie animations?

| 中文 | English |
|:---|:---|
| 用法请参考 [issue #341](https://github.com/ChenYilong/CYLTabBarController/issues/341)。 | See [issue #341](https://github.com/ChenYilong/CYLTabBarController/issues/341) for usage. |

## [CN]Star 历史
## [EN]Star history

<a href="https://star-history.dera.page/ChenYilong/CYLTabBarController">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://star-history.dera.page/svg?repos=ChenYilong/CYLTabBarController&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://star-history.dera.page/svg?repos=ChenYilong/CYLTabBarController" />
   <img alt="Star History Chart" src="https://star-history.dera.page/svg?repos=ChenYilong/CYLTabBarController" />
 </picture>
</a>

| 中文 | English |
|:---|:---|
| （更多 iOS 开发干货，欢迎关注 [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/)） | (For more iOS development tips, follow [@iOS程序犭袁 on Weibo](http://weibo.com/luohanchenyilong/).) |

--------------------------------------------

| 中文 | English |
|:---|:---|
| 发布者：[微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/) & [公众号@iTeaTime技术清谈](https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw) | Posted by [@iOS程序犭袁 on Weibo](http://weibo.com/luohanchenyilong/) & [@iTeaTime技术清谈 on WeChat](https://mp.weixin.qq.com/s/A4e5h3xgIEh6PInf1Rjqsw) |

| 中文 | English |
|:---|:---|
| 原创作品，版权声明：License MIT | Original work. Copyright license: MIT. |

<p align="center"><a href="http://weibo.com/u/1692391497?s=6uyXnP" target="_blank"><img border="0" src="http://service.t.sina.com.cn/widget/qmd/1692391497/b46c844b/1.png"/></a></p>
