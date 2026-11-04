#!/usr/bin/env python3
"""The edge-case checklist of configuration loading, its score per round, and the docs table generated from it.

[EN] Every edge case of `-initWithConfiguration:`, the configuration files and the URL loading (A: files and data,
     B: values, C: view controllers, D: network, E: threads), with the round of fixes that handled it. The score of a
     round = handled cases / cases known in that round (partly handled counts half); cases found during a review are
     added with `found`, so a score can drop. The table between `<!-- edge-cases:start -->` and `<!-- edge-cases:end -->`
     in docs/Configuration-File.md is generated from this file: edit the list here, never the table.
[CN] `-initWithConfiguration:`、配置文件与 URL 加载的所有边界情况（A：文件与数据，B：值，C：子控制器，D：网络，E：线程），以及处理它的修复轮次。
     某一轮的分数 = 已处理的情况 / 该轮已知的情况（部分处理计一半）；复查中发现的情况用 `found` 加入，因此分数可能下降。
     docs/Configuration-File.md 中 `<!-- edge-cases:start -->` 与 `<!-- edge-cases:end -->` 之间的表格由本文件生成：请修改这里的列表，不要直接修改表格。

Usage 用法:
    python3 scripts/configuration-edge-cases.py            # score of every round 每一轮的分数
    python3 scripts/configuration-edge-cases.py --write    # regenerate the docs table 重新生成文档中的表格
    python3 scripts/configuration-edge-cases.py --check    # exit 1 if the docs table is out of date 表格过期时返回 1

Add a case 新增情况: append a tuple (ID, 中文情况, English case, 中文处理, English handling,
{'fixed': <round>, 'partial': <round, optional>, 'found': <round, default 1>}) and, for a new round, an entry in ROUNDS.
"""
import os
import sys

CASES = [
 # A. Files and data 文件与数据
 ('A1', '文件路径为 nil 或空字符串', 'The file path is nil or empty', '返回 nil 与 FileNotFound 错误', 'nil and a FileNotFound error', {'fixed': 1}),
 ('A2', '文件不存在、是目录或无读取权限', 'The file is missing, a directory or unreadable', '返回 nil 与 FileNotFound 错误', 'nil and a FileNotFound error', {'fixed': 1}),
 ('A3', '文件为 0 字节', 'The file has 0 bytes', 'Empty 错误（以前 YAML 等格式会生成没有 Tab 的控制器）', 'An Empty error (YAML and others used to give a controller with no tabs)', {'fixed': 3, 'partial': 1}),
 ('A4', '文件只有空白或注释', 'The file has only whitespace or comments', 'Empty 错误', 'An Empty error', {'fixed': 3}),
 ('A5', '不是合法的 UTF-8 文本', 'Not valid UTF-8 text', 'InvalidSyntax 错误', 'An InvalidSyntax error', {'fixed': 1}),
 ('A6', '以 UTF-8 BOM 开头', 'Starts with a UTF-8 BOM', '自动去掉 BOM', 'The BOM is skipped', {'fixed': 1}),
 ('A7', '扩展名与内容不符（如 .json 中是 YAML）', 'The extension does not match the content (YAML in a .json file)', '按扩展名解析失败后根据内容识别并重试', 'When the extension\'s format fails, the content is detected and parsed again', {'fixed': 4}),
 ('A8', '扩展名未知或缺失', 'An unknown or missing extension', '根据内容识别格式', 'The format is detected from the content', {'fixed': 1}),
 ('A9', '文件过大（例如 1 GB）', 'A huge file (e.g. 1 GB)', '超过 5 MB 时返回 TooLarge 错误，不读入内存解析', 'Over 5 MB: a TooLarge error, nothing is parsed', {'fixed': 3}),
 ('A10', '嵌套过深（如 10 万层 `[[[[`）导致栈溢出', 'Deep nesting (e.g. 100,000 levels of `[[[[`) overflows the stack', '超过 64 层时返回 TooDeep 错误，所有递归解析器都有层数限制', 'Over 64 levels: a TooDeep error; every recursive parser has a depth limit', {'fixed': 2}),
 ('A11', '顶层不是字典（数组、字符串、数字）', 'The top level is not a dictionary (a list, a string, a number)', 'NotADictionary 错误', 'A NotADictionary error', {'fixed': 1}),
 ('A12', '截断或无效的二进制 plist / protobuf', 'A truncated or invalid binary plist / protobuf', 'InvalidSyntax 错误，越界读取被拒绝', 'An InvalidSyntax error; out-of-bounds reads are refused', {'fixed': 1}),
 ('A13', '语法错误', 'A syntax error', '错误描述包含格式与行号', 'The error names the format and the line', {'fixed': 1}),
 ('A14', 'XML 外部实体（XXE）', 'XML external entities (XXE)', '显式关闭外部实体解析', 'External entities are explicitly not resolved', {'fixed': 4, 'partial': 1}),
 ('A15', '重复的键', 'Duplicate keys', '后出现的值生效，不崩溃', 'The last value wins, no crash', {'fixed': 1}),
 ('A16', 'UTF-16 / UTF-32 编码的文本文件（带 BOM）', 'A UTF-16 / UTF-32 text file (with a BOM)', '根据 BOM 识别编码', 'The encoding is detected from the BOM', {'fixed': 6, 'found': 5}),
 ('A17', 'A7 的重试掩盖了语法错误（.properties、INI、Protobuf 文本几乎接受任何文本；TOML 曾接受 `[1, 2]` 这样的表名）', 'The retry of A7 hid syntax errors (.properties, INI and Protobuf text accept almost any text; TOML accepted a table named `[1, 2]`)', '重试只使用结构明确的格式（JSON、YAML、TOML、plist、XML、二进制 Protobuf），TOML 裸键只接受规范允许的字符；由测试套件发现', 'The retry only uses formats with a distinctive structure (JSON, YAML, TOML, plist, XML, binary Protobuf), and TOML bare keys only take the characters of the specification; found by the test suite', {'fixed': 7, 'found': 7}),
 # B. Values 值
 ('B1', '没有 Tab（缺少或为空的 `CYLTabBarControllerTabBarItemsAttributes`）', 'No tabs (missing or empty `CYLTabBarControllerTabBarItemsAttributes`)', '读取文件或 URL 时返回 NoTabs 错误；代码中初始化时保持原行为并输出警告', 'Files and URLs: a NoTabs error; in code: unchanged behavior and a warning', {'fixed': 3}),
 ('B2', 'Tab 列表不是数组（字符串、数字）', 'The tab list is not a list (a string, a number)', '视为没有 Tab，见 B1', 'Treated as no tabs, see B1', {'fixed': 3, 'partial': 1}),
 ('B3', '只有一个 Tab 且写成字典（Protobuf 文本、XML）', 'A single tab written as a dictionary (Protobuf text, XML)', '自动包装为列表', 'Wrapped into a list', {'fixed': 1}),
 ('B4', 'Tab 列表中的元素不是字典', 'A tab entry is not a dictionary', '代码传入子控制器时用空字典占位，保持下标对应；根据配置创建子控制器时跳过', 'With view controllers from code: an empty placeholder keeps the indexes; when they are created: skipped', {'fixed': 4, 'partial': 1}),
 ('B5', '字符串键的值类型错误（标题为数组、字典）', 'A string key has the wrong type (a title that is a list or a dictionary)', '数字转换为字符串，其他类型移除；以前会因 unrecognized selector 崩溃', 'Numbers become strings, other types are removed; this used to crash (unrecognized selector)', {'fixed': 2}),
 ('B6', '值为 null（JSON null、YAML ~）', 'A value is null (JSON null, YAML ~)', '移除该键；以前在 item 中会崩溃', 'The key is removed; inside an item this used to crash', {'fixed': 2}),
 ('B7', '内边距 / 偏移为 NaN、Infinity 或极大值', 'Insets / offsets are NaN, Infinity or huge', '非有限值或绝对值超过 1000 时移除；以前会触发 CALayer NaN 异常', 'Non-finite values or values over 1000 are removed; this used to raise a CALayer NaN exception', {'fixed': 2}),
 ('B8', '尺寸为负数、0 或极大值', 'A size is negative, zero or huge', '要求 0 < 值 ≤ 1000，否则移除', 'Requires 0 < value ≤ 1000, removed otherwise', {'fixed': 2}),
 ('B9', '未知的样式名称或超出范围的样式编号（如 99）', 'An unknown style name or an out-of-range style number (e.g. 99)', '使用默认样式并输出警告', 'The default style and a warning', {'fixed': 2, 'partial': 1}),
 ('B10', '请求扁平样式但未集成 FlatDesign 子库', 'FlatDesign requested without the FlatDesign subspec', '使用默认样式并输出警告', 'The default style and a warning', {'fixed': 4}),
 ('B11', '拼写错误的键（如 `CYLTabBarItemTitel`）', 'A misspelled key (e.g. `CYLTabBarItemTitel`)', '保留（App 可能有自定义键），DEBUG 下提示最接近的已知键', 'Kept (the app may use its own keys); DEBUG names the closest known key', {'fixed': 4}),
 ('B12', '重复的 `CYLTabBarItemIdentifier`', 'A duplicate `CYLTabBarItemIdentifier`', '后出现的改为「标识_2」等并输出警告', 'Later ones become "identifier_2"..., with a warning', {'fixed': 4}),
 ('B13', '无效的图片 / Lottie URL，或不存在的本地 Lottie 文件', 'An invalid image / Lottie URL, or a missing local Lottie file', '只接受 http(s) 与存在的本地文件，否则移除', 'Only http(s) URLs and existing local files are kept', {'fixed': 4}),
 ('B14', '图片名称或 SF Symbol 不存在', 'An image name or SF Symbol that does not exist', '该 Tab 没有图标，不崩溃', 'The tab has no icon, no crash', {'fixed': 1}),
 ('B15', 'Tab 很多（超过 5 个）', 'Many tabs (more than 5)', '由 UIKit 处理（“更多”）', 'Handled by UIKit ("More")', {'fixed': 1}),
 ('B16', '超长标题', 'A very long title', '不崩溃，由 UIKit 截断显示', 'No crash; UIKit truncates it', {'fixed': 1}),
 ('B17', 'Lottie 文件不是合法的 JSON 动画', 'A Lottie file that is not a valid JSON animation', '解析检查失败时移除，避免 Lottie 内部异常', 'Removed when it does not parse as a JSON object, so Lottie never sees it', {'fixed': 6, 'found': 5}),
 ('B18', '代码中传入的配置不是字典（如类型不明的 JSON 数组）', 'The configuration passed in code is not a dictionary (e.g. an untyped JSON list)', '视为空配置并输出警告；以前会因 unrecognized selector 崩溃', 'Treated as empty, with a warning; this used to crash (unrecognized selector)', {'fixed': 6, 'found': 6}),
 ('B19', '无效的颜色（`CYLTabBarItemTitleColor` 等为错误的十六进制串或数字）', 'An invalid color (`CYLTabBarItemTitleColor`... a wrong hex string or a number)', '接受 UIColor 与 "#RGB" / "#RRGGBB" / "#RRGGBBAA"，其他移除并输出警告', 'UIColor and "#RGB" / "#RRGGBB" / "#RRGGBBAA" are accepted; anything else is removed, with a warning', {'fixed': 8, 'found': 8}),
 ('B20', '无效的字体（字号为 0、NaN、超过 200，或字体名称不存在）', 'An invalid font (size 0, NaN, over 200, or a font name that does not exist)', '字号必须在 1 到 200 之间，字体必须存在，否则移除并输出警告', 'The size must be between 1 and 200 and the font must exist; removed otherwise, with a warning', {'fixed': 8, 'found': 8}),
 # C. View controllers 子控制器
 ('C1', '子控制器类不存在', 'The view controller class does not exist', '使用 UIViewController 并输出警告', 'UIViewController and a warning', {'fixed': 1}),
 ('C2', '类不是 UIViewController（如 NSString）', 'The class is not a UIViewController (e.g. NSString)', '使用 UIViewController 并输出警告', 'UIViewController and a warning', {'fixed': 1}),
 ('C3', '子控制器类是 UITabBarController / UINavigationController / UIAlertController 等容器', 'The class is a container: UITabBarController, UINavigationController, UIAlertController...', '拒绝并使用 UIViewController', 'Refused; UIViewController is used', {'fixed': 4}),
 ('C4', '子控制器的 -init 抛出异常', 'The view controller\'s -init raises an exception', '捕获异常并使用 UIViewController', 'The exception is caught; UIViewController is used', {'fixed': 4}),
 ('C5', '导航控制器类无效', 'An invalid navigation controller class', '不嵌入导航控制器', 'Not embedded', {'fixed': 1}),
 ('C6', '`CYLTabBarControllerViewControllers` 中有非控制器对象', '`CYLTabBarControllerViewControllers` holds objects that are not view controllers', '移除这些对象；以前会崩溃', 'They are removed; this used to crash', {'fixed': 2}),
 ('C7', '同一个子控制器出现两次', 'The same view controller twice', '移除重复项；以前 UIKit 会抛异常', 'The duplicate is removed; UIKit used to raise', {'fixed': 2}),
 ('C8', '子控制器数量与 Tab 数量不一致', 'More or fewer view controllers than tabs', '本库按下标保护，不越界', 'The library checks indexes, no out-of-bounds access', {'fixed': 1}),
 ('C9', '`CYLTabBarControllerViewControllers` 为空数组', '`CYLTabBarControllerViewControllers` is an empty list', '视为未提供，根据 Tab 创建子控制器', 'Treated as missing: the view controllers are created from the tabs', {'fixed': 6, 'found': 5}),
 # D. Network 网络
 ('D1', 'URL 为 nil', 'A nil URL', '回调返回 FileNotFound 错误', 'The completion gets a FileNotFound error', {'fixed': 1}),
 ('D2', '不支持的 scheme 或无效 URL', 'An unsupported scheme or an invalid URL', '回调返回 Network 错误', 'The completion gets a Network error', {'fixed': 1}),
 ('D3', 'HTTP 4xx / 5xx', 'HTTP 4xx / 5xx', 'Network 错误，包含状态码', 'A Network error with the status code', {'fixed': 1}),
 ('D4', '无网络、DNS 失败', 'No network, a DNS failure', 'Network 错误（NSUnderlyingErrorKey 为原始错误）', 'A Network error (NSUnderlyingErrorKey holds the original)', {'fixed': 1}),
 ('D5', '服务器不响应', 'The server does not answer', '默认 15 秒超时（以前为系统默认的 60 秒）；可传入自定义 NSURLRequest', 'A 15 s timeout by default (it was the system\'s 60 s); a custom NSURLRequest can be passed', {'fixed': 5}),
 ('D6', '响应体为空', 'An empty response body', 'Empty 错误', 'An Empty error', {'fixed': 3, 'partial': 1}),
 ('D7', '返回 HTML 页面（如公共 Wi-Fi 的登录页）', 'An HTML page instead (e.g. a captive Wi-Fi portal)', '识别为没有 Tab 的配置，返回 NoTabs 错误；以前会生成空的 TabBar', 'Detected as a configuration with no tabs: a NoTabs error; it used to give an empty tab bar', {'fixed': 3}),
 ('D8', '响应过大', 'A huge response', '超过 5 MB 时返回 TooLarge 错误', 'Over 5 MB: a TooLarge error', {'fixed': 3}),
 ('D9', 'Content-Type 错误（如 text/plain）', 'A wrong Content-Type (e.g. text/plain)', '根据扩展名或内容识别', 'Detected from the extension or the content', {'fixed': 1}),
 ('D10', '请求被取消', 'The request is cancelled', '回调仍会执行一次，返回 Network 错误', 'The completion still runs once, with a Network error', {'fixed': 1}),
 ('D11', '回调线程与次数', 'Completion thread and count', '总在主队列执行且只执行一次', 'Always on the main queue, exactly once', {'fixed': 1}),
 ('D12', 'completion 为 nil', 'A nil completion', '不发起请求，返回 nil', 'No request is made; returns nil', {'fixed': 1}),
 # E. Threads 线程
 ('E1', '在后台线程读取文件并创建控制器', 'Reading a file and creating the controller on a background thread', '文件接口返回 MainThreadRequired 错误；代码初始化输出警告（与原行为一致）', 'The file APIs return a MainThreadRequired error; the code initializer warns (as before)', {'fixed': 5}),
 ('E2', '在后台线程只解析配置字典', 'Only parsing the dictionary on a background thread', '解析器只依赖 Foundation，线程安全', 'The parser is Foundation only and thread-safe', {'fixed': 1}),
]

ROUNDS = {
 1: ('基线：解析器已能拒绝大部分无效文件，但值的类型、NaN、嵌套深度、空文件与 HTML 页面等会导致崩溃或生成空 TabBar。',
     'Baseline: the parser already refuses most invalid files, but wrong value types, NaN, deep nesting, empty files and HTML pages crash or give an empty tab bar.'),
 2: ('修复会崩溃的情况：值的类型检查、null、NaN / Infinity、尺寸范围、样式编号范围、非控制器对象、重复的控制器、嵌套深度限制。',
     'Crash fixes: value type checks, null, NaN / Infinity, size ranges, style number range, objects that are not view controllers, duplicate view controllers, nesting depth limit.'),
 3: ('语义校验：空文件、没有 Tab、HTML 页面、文件 / 响应大小限制，新增错误码 Empty、TooLarge、TooDeep、NoTabs。',
     'Semantic checks: empty files, no tabs, HTML pages, file / response size limits; new error codes Empty, TooLarge, TooDeep, NoTabs.'),
 4: ('容错：扩展名不符时重试、XXE、容器类与 -init 异常、无效 Tab 占位、FlatDesign 不可用、拼写错误提示、重复标识、URL 与本地文件检查。',
     'Tolerance: retry when the extension is wrong, XXE, container classes and -init exceptions, placeholders for invalid tabs, FlatDesign missing, typo hints, duplicate identifiers, URL and local file checks.'),
 5: ('网络超时与线程：默认 15 秒超时、可传入 NSURLRequest、后台线程保护。复查时新发现 4 个问题（A16、B17、C9），总分下降。',
     'Network timeout and threads: a 15 s default timeout, a custom NSURLRequest, background-thread protection. The review found new cases (A16, B17, C9), so the score dropped.'),
 6: ('修复新发现的问题：UTF-16 / UTF-32、无效的 Lottie 文件、空的子控制器数组；复查又发现并修复了 B18（配置不是字典）。全部情况均已处理。',
     'Fixes for the new cases: UTF-16 / UTF-32, invalid Lottie files, an empty view controller list; the review also found and fixed B18 (a configuration that is not a dictionary). Every case is handled.'),
 8: ('合并 master 后，新增的 11 个 Tab 键（颜色、字体、无障碍）加入配置：文件中颜色写作 "#RRGGBB"，字体写作字号、"bold:15" 或 "Menlo-Regular:12"，无障碍键做字符串检查；导出脚本与 Protobuf 结构定义（字段 22–32）同步更新。新增并处理 B19、B20。',
     'After merging master, its 11 new tab keys (colors, fonts, accessibility) join the configuration: colors as "#RRGGBB" in files, fonts as a size, "bold:15" or "Menlo-Regular:12", the accessibility keys checked as strings; the export script and the Protobuf schema (fields 22-32) follow. B19 and B20 added and handled.'),
 7: ('测试固化为 scripts/configuration-tests/run-tests.sh 后，测试套件发现第 4 轮的回归（A17）：A7 的重试会把 .json 中的数组、无效的 TOML、缩进错误的 YAML 当作 .properties、TOML 表或 Protobuf 文本读取，掩盖其错误。已修复，所有测试通过。',
     'With the tests kept as scripts/configuration-tests/run-tests.sh, the suite found a regression of round 4 (A17): the retry of A7 read a list in a .json file, invalid TOML and badly indented YAML as .properties, a TOML table or Protobuf text, hiding their errors. Fixed; every test passes.'),
}


def status(case, round_):
    info = case[5]
    if info.get('found', 1) > round_:
        return None
    if info['fixed'] <= round_:
        return 1.0
    if info.get('partial') and info['partial'] <= round_:
        return 0.5
    return 0.0


def score(round_):
    values = [status(c, round_) for c in CASES]
    values = [v for v in values if v is not None]
    return round(100 * sum(values) / len(values)), len(values)


def section(current):
    out = ['<!-- edge-cases:start -->', '<!-- Generated from the edge-case checklist; the status column is the round that handled each case. -->', '']
    out += ['| 编号 ID | 情况 | Case | 处理 | Handling | 状态 Status |', '|:---|:---|:---|:---|:---|:---|']
    for c in CASES:
        s = status(c, current)
        if s is None:
            continue
        # [EN] Ordered comparisons: the status is 1.0, 0.5 or 0.0 (no float equality).
        # [CN] 使用大小比较：状态为 1.0、0.5 或 0.0（不对浮点数做相等比较）。
        if s >= 1:
            mark = '✅ 第 %d 轮 / round %d' % (c[5]['fixed'], c[5]['fixed'])
        elif s > 0:
            mark = '🟡 部分 / partial'
        else:
            mark = '❌ 未处理 / not yet'
        out.append('| %s | %s | %s | %s | %s | %s |' % (c[0], c[1], c[2], c[3], c[4], mark))
    out += ['', '| 轮次 Round | 分数 Score | 情况数 Cases | 说明 | Notes | 减分项 Deductions |', '|:---|:---|:---|:---|:---|:---|']
    for r in range(1, current + 1):
        sc, n = score(r)
        open_cases = [c[0] for c in CASES if status(c, r) not in (None, 1.0)]
        out.append('| %d | %d | %d | %s | %s | %s |' % (r, sc, n, ROUNDS[r][0], ROUNDS[r][1], ', '.join(open_cases) or '—'))
    out.append('<!-- edge-cases:end -->')
    return '\n'.join(out)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, 'docs', 'Configuration-File.md')
START, END = '<!-- edge-cases:start -->', '<!-- edge-cases:end -->'


def last_round():
    return max(ROUNDS)


def main():
    current = last_round()
    for r in range(1, current + 1):
        sc, n = score(r)
        open_cases = ', '.join(c[0] for c in CASES if status(c, r) not in (None, 1.0)) or 'none'
        print('round %d: %d / 100 (%d cases); open: %s' % (r, sc, n, open_cases))
    if '--write' in sys.argv or '--check' in sys.argv:
        text = open(DOC, encoding='utf-8').read()
        start, end = text.index(START), text.index(END) + len(END)
        updated = text[:start] + section(current) + text[end:]
        if '--check' in sys.argv:
            if updated != text:
                print('docs/Configuration-File.md is out of date: run python3 scripts/configuration-edge-cases.py --write')
                return 1
            print('docs/Configuration-File.md is up to date.')
        elif updated != text:
            open(DOC, 'w', encoding='utf-8').write(updated)
            print('updated docs/Configuration-File.md')
    return 0


if __name__ == '__main__':
    sys.exit(main())
