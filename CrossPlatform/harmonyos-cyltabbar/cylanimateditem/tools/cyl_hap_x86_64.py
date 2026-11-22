#!/usr/bin/env python3
"""
CYLAnimatedItem x86_64 emulator helper (CYLTabBarController HarmonyOS, cylanimateditem/tools).

The x86_64 HarmonyOS emulator rejects a HAP that carries arm64-v8a-only native libraries (@ohos/rive libohos_rive.so,
@tencent/libpag libpag.so, and the libc++_shared.so next to them): "install parse native so failed", error 9568347.
Prefer the build profile's "emulator" target (cylanimateditem/README.md, "x86_64 emulator"); this tool is for a HAP
that was built without it, and for installing any HAP on the right device.

  python3 cyl_hap_x86_64.py strip  <in.hap> [<out.hap>]   copy the HAP without the native libraries the device cannot load
  python3 cyl_hap_x86_64.py install <app.hap> [--target 127.0.0.1:5557] [--hdc <path>] [--strip auto|yes|no]
                                     [--x86-engines auto|yes|no]

"install" asks the device for its ABIs (hdc shell param get const.product.cpu.abilist); with --strip auto (default) it
strips libs/<abi>/ folders the device does not list, then runs hdc install -r. CYL_HAP_STRIP_LIBS=1 / 0 forces strip on /
off. With --x86-engines auto (default) on an x86_64 device, it also adds the x86_64 debug engine kit
(../x86_64-debug-engines/rive: libohos_rive.so of @ohos/rive 1.0.4, libc++_shared.so) and the marker rawfile
cyl_x86_64_debug_engines.json, so Rive plays in DEBUG builds (CYLAnimatedItemEngines reads the marker); CYL_X86_ENGINES=1 / 0
forces it. Standard library only. The Rive and PAG items of the stripped app show their still images
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


def cyl_local_path(path):
    """
    An absolute path in the platform's own form. On Windows hdc reads "C:/Users/..." as a relative path ("Error opening
    file ...\\C:/Users/..."), so it needs backslashes (reported by the CYLTableViewPlaceHolder session, 2026-11-22).
    """
    return os.path.abspath(os.path.normpath(path))


CYL_KIT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'x86_64-debug-engines')
CYL_MARKER = 'resources/rawfile/cyl_x86_64_debug_engines.json'


def cyl_add_debug_engines(source, target, kit_dir=CYL_KIT_DIR):
    """
    Copies source to target with the x86_64 debug engine kit added: libs/x86_64/<library> for each engine folder of kit_dir
    (stored, not compressed) and the marker rawfile that names the engines. Returns the engine names added.
    """
    engines, files = [], {}
    for name in sorted(os.listdir(kit_dir)) if os.path.isdir(kit_dir) else []:
        folder = os.path.join(kit_dir, name)
        libraries = [f for f in sorted(os.listdir(folder)) if f.endswith('.so')] if os.path.isdir(folder) else []
        if libraries:
            engines.append({'rive': 'Rive', 'pag': 'PAG'}.get(name, name))
            for library in libraries:
                files['libs/x86_64/' + library] = os.path.join(folder, library)
    with zipfile.ZipFile(source) as zin, zipfile.ZipFile(target, 'w') as zout:
        present = set(zin.namelist())
        for item in zin.infolist():
            if item.filename != CYL_MARKER:
                zout.writestr(item, zin.read(item.filename))
        for name, path in files.items():
            if name not in present:
                zout.write(path, name, compress_type=zipfile.ZIP_STORED)
        if engines:
            zout.writestr(CYL_MARKER, '{"engines": %s, "kit": "cylanimateditem/x86_64-debug-engines"}' % str(engines).replace("'", '"'))
    return engines


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
        source = cyl_local_path(argv[1])
        target = cyl_local_path(argv[2]) if len(argv) > 2 else source.replace('.hap', '-x86_64.hap')
        dropped = cyl_strip(source, target)
        print(f'{target}: left out {len(dropped)} native libraries')
        return 0
    args = argv[1:]
    hap, target, hdc, strip, engines = cyl_local_path(args[0]), '', cyl_hdc_default(), 'auto', 'auto'
    for flag, value in zip(args[1::2], args[2::2]):
        if flag == '--target':
            target = value
        elif flag == '--hdc':
            hdc = value
        elif flag == '--strip':
            strip = value
        elif flag == '--x86-engines':
            engines = value
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
    forced_engines = os.environ.get('CYL_X86_ENGINES')
    if forced_engines in ('0', '1'):
        engines = 'yes' if forced_engines == '1' else 'no'
    if engines == 'yes' or (engines == 'auto' and 'x86_64' in device):
        with_engines = os.path.join(tempfile.mkdtemp(prefix='cyl-hap-'), os.path.basename(install).replace('.hap', '-engines.hap'))
        added = cyl_add_debug_engines(install, with_engines)
        print(f'x86_64 debug engine kit: {", ".join(added) or "none"} ({with_engines})')
        install = with_engines
    command = [hdc] + (['-t', target] if target else []) + ['install', '-r', cyl_local_path(install)]
    result = subprocess.run(command, capture_output=True, text=True)
    print(result.stdout.strip() or result.stderr.strip())
    return 0 if 'successfully' in result.stdout else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
