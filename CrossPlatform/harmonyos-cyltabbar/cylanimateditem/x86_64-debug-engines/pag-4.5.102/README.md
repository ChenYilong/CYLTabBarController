# x86_64 debug engine kit: PAG (@tencent/libpag 4.5.102)

**Debug test kit for the x86_64 HarmonyOS emulator only**, like [../pag](../pag/README.md) (4.4.31): never part of a HAR, a
release build or a published package. `tools/cyl_hap_x86_64.py install` adds it only to a HAP whose ArkTS was built with
@tencent/libpag 4.5.102 (`kit.json`; a native library of another version crashes the app's ArkTS layer). The debug-build
guard was removed with the owner's approval (2026-11-23).

| File | What | SHA-256 |
|:---|:---|:---|
| `libpag.so` | @tencent/libpag 4.5.102 native library, built for x86_64 (release, stripped, C++ runtime static) | `c22736a144cd370f39470caa153a2a6864bbb6b7b3271809893e309ce4e0b1c6` |

## Provenance (built 2026-11-22 on Windows 11, DevEco Studio 6.0 SDK)

- Sources: GitHub `Tencent/libpag`, tag `v4.5.102` (commit `1ff5275`), third-party sources by `depsync` from the tag's
  `DEPS`. License: `LICENSE-libpag.txt` (Apache License 2.0, with the notices of its third-party components).
- Build changes (local): `ohos/libpag/build-profile.json5` `abiFilters: ["x86_64"]` (the tag's product already targets the
  HarmonyOS SDK 6.0.0(20)). Command, in `ohos/`: `hvigorw --mode module -p module=libpag@default -p product=default
  -p buildMode=release assembleHar` (2 min 15 s).
- Checked: x86-64 ELF; `types/libpag/Index.d.ts` matches the official 4.5.102 HAR's (whose parameter names are
  obfuscated) except `JPAG.SetDataReportEnabled` / `JPAG.DataReportEnabled`, which the published HAR has and the
  open-source tag does not: an app that calls `PAG.SetDataReportEnabled` / `PAG.DataReportEnabled` would fail on x86_64
  with this kit (no example does).
