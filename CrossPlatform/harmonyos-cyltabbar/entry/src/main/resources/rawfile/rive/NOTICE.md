# Rive sample files

| File | Source | License |
|:---|:---|:---|
| `icons.riv` | `Example-SwiftUI-Rive/AnimatedApp/RiveAssets/icons.riv` of this repository (the Design+Code course "SwiftUI Animations", Meng To) | No license file in the course download; copyright of the original author (see `Example-SwiftUI-Rive/README.md`, "Source and license") |
| `house.riv` | `Example-SwiftUI-Rive/AnimatedApp/RiveAssets/house.riv` of this repository (the same course) | The same as `icons.riv` |

An unchanged copy, used by the HarmonyOS example (`configurations/cyl_tabbar_configuration_rive.json`), as the iOS
(Example-Rive, Example-SwiftUI-Rive) and Android (Example-Android/example-rive) Rive demos use it. The file predates
Rive data binding, so the tabs drive the state machine input `active` (legacy runtime options).

`house.riv` (used by `configurations/cyl_tabbar_configuration_rive_house.json`) moves only when its state machine's NUMBER
input `Rooms` changes, so its tab sets the next of `values` on each play (`numberInput=Rooms&values=3,4,5,6`).
