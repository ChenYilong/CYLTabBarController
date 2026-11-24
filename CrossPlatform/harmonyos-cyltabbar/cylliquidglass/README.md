# cylliquidglass

Liquid Glass of CYLTabBarController for HarmonyOS NEXT as a base library: `CYLLiquidGlass.isActive()` (the availability rule, the
same name as iOS and Android) and `CYLLiquidGlassView`, a glass background for any component (`glassTintColor`, `cornerRadius`,
`isGlassDrawn`). It depends on no other package: `cyltabbar` depends on it. Until the system material is available (API 24 and
later, see docs/HarmonyOS-Liquid-Glass-Parity.md) the glass is a blur imitation, as in the tab bar.
Guide: [docs/Liquid-Glass-Component.md](../../../docs/Liquid-Glass-Component.md) in CYLTabBarController.
