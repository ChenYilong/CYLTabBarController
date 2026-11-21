#!/usr/bin/env python3
"""
CYLAnimatedItem x86_64 emulator helper (CYLTabBarController HarmonyOS, cylanimateditem/tools).

The x86_64 HarmonyOS emulator rejects a HAP that carries arm64-v8a-only native libraries (@ohos/rive libohos_rive.so,
@tencent/libpag libpag.so, and the libc++_shared.so next to them): "install parse native so failed", error 9568347.
Prefer the build profile's "emulator" target (cylanimateditem/README.md, "x86_64 emulator"); this tool is for a HAP
that was built without it, and for installing any HAP on the right device.

  python3 cyl_hap_x86_64.py strip  <in.hap> [<out.hap>]   copy the HAP without the native libraries the device cannot load
  python3 cyl_hap_x86_64.py install <app.hap> [--target 127.0.0.1:5557] [--hdc <path>] [--strip auto|yes|no]

"install" asks the device for its ABIs (hdc shell param get const.product.cpu.abilist); with --strip auto (default) it
strips libs/<abi>/ folders the device does not list, then runs hdc install -r. CYL_HAP_STRIP_LIBS=1 / 0 forces strip on /
off. Standard library only. The Rive and PAG items of the stripped app show their still images
(CYLAnimatedItemEngines.isSupportedOnDevice); their playback still needs an arm64 device.
"""
import os
import subprocess
import sys
import tempfile
import zipfile


def cyl_strip(source, target, keep_abis=None):
    """
    Copies source to target without libs/<abi>/ entries whose ABI is not in keep_abis (None or []: drop all native
    libraries). Returns the names that were left out.
    """
    dropped = []
    with zipfile.ZipFile(source) as zin, zipfile.ZipFile(target, 'w') as zout:
        for item in zin.infolist():
            parts = item.filename.split('/')
            if len(parts) > 2 and parts[0] == 'libs' and (not keep_abis or parts[1] not in keep_abis):
                dropped.append(item.filename)
                continue
            zout.writestr(item, zin.read(item.filename))
    return dropped


def cyl_hdc_default():
    """
    The hdc of DevEco Studio on Windows or macOS, else "hdc" from PATH.
    """
    for path in (r'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',
                 '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'):
        if os.path.exists(path):
            return path
    return 'hdc'


def cyl_device_abis(hdc, target):
    """
    The device's ABIs, e.g. ['x86_64'] on the emulator, ['arm64-v8a'] on a phone.
    """
    command = [hdc] + (['-t', target] if target else []) + ['shell', 'param', 'get', 'const.product.cpu.abilist']
    output = subprocess.run(command, capture_output=True, text=True).stdout.strip()
    return [abi.strip() for abi in output.split(',') if abi.strip()]


def cyl_hap_abis(path):
    """
    The ABIs a HAP carries native libraries for.
    """
    with zipfile.ZipFile(path) as hap:
        return sorted({name.split('/')[1] for name in hap.namelist() if name.startswith('libs/') and name.count('/') >= 2})


def main(argv):
    if len(argv) < 2 or argv[0] not in ('strip', 'install'):
        print(__doc__)
        return 2
    if argv[0] == 'strip':
        source = argv[1]
        target = argv[2] if len(argv) > 2 else source.replace('.hap', '-x86_64.hap')
        dropped = cyl_strip(source, target)
        print(f'{target}: left out {len(dropped)} native libraries')
        return 0
    args = argv[1:]
    hap, target, hdc, strip = args[0], '', cyl_hdc_default(), 'auto'
    for flag, value in zip(args[1::2], args[2::2]):
        if flag == '--target':
            target = value
        elif flag == '--hdc':
            hdc = value
        elif flag == '--strip':
            strip = value
    forced = os.environ.get('CYL_HAP_STRIP_LIBS')
    if forced in ('0', '1'):
        strip = 'yes' if forced == '1' else 'no'
    device = cyl_device_abis(hdc, target)
    carried = cyl_hap_abis(hap)
    missing = [abi for abi in carried if abi not in device]
    print(f'device ABIs: {", ".join(device) or "unknown"}; HAP native libraries: {", ".join(carried) or "none"}')
    install = hap
    if strip == 'yes' or (strip == 'auto' and missing and device):
        install = os.path.join(tempfile.mkdtemp(prefix='cyl-hap-'), os.path.basename(hap).replace('.hap', '-x86_64.hap'))
        dropped = cyl_strip(hap, install, keep_abis=device)
        print(f'left out {len(dropped)} native libraries the device cannot load: {install}')
    command = [hdc] + (['-t', target] if target else []) + ['install', '-r', install]
    result = subprocess.run(command, capture_output=True, text=True)
    print(result.stdout.strip() or result.stderr.strip())
    return 0 if 'successfully' in result.stdout else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
