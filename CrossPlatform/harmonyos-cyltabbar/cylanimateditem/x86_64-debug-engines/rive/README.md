# x86_64 debug engine kit: Rive (@ohos/rive 1.0.4)

**Debug test kit for the x86_64 HarmonyOS emulator only.** Never part of a HAR, a release build or a published package:
`tools/cyl_hap_x86_64.py install` adds these files to a debug HAP when the device is x86_64, and `CYLAnimatedItemEngines`
turns Rive on for x86_64 only in debug builds and only when that tool installed the kit (README "x86_64 emulator", Plan 1;
owner's rules in CYLTabBarController `instructions.md`, tag `windows-harmonyos`). Removing the debug guard needs the
owner's approval.

| File | What | SHA-256 |
|:---|:---|:---|
| `libohos_rive.so` | @ohos/rive 1.0.4 native library, built for x86_64 (release) | `5bc47b425b1fccdcf9f3cffe73744c21e6ca1bb0babd2a5d688a2a3f07f45fcf` |
| `libc++_shared.so` | the LLVM C++ runtime of the HarmonyOS NDK for x86_64, which `libohos_rive.so` links | `ee341fc205c7a289e4783878127f61199b58d31bb7ba143be221984c8a51fb48` |

## Provenance (built 2026-11-22 on Windows 11, DevEco Studio 6.0 SDK, HarmonyOS 6.0.1)

- Wrapper: GitCode `openharmony-tpc/openharmony_tpc_samples`, commit `4b1609b2` ("update CHANGELOG to 1.0.4"),
  folder `ohos_rive` (`library/oh-package.json5` version 1.0.4). License: `LICENSE-ohos_rive.txt` (MIT License /  / Copyright (c) 2020-2024 Rive).
- Engine: submodule `ohos_rive/submodules/rive-runtime`, commit `f27a90050386b5428589bddb9a4ce5e248e0e8b3` from
  `https://gitee.com/yp9522/rive-runtime.git` (the HarmonyOS fork of GitHub `rive-app/rive-runtime`; this commit is not in
  the GitHub repository, so 1.0.4 can only be rebuilt from the fork). License: `LICENSE-rive-runtime.txt` (MIT).
- `ohos_rive/library/src/main/cpp/boundscheck/third_party_bounds_checking_function`: commit `2ae82839` (gitee
  `openharmony/third_party_bounds_checking_function`).
- Build changes (local, not in the sources): `library/build-profile.json5` `abiFilters: ["x86_64"]`; the product on the
  HarmonyOS 6.0.1 SDK (`targetSdkVersion "6.0.1(21)"`, `compatibleSdkVersion "5.0.0(12)"`, `runtimeOS "HarmonyOS"`);
  `OHOS_NDK` through a junction without spaces to the SDK's `native` folder; MSYS2 (ninja, make, python-ply) and premake
  5.0.0-beta2 (GitHub premake/premake-core) on PATH. Command:
  `hvigorw --mode module -p module=rive_ohos@default -p product=default -p buildMode=release assembleHar`; the files are
  `library/build/default/intermediates/stripped_native_libs/default/x86_64/`.
- Checked: x86-64 ELF; `types/libohos_rive/Index.d.ts` identical to the official 1.0.4; 6846 exported symbols against
  6848 in the official arm64 library, the 9 that differ are text and layout internals (SheenBidi, Yoga), none N-API.
