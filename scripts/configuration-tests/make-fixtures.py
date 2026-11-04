#!/usr/bin/env python3
"""Writes the edge-case files of the configuration parser and the result each one must give.

[EN] Called by run-tests.sh. Writes every file into the given folder, with manifest.json: for each file, the expected
     result, either "dictionary" (it parses) or an error code of CYLTabBarConfigurationErrorDomain (see
     CYLTabBarConfigurationParser.h), and optionally the JSON file whose dictionary it must be equal to. The case IDs are
     those of docs/Configuration-File.md ("Edge cases and score"). Python 3 standard library only.
[CN] 由 run-tests.sh 调用。把所有文件写入指定目录，并写出 manifest.json：每个文件的预期结果，"dictionary"（能解析）或
     CYLTabBarConfigurationErrorDomain 的错误码（见 CYLTabBarConfigurationParser.h），以及可选的、其字典必须相等的 JSON 文件。情况编号与
     docs/Configuration-File.md（“边界情况与评分”）一致。仅使用 Python 3 标准库。
"""
import json
import os
import plistlib
import sys

INVALID_SYNTAX, NOT_A_DICTIONARY, EMPTY, TOO_LARGE, TOO_DEEP = 3, 4, 6, 7, 8
N = 100000  # nesting levels of the hostile files 恶意文件的嵌套层数


def varint(n):
    out = bytearray()
    while True:
        b, n = n & 0x7F, n >> 7
        out.append(b | (0x80 if n else 0))
        if not n:
            return bytes(out)


def field(number, payload):
    return varint(number << 3 | 2) + varint(len(payload)) + payload


def main(folder):
    os.makedirs(folder, exist_ok=True)
    cases = []

    def add(name, data, expect, case, equals=None, values=None):
        """`values`: key path (dots, numbers for list elements) -> expected JSON value. 键路径 -> 预期的 JSON 值。"""
        with open(os.path.join(folder, name), 'wb') as f:
            f.write(data if isinstance(data, bytes) else data.encode('utf-8'))
        cases.append({'file': name, 'expect': expect, 'case': case, 'equals': equals, 'values': values or {}})

    # The reference: a small valid configuration with Chinese text and a map. 参照：含中文与 map 的有效配置。
    reference = {
        'CYLTabBarControllerContext': '首页 ✓',
        'CYLTabBarControllerStyleType': 'liquidGlass',
        'CYLTabBarControllerTabBarItemsAttributes': [{
            'CYLTabBarItemTitle': '消息',
            'CYLTabBarItemImage': 'system:message',
            'CYLTabBarLottieDarkColors': {'Icon.**.Color': '#C8C8C8', 'Main.**.Color': '#266428'},
        }],
    }
    add('reference.json', json.dumps(reference, ensure_ascii=False), 'dictionary', 'reference')

    # A10: nesting. 嵌套。
    add('deep.json', '{"a": ' + '[' * N + ']' * N + '}', TOO_DEEP, 'A10')
    add('deep.json5', '{a: ' + '[' * N + ']' * N + '}', TOO_DEEP, 'A10')
    add('deep_flow.yaml', 'a: ' + '[' * N + ']' * N + '\n', TOO_DEEP, 'A10')
    add('deep_block.yaml', ''.join(' ' * i + 'k%d:\n' % i for i in range(3000)) + ' ' * 3000 + 'v: 1\n', TOO_DEEP, 'A10')
    add('deep.toml', 'a = ' + '[' * N + ']' * N + '\n', TOO_DEEP, 'A10')
    add('deep.textproto', 'a ' + '{ b ' * N + '}' * N + '\n', TOO_DEEP, 'A10')
    add('deep.xml', '<r>' + '<a>' * N + '</a>' * N + '</r>', TOO_DEEP, 'A10')
    add('deep_xml.plist', '<?xml version="1.0"?><plist><dict><key>a</key>' + '<array>' * N + '</array>' * N + '</dict></plist>', TOO_DEEP, 'A10')
    add('deep_openstep.plist', '{ a = ' + '(' * N + ')' * N + '; }', TOO_DEEP, 'A10')
    add('deep.ini', '[' + '.'.join('k%d' % i for i in range(5000)) + ']\nv = 1\n', INVALID_SYNTAX, 'A10')
    value = 1
    for _ in range(200):
        value = [value]
    add('deep_binary.plist', plistlib.dumps({'a': value}, fmt=plistlib.FMT_BINARY), TOO_DEEP, 'A10')
    add('shallow_binary.plist', plistlib.dumps({'a': [[[1]]]}, fmt=plistlib.FMT_BINARY), 'dictionary', 'A10')

    # A12: corrupted binary data. 损坏的二进制数据。
    corrupted = bytearray(plistlib.dumps({'a': [1, 2]}, fmt=plistlib.FMT_BINARY))
    corrupted[-9] = 0xFF  # the offset table points past the end 偏移表越界
    add('corrupted_binary.plist', bytes(corrupted), INVALID_SYNTAX, 'A12')
    item = field(1, '消息'.encode()) + field(2, b'system:message')
    item += field(18, field(1, b'Icon.**.Color') + field(2, b'#C8C8C8')) + field(18, field(1, b'Main.**.Color') + field(2, b'#266428'))
    message = field(1, item) + field(4, b'liquidGlass') + field(5, '首页 ✓'.encode())
    add('reference.binpb', message, 'dictionary', 'A12', equals='reference.json')
    add('truncated.binpb', message[:-5], INVALID_SYNTAX, 'A12')
    add('garbage.binpb', bytes([0x0F, 0xFF, 0x01, 0x02, 0x03, 0x00, 0x99]), INVALID_SYNTAX, 'A12')

    # Protobuf text: UTF-8, and octal escapes as older protoc writes them. Protobuf 文本：UTF-8，以及旧版 protoc 的八进制转义。
    text = ('CYLTabBarControllerTabBarItemsAttributes {\n  CYLTabBarItemTitle: "消息"\n  CYLTabBarItemImage: "system:message"\n'
            '  CYLTabBarLottieDarkColors { key: "Icon.**.Color" value: "#C8C8C8" }\n'
            '  CYLTabBarLottieDarkColors { key: "Main.**.Color" value: "#266428" }\n}\n'
            'CYLTabBarControllerStyleType: "liquidGlass"\nCYLTabBarControllerContext: "首页 ✓"\n')
    add('reference.textproto', text, 'dictionary', 'B3', equals='reference.json')
    octal = ''.join(c if ord(c) < 128 else ''.join('\\%03o' % b for b in c.encode()) for c in text)
    add('reference_octal.textproto', octal, 'dictionary', 'B3', equals='reference.json')

    # A3, A4: empty. 空。
    add('empty.json', '', EMPTY, 'A3')
    add('empty.yaml', '', EMPTY, 'A3')
    add('no_extension', '', EMPTY, 'A3')
    add('spaces.toml', '   \n\n\t \n', EMPTY, 'A4')
    add('comments.yaml', '# only\n# comments\n---\n', EMPTY, 'A4')
    add('comments.ini', '; only a comment\n# another\n', EMPTY, 'A4')
    add('braces.json', '{}', EMPTY, 'A4')
    # A9: too large. 过大。
    add('huge.json', '{"a": "' + 'x' * (6 * 1024 * 1024) + '"}', TOO_LARGE, 'A9')
    # A11, A13: not a dictionary, syntax errors. 不是字典、语法错误。
    add('list.json', '[1, 2]', NOT_A_DICTIONARY, 'A11')
    add('broken.json', '{ broken json', INVALID_SYNTAX, 'A13')
    add('unquoted.toml', 'a = unquoted\n', INVALID_SYNTAX, 'A13')
    add('indentation.yaml', 'a: 1\n  b: 2\n', INVALID_SYNTAX, 'A13')
    add('not_utf8.json', bytes([0x7B, 0x22, 0xC3, 0x28, 0x22, 0x3A, 0x31, 0x7D]), INVALID_SYNTAX, 'A5')
    # A7: the extension does not match the content. 扩展名与内容不符。
    add('yaml_inside.json', 'CYLTabBarControllerContext: yaml-in-json\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home\n', 'dictionary', 'A7')
    add('json_inside.toml', '{"CYLTabBarControllerContext": "json-in-toml", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home"}]}', 'dictionary', 'A7')
    # A14: XML external entity (checked for a leak by the test). XML 外部实体（测试会检查是否泄漏）。
    add('xxe.xml', '<?xml version="1.0"?>\n<!DOCTYPE r [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>\n<r><CYLTabBarControllerContext>&xxe;</CYLTabBarControllerContext></r>\n', 'dictionary', 'A14',
        values={'CYLTabBarControllerContext': ''})
    # A16: UTF-16 / UTF-32.
    yaml_text = 'CYLTabBarControllerContext: utf16\nCYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: 首页\n'
    add('utf16le.yaml', b'\xff\xfe' + yaml_text.encode('utf-16-le'), 'dictionary', 'A16')
    add('utf16be.json', b'\xfe\xff' + json.dumps(reference, ensure_ascii=False).encode('utf-16-be'), 'dictionary', 'A16', equals='reference.json')
    add('utf32le.toml', b'\xff\xfe\x00\x00' + 'CYLTabBarControllerContext = "utf32"\n[[CYLTabBarControllerTabBarItemsAttributes]]\nCYLTabBarItemTitle = "首页"\n'.encode('utf-32-le'), 'dictionary', 'A16')
    # D7: an HTML page parses (as XML); the library then refuses it with NoTabs. HTML 页面可以解析（XML）；随后由库以 NoTabs 拒绝。
    add('captive_portal.xml', '<html><head><title>Wi-Fi login</title></head><body><form>Accept</form></body></html>', 'dictionary', 'D7')
    # Parser details. 解析细节。
    add('details.yaml', "a:\n  b: [1, 2.5, true, null, 'it''s', \"x\\ty\"]\n  c:\n    - 1\n    -\n      d: e\n  f: |\n    line1\n    line2\n  g: 1_2\n", 'dictionary', 'details',
        values={'a.b.1': 2.5, 'a.b.2': True, 'a.b.4': "it's", 'a.b.5': 'x\ty', 'a.c.1.d': 'e', 'a.f': 'line1\nline2', 'a.g': '1_2'})
    add('details.toml', 'a = 1_000\nb = [ 1,\n  2, # c\n]\nc = { d = "e", f.g = true }\n[h.i]\nj = \'\'\'\nraw\\n\'\'\'\n', 'dictionary', 'details',
        values={'a': 1000, 'b.1': 2, 'c.d': 'e', 'c.f.g': True, 'h.i.j': 'raw\\n'})
    add('details.properties', 'a.b=1\na.c = x\\u0041y\\\n   z\n! comment\na.d: 10.5\n', 'dictionary', 'details', values={'a.b': 1, 'a.c': 'xAyz', 'a.d': 10.5})
    add('details.ini', '[a]\nb.0 = 1\nb.1 = "two"\nb.10 = ten\nb.2 = 3\n', 'dictionary', 'details', values={'a.b.0': 1, 'a.b.1': 'two', 'a.b.2': 3, 'a.b.3': 'ten'})

    with open(os.path.join(folder, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(cases, f, ensure_ascii=False, indent=1)
    print('%d fixtures in %s' % (len(cases), folder))


if __name__ == '__main__':
    main(sys.argv[1])
