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

    def test_local_path_is_absolute_in_the_platform_form(self):
        path = cyl.cyl_local_path('some/dir/../entry.hap')
        self.assertTrue(os.path.isabs(path))
        self.assertTrue(path.endswith(os.path.join('some', 'entry.hap')))
        if os.sep == '\\':
            self.assertNotIn('/', cyl.cyl_local_path('C:/Users/x/entry.hap'))

    def test_debug_engine_kit_adds_the_x86_64_libraries_and_the_marker(self):
        with tempfile.TemporaryDirectory() as folder:
            hap = self.make_hap(folder)
            stripped = os.path.join(folder, 'stripped.hap')
            cyl.cyl_strip(hap, stripped, keep_abis=['x86_64'])
            kit = os.path.join(folder, 'kit', 'rive')
            os.makedirs(kit)
            for name in ('libohos_rive.so', 'libc++_shared.so', 'README.md'):
                with open(os.path.join(kit, name), 'w') as handle:
                    handle.write(name)
            out = os.path.join(folder, 'out.hap')
            self.assertEqual(cyl.cyl_add_debug_engines(stripped, out, os.path.join(folder, 'kit')), ['Rive'])
            with zipfile.ZipFile(out) as result:
                names = result.namelist()
                self.assertIn('libs/x86_64/libohos_rive.so', names)
                self.assertIn('libs/x86_64/libc++_shared.so', names)
                self.assertNotIn('libs/x86_64/README.md', names)
                self.assertEqual(result.getinfo('libs/x86_64/libohos_rive.so').compress_type, zipfile.ZIP_STORED)
                self.assertIn('"Rive"', result.read(cyl.CYL_MARKER).decode())

    def test_the_real_kit_holds_the_x86_64_rive_library(self):
        rive = os.path.join(cyl.CYL_KIT_DIR, 'rive')
        self.assertTrue(os.path.isfile(os.path.join(rive, 'libohos_rive.so')))
        self.assertTrue(os.path.isfile(os.path.join(rive, 'libc++_shared.so')))

    def test_the_real_kit_holds_the_x86_64_pag_library(self):
        self.assertTrue(os.path.isfile(os.path.join(cyl.CYL_KIT_DIR, 'pag', 'libpag.so')))

    def test_only_the_engines_the_app_ships_are_added(self):
        with tempfile.TemporaryDirectory() as folder:
            kit = os.path.join(folder, 'kit')
            for engine, libraries in (('rive', ('libohos_rive.so', 'libc++_shared.so')), ('pag', ('libpag.so',))):
                os.makedirs(os.path.join(kit, engine))
                for name in libraries:
                    with open(os.path.join(kit, engine, name), 'w') as handle:
                        handle.write(name)
            app = os.path.join(folder, 'rive-only.hap')
            with zipfile.ZipFile(app, 'w') as hap:
                hap.writestr('module.json', '{}')
                hap.writestr('libs/arm64-v8a/libohos_rive.so', 'rive')
                hap.writestr('libs/arm64-v8a/libc++_shared.so', 'cxx')
            out = os.path.join(folder, 'out.hap')
            self.assertEqual(cyl.cyl_add_debug_engines(app, out, kit, shipped=cyl.cyl_hap_libraries(app)), ['Rive'])
            with zipfile.ZipFile(out) as result:
                self.assertNotIn('libs/x86_64/libpag.so', result.namelist())
            self.assertEqual(cyl.cyl_add_debug_engines(app, out, kit, shipped=set()), [])
            # [EN] A HAP of the "emulator" target carries no arm64 file; its ArkTS still imports the module.
            emulator = os.path.join(folder, 'emulator.hap')
            with zipfile.ZipFile(emulator, 'w') as hap:
                hap.writestr('ets/modules.abc', b'\x00@normalized:Y&&&libohos_rive.so&\x00')
            self.assertEqual(cyl.cyl_hap_libraries(emulator), {'libohos_rive.so'})
            self.assertEqual(cyl.cyl_add_debug_engines(emulator, out, kit, shipped=cyl.cyl_hap_libraries(emulator)), ['Rive'])
            self.assertEqual(cyl.cyl_add_debug_engines(self.make_hap(folder), out, kit,
                                                       shipped=cyl.cyl_hap_libraries(self.make_hap(folder))), ['PAG', 'Rive'])

    def test_strip_without_abis_drops_every_native_library(self):
        with tempfile.TemporaryDirectory() as folder:
            hap = self.make_hap(folder)
            out = os.path.join(folder, 'out.hap')
            cyl.cyl_strip(hap, out)
            self.assertEqual(cyl.cyl_hap_abis(out), [])


if __name__ == '__main__':
    unittest.main()
