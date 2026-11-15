# harmonyos-cyltabbar

| 中文 | English |
|:---|:---|
| 鸿蒙版 CYLTabBarController（ArkTS / ArkUI）：`cyltabbar` 库（HAR）与示例 `entry`（HAP，复刻 Objective-C Example）。进度与打分见 [docs/HarmonyOS-Parity.md](../../docs/HarmonyOS-Parity.md)。 | CYLTabBarController for HarmonyOS (ArkTS / ArkUI): the `cyltabbar` library (HAR) and the example `entry` (HAP, a replica of the Objective-C Example). Progress and score: [docs/HarmonyOS-Parity.md](../../docs/HarmonyOS-Parity.md). |
| 系统版本：HarmonyOS 6.0.1（API 21），DevEco Studio 6.0。 | Version: HarmonyOS 6.0.1 (API 21), DevEco Studio 6.0. |
| 构建：用 DevEco Studio 打开本目录。hvigor 不接受含空格或非 ASCII 字符的路径，因此请把项目复制到 `C:\cyl-hm` 之类的路径后再运行 `hvigorw assembleHap`。 | Build: open this folder in DevEco Studio. hvigor refuses paths with spaces or non-ASCII characters, so copy the project to a path such as `C:\cyl-hm` before running `hvigorw assembleHap`. |
| 运行：DevEco Studio → Device Manager 安装 HarmonyOS 6.0.1 手机模拟器（需华为账号登录），或连接真机，并在 File → Project Structure → Signing Configs 中自动签名。 | Run: install a HarmonyOS 6.0.1 phone emulator in DevEco Studio → Device Manager (a Huawei account sign-in is needed) or connect a phone, then use automatic signing in File → Project Structure → Signing Configs. |

```ts
import { CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton } from 'cyltabbar';

CYLTabBarController({
  tabBarItemsAttributes: tabs,          // CYLTabBarControllerTabBarItemsAttributes
  plusButton: plus,                     // CYLTabBarControllerPlusButton
  selectedIndex: $selectedIndex,
  plusButtonAction: () => {},           // CYLTabBarControllerPlusButtonAction
  pageBuilder: (index: number, identifier: string) => { this.page(index, identifier) },
})
```
