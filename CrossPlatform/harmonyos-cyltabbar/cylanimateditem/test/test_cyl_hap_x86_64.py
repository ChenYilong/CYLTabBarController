"""
Unit tests of tools/cyl_hap_x86_64.py (strip and ABI listing). Run: python3 -m unittest discover -s
CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test -p "test_*.py"
"""
import os
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
import cyl_hap_x86_64 as cyl  # noqa: E402


class CYLHapX8664Tests(unittest.TestCase):
    def make_hap(self, folder):
        path = os.path.join(folder, 'entry.hap')
        with zipfile.ZipFile(path, 'w') as hap:
            hap.writestr('module.json', '{}')
            hap.writestr('ets/modules.abc', 'abc')
            hap.writestr('libs/arm64-v8a/libohos_rive.so', 'rive')
            hap.writestr('libs/arm64-v8a/libpag.so', 'pag')
            hap.writestr('libs/arm64-v8a/libc++_shared.so', 'cxx')
            hap.writestr('libs/x86_64/libown.so', 'own')
        return path

    def test_strip_keeps_only_the_device_abis(self):
        with tempfile.TemporaryDirectory() as folder:
            hap = self.make_hap(folder)
            self.assertEqual(cyl.cyl_hap_abis(hap), ['arm64-v8a', 'x86_64'])
            out = os.path.join(folder, 'out.hap')
            dropped = cyl.cyl_strip(hap, out, keep_abis=['x86_64'])
            self.assertEqual(len(dropped), 3, 'libc++_shared.so goes too: it alone still fails the install')
            with zipfile.ZipFile(out) as result:
                self.assertEqual(sorted(result.namelist()), ['ets/modules.abc', 'libs/x86_64/libown.so', 'module.json'])

    def test_strip_without_abis_drops_every_native_library(self):
        with tempfile.TemporaryDirectory() as folder:
            hap = self.make_hap(folder)
            out = os.path.join(folder, 'out.hap')
            cyl.cyl_strip(hap, out)
            self.assertEqual(cyl.cyl_hap_abis(out), [])


if __name__ == '__main__':
    unittest.main()
