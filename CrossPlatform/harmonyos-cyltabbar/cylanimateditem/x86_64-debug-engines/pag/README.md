# x86_64 debug engine kit: PAG (@tencent/libpag 4.4.31)

**Debug test kit for the x86_64 HarmonyOS emulator only.** Never part of a HAR, a release build or a published package:
`tools/cyl_hap_x86_64.py install` adds these files to a debug HAP when the device is x86_64, and `CYLAnimatedItemEngines`
adds it only to a HAP built with @tencent/libpag 4.4.31 (`kit.json`; for 4.5.102 see `../pag-4.5.102`), and `CYLAnimatedItemEngines` turns PAG on for x86_64 only in debug builds and only when that tool installed the kit (README "x86_64 emulator", Plan 1;
owner's rules in CYLTabBarController `instructions.md`, tag `windows-harmonyos`). Removing the debug guard needs the
owner's approval.

| File | What | SHA-256 |
|:---|:---|:---|
| `libpag.so` | @tencent/libpag 4.4.31 native library, built for x86_64 (release, stripped; the C++ runtime is linked statically, `-DOHOS_STL=c++_static`, so no `libc++_shared.so` is needed) | `261d2684711b4a8d5980438d4ec5bf73e3fc72e4bbaed991dacd68eebb50c6cf` |

## Provenance (built 2026-11-22 on Windows 11, DevEco Studio 6.0 SDK, HarmonyOS 6.0.1)

- Sources: GitHub `Tencent/libpag`, tag `v4.4.31` (commit `e517a994`), the version of the published `@tencent/libpag`
  4.4.31 HAR; its third-party sources synced by `depsync` from the tag's `DEPS` (tgfx `55e8b14b`, libavc `c2bf4c84`,
  harfbuzz `f1f2be77`, lz4 `5ff83968`, rttr `7edbd580`, vendor_tools `ce1f4d55`, and tgfx's own DEPS). License:
  `LICENSE-libpag.txt` (Apache License 2.0, with the notices of its third-party components).
- Build changes (local, not in the sources): `ohos/libpag/build-profile.json5` `abiFilters: ["x86_64"]`; the product on
  the HarmonyOS 6.0.1 SDK (`targetSdkVersion "6.0.1(21)"`). Command, in `ohos/`:
  `hvigorw --mode module -p module=libpag@default -p product=default -p buildMode=release assembleHar` (1 min 47 s); the file
  is `libpag/build/default/intermediates/stripped_native_libs/default/x86_64/libpag.so`.
- Checked: x86-64 ELF; it links only system libraries (GLESv3, EGL, image, media, native window, ace_napi, hilog, rawfile,
  libc); `types/libpag/Index.d.ts` identical to the official 4.4.31 HAR's; the same 15 N-API classes (`JPAGView`,
  `JPAGFile`, `JPAGPlayer`, …) as the official arm64 library.
