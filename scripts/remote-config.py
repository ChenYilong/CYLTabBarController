#!/usr/bin/env python3
"""Convert tab bar configuration files to and from Firebase Remote Config.

[EN] docs/Configuration-File.md, "Firebase Remote Config". Turns a configuration file (JSON, property list or TOML: the
     formats Python's standard library reads) into what Remote Config takes, and back:
     - a Remote Config template JSON (`{"parameters": {...}}`, the shape the console's "Publish from a file" and the REST
       API use), one parameter per top-level key: a scalar as STRING / NUMBER / BOOLEAN, a nested value as JSON holding
       exactly the JSON the `.json` file has under that key (`--whole` puts the whole file in one JSON parameter,
       `CYLTabBarConfiguration`);
     - an Android defaults file (`res/xml/remote_config_defaults.xml`, for `setDefaultsAsync(R.xml.…)`);
     - an iOS defaults property list (for `setDefaults(fromPlist:)`).
     Each output reads back, through the library (`+configurationWithContentsOfFile:error:`, `CYLTabBarConfigurationParser`
     on Android) or through `to-config` here, into the same dictionary as the input. The checks follow Remote Config's
     quotas (firebase.google.com/docs/remote-config/parameters): at most 3,000 parameters, keys of at most 256 characters
     that start with a letter or an underscore and hold only letters, digits and underscores, and at most 1,000,000
     characters across all values. Python 3 standard library only.
[CN] docs/Configuration-File.md，“Firebase Remote Config”。把配置文件（JSON、属性列表或 TOML：Python 标准库能读取的格式）转换为 Remote Config
     使用的文件，也可以转换回来：
     - Remote Config 模板 JSON（`{"parameters": {...}}`，即控制台“从文件发布”与 REST API 使用的格式），每个顶层 key 一个参数：标量为
       STRING / NUMBER / BOOLEAN，嵌套的值为 JSON，内容与 `.json` 文件中该 key 下的 JSON 完全相同（`--whole` 把整个文件放进一个 JSON 参数
       `CYLTabBarConfiguration`）；
     - Android 默认值文件（`res/xml/remote_config_defaults.xml`，用于 `setDefaultsAsync(R.xml.…)`）；
     - iOS 默认值属性列表（用于 `setDefaults(fromPlist:)`）。
     每种输出都可以通过本库（`+configurationWithContentsOfFile:error:`、Android 的 `CYLTabBarConfigurationParser`）或这里的 `to-config`
     读取回与输入相同的字典。检查遵循 Remote Config 的配额（firebase.google.com/docs/remote-config/parameters）：最多 3,000 个参数，key 最长
     256 个字符、以字母或下划线开头且只包含字母、数字与下划线，所有值合计最多 1,000,000 个字符。仅使用 Python 3 标准库。

Usage 用法:
    python3 scripts/remote-config.py to-template Example-Shared/Configurations/cyl_tabbar_configuration.json -o template.json
    python3 scripts/remote-config.py to-template --whole tabbar.toml -o template.json
    python3 scripts/remote-config.py to-defaults-xml tabbar.json -o app/src/main/res/xml/remote_config_defaults.xml
    python3 scripts/remote-config.py to-defaults-plist tabbar.json -o RemoteConfigDefaults.plist
    python3 scripts/remote-config.py to-config template.json -o tabbar.json     # also a defaults .xml or .plist
    python3 scripts/remote-config.py --self-test                                # round trips of the sample files
"""

import argparse
import json
import os
import plistlib
import re
import sys
import tomllib
import tempfile
import xml.etree.ElementTree as ElementTree

WHOLE_CONFIGURATION_KEY = "CYLTabBarConfiguration"
PARAMETER_PREFIX = "CYL"
MAXIMUM_PARAMETERS = 3000
MAXIMUM_KEY_LENGTH = 256
MAXIMUM_VALUE_CHARACTERS = 1_000_000
KEY_PATTERN = re.compile(r"^[A-Za-z_]\w*$", re.ASCII)
# [EN] Geometry strings ("{0, -2}") start with "{" but are not JSON. [CN] 几何字符串（"{0, -2}"）以 "{" 开头但不是 JSON。
GEOMETRY = re.compile(r"^\{\s*-?[0-9.]+(\s*,\s*-?[0-9.]+)*\s*\}$")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAMPLES = os.path.join(ROOT, "Example-Shared", "Configurations")
PLIST_EXTENSION = ".plist"


class ConversionError(Exception):
    """[EN] A file that cannot be converted, with the reason. [CN] 无法转换的文件及原因。"""


def checked_path(path, must_exist):
    """[EN] `path` resolved (symbolic links and `..` followed), and inside this repository, the current folder or the temporary
    folder, so that an argument written by a person or by an agent cannot reach another place; an existing file when `must_exist`.
    [CN] 解析后的 `path`（跟随符号链接与 `..`），必须位于本仓库、当前目录或临时目录之内，因此由人或 agent 写出的参数无法到达其他位置；
    `must_exist` 时必须是已存在的文件。"""
    resolved = os.path.realpath(path)
    allowed = {os.path.normcase(os.path.realpath(folder)) for folder in (ROOT, os.getcwd(), tempfile.gettempdir())}
    if not any(os.path.normcase(resolved).startswith(folder + os.sep) for folder in allowed):
        raise ConversionError(f"{path}: outside this repository, the current folder and the temporary folder")
    if must_exist and not os.path.isfile(resolved):
        raise ConversionError(f"{path}: no such file")
    return resolved


# MARK: - Reading configuration files 读取配置文件

def read_configuration(path):
    """[EN] A configuration file as a dictionary (JSON, property list, TOML). [CN] 将配置文件读取为字典（JSON、属性列表、TOML）。"""
    extension = os.path.splitext(path)[1].lower()
    with open(checked_path(path, True), "rb") as handle:
        data = handle.read()
    try:
        if extension == PLIST_EXTENSION:
            value = plistlib.loads(data)
        elif extension == ".toml":
            value = tomllib.loads(data.decode("utf-8"))
        elif extension == ".json":
            value = json.loads(data.decode("utf-8-sig"))
        else:
            raise ConversionError(f"{path}: use a .json, .plist or .toml file (other formats: convert them to JSON "
                                  "first, e.g. with the Example's \"export\" row)")
    except ValueError as error:  # [EN] also plistlib.InvalidFileException and tomllib.TOMLDecodeError. [CN] 也包括它们。
        raise ConversionError(f"{path}: {error}") from error
    if not isinstance(value, dict) or not value:
        raise ConversionError(f"{path}: the top level must be a non-empty dictionary")
    return value


# MARK: - Parameters 参数

def json_text(value):
    """[EN] Compact JSON, as a Remote Config value. [CN] 紧凑的 JSON，作为 Remote Config 的值。"""
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=False)


def parameter(value):
    """[EN] (string value, Remote Config value type) of one configuration value. [CN] 一个配置值对应的（字符串值，Remote Config 值类型）。"""
    if isinstance(value, bool):
        return ("true" if value else "false"), "BOOLEAN"
    if isinstance(value, (int, float)):
        return json_text(value), "NUMBER"
    if isinstance(value, str):
        return value, "STRING"
    if isinstance(value, (dict, list)):
        return json_text(value), "JSON"
    raise ConversionError(f"a {type(value).__name__} value cannot be a Remote Config parameter (dates and data are not "
                          "configuration values)")


# [EN] The keys that hold a geometry value, and how many numbers it has: an inset has 4 (top, left, bottom, right), an
#      offset or a size has 2. A string is only read as a geometry for these keys, so a title such as "{1}" stays text.
# [CN] 几何值所在的 key 及数字个数：内边距 4 个（上、左、下、右），偏移与尺寸 2 个。只有这些 key 的字符串才按几何值读取，因此 "{1}" 这样的标题仍是文本。
GEOMETRY_KEYS = (
    (re.compile(r"^CYLTabBar(Controller|Item)?Image(Insets)$"), 4),
    (re.compile(r"^CYLTabBar(Controller|Item)?(Title|Image)PositionAdjustment$"), 2),
    (re.compile(r"^CYLTabBar(Item)?(ImageURL|Lottie|Animation|PAG|Rive|GIF)Size$"), 2),
)


def native_geometry(value, key=None):
    """[EN] `value` with each geometry string ("{0, -2}") of a geometry key turned into the JSON array Remote Config's JSON type holds
    ([0, -2]); everything else is kept. The library reads both forms (the string form is for old files). Applied to the
    nested values too (the tab items, the themes).
    [CN] 把几何 key 中的每个几何字符串（"{0, -2}"）转换为 Remote Config 的 JSON 类型所存的 JSON 数组（[0, -2]），其余保持不变。
    本库两种写法都能读取（字符串写法供旧文件使用）。嵌套的值（Tab 项、主题）同样转换。"""
    if isinstance(value, dict):
        return {name: native_geometry(item, name) for name, item in value.items()}
    if isinstance(value, list):
        return [native_geometry(item, key) for item in value]
    if isinstance(value, str) and key and GEOMETRY.match(value.strip()):
        count = next((expected for pattern, expected in GEOMETRY_KEYS if pattern.match(key)), None)
        numbers = [float(part) for part in value.strip().strip("{}").split(",")]
        if count == len(numbers):
            return [int(number) if number == int(number) else number for number in numbers]
    return value


def parameters_of(configuration, whole=False):
    """[EN] The parameters ({key: (value, type)}) of a configuration, checked against Remote Config's quotas. Geometry
    strings become JSON arrays (`native_geometry`). [CN] 配置对应的参数（{key: (值, 类型)}），并按 Remote Config 的配额检查；
    几何字符串转换为 JSON 数组（`native_geometry`）。"""
    configuration = {key: native_geometry(value, key) for key, value in configuration.items()}
    if whole:
        result = {WHOLE_CONFIGURATION_KEY: (json_text(configuration), "JSON")}
    else:
        result = {}
        for key, value in configuration.items():
            if not key.startswith(PARAMETER_PREFIX):
                raise ConversionError(f"\"{key}\" is not read from Remote Config (only {PARAMETER_PREFIX}… keys are); "
                                      "use --whole to keep it")
            result[key] = parameter(value)
    for key in result:
        if not KEY_PATTERN.match(key) or len(key) > MAXIMUM_KEY_LENGTH:
            raise ConversionError(f"\"{key}\" is not a valid Remote Config key (a letter or \"_\" first, then letters, "
                                  f"digits and \"_\", at most {MAXIMUM_KEY_LENGTH} characters); use --whole")
    if len(result) > MAXIMUM_PARAMETERS:
        raise ConversionError(f"{len(result)} parameters, more than Remote Config's {MAXIMUM_PARAMETERS}")
    characters = sum(len(value) for value, _ in result.values())
    if characters > MAXIMUM_VALUE_CHARACTERS:
        raise ConversionError(f"{characters} characters of values, more than Remote Config's "
                              f"{MAXIMUM_VALUE_CHARACTERS} per project")
    return result


# MARK: - Writing 写入

def template_json(configuration, whole=False):
    """[EN] A Remote Config template (the REST API / console file shape). [CN] Remote Config 模板（REST API / 控制台文件格式）。"""
    parameters = {key: {"defaultValue": {"value": value}, "valueType": value_type}
                  for key, (value, value_type) in parameters_of(configuration, whole).items()}
    return json.dumps({"parameters": parameters}, ensure_ascii=False, indent=2) + "\n"


def defaults_xml(configuration, whole=False):
    """[EN] An Android `remote_config_defaults.xml`. [CN] Android 的 `remote_config_defaults.xml`。"""
    root = ElementTree.Element("defaultsMap")
    for key, (value, _) in parameters_of(configuration, whole).items():
        entry = ElementTree.SubElement(root, "entry")
        ElementTree.SubElement(entry, "key").text = key
        ElementTree.SubElement(entry, "value").text = value
    ElementTree.indent(root, space="    ")
    return '<?xml version="1.0" encoding="utf-8"?>\n' + ElementTree.tostring(root, encoding="unicode") + "\n"


def defaults_plist(configuration, whole=False):
    """[EN] An iOS defaults property list: JSON parameters as strings, scalars with their type.
    [CN] iOS 默认值属性列表：JSON 参数为字符串，标量保留类型。"""
    values = {}
    for key, (value, value_type) in parameters_of(configuration, whole).items():
        if value_type == "BOOLEAN":
            values[key] = value == "true"
        elif value_type == "NUMBER":
            values[key] = json.loads(value)
        else:
            values[key] = value
    return plistlib.dumps(values, fmt=plistlib.FMT_XML)


# MARK: - Reading Remote Config files back 读取 Remote Config 文件

def decoded(value):
    """[EN] One value as the library decodes it: JSON objects and arrays parsed, other strings kept. The library also
    types scalar strings ("true", "12") as the .properties reader does; this script keeps the types the input had.
    [CN] 按本库的方式解码一个值：解析 JSON 对象与数组，其他字符串保持不变。本库还会像 .properties 读取器一样转换标量字符串（"true"、"12"）的类型；
    本脚本保留输入中的类型。"""
    if isinstance(value, str) and value.strip()[:1] in ("{", "["):
        try:
            return json.loads(value)
        except ValueError:
            if GEOMETRY.match(value.strip()):
                # [EN] "{0, -2}": an offset, an inset or a size, not JSON. [CN] 偏移、内边距或尺寸，不是 JSON。
                return value
            raise
    return value


def configuration_from_values(values, types=None):
    """[EN] Remote Config values (and their value types) as a configuration, as the library reads them.
    [CN] 按本库的读取方式，把 Remote Config 的值（及其值类型）转换为配置。"""
    types = types or {}
    configuration = {}
    whole = values.get(WHOLE_CONFIGURATION_KEY)
    if isinstance(whole, str) and whole.strip():
        configuration.update(json.loads(whole))
    for key in sorted(values):
        value = values[key]
        if key == WHOLE_CONFIGURATION_KEY or not key.startswith(PARAMETER_PREFIX) or value in ("", None):
            continue
        value_type = types.get(key)
        if value_type == "NUMBER" and isinstance(value, str):
            value = json.loads(value)
        elif value_type == "BOOLEAN" and isinstance(value, str):
            value = value.strip().lower() == "true"
        configuration[key] = value if value_type == "STRING" else decoded(value)
    if not configuration:
        raise ConversionError(f"no {PARAMETER_PREFIX}… parameter (or \"{WHOLE_CONFIGURATION_KEY}\") with a value")
    return configuration


def read_remote_config_file(path):
    """[EN] A template JSON, a defaults .xml or a defaults .plist as a configuration.
    [CN] 将模板 JSON、默认值 .xml 或默认值 .plist 读取为配置。"""
    extension = os.path.splitext(path)[1].lower()
    with open(checked_path(path, True), "rb") as handle:
        data = handle.read()
    if extension == ".xml":
        root = ElementTree.fromstring(data)
        if root.tag != "defaultsMap":
            raise ConversionError(f"{path}: not a Remote Config defaults file (<defaultsMap>)")
        values = {entry.findtext("key", ""): entry.findtext("value", "") for entry in root.iter("entry")}
        return configuration_from_values(values)
    if extension == PLIST_EXTENSION:
        return configuration_from_values(plistlib.loads(data))
    template = json.loads(data.decode("utf-8-sig"))
    values, types = {}, {}
    parameter_sets = [template.get("parameters", {})]
    parameter_sets += [group.get("parameters", {}) for group in template.get("parameterGroups", {}).values()]
    for parameters in parameter_sets:
        for key, item in parameters.items():
            default = item.get("defaultValue", {})
            if default.get("useInAppDefault") or "value" not in default:
                continue
            values[key] = default["value"]
            types[key] = item.get("valueType")
    return configuration_from_values(values, types)


# MARK: - Self-test 自测

def sample_configurations():
    """[EN] (relative path, configuration) of every sample file that is a configuration (not, for example, a manifest or a
    localization table). [CN] 每个属于配置的示例文件的（相对路径，配置）（例如清单或字符串表不算）。"""
    for folder, _, files in os.walk(SAMPLES):
        for name in sorted(files):
            if os.path.splitext(name)[1].lower() not in (".json", PLIST_EXTENSION, ".toml"):
                continue
            sample = os.path.join(folder, name)
            try:
                configuration = read_configuration(sample)
            except ConversionError:
                continue
            if any(key.startswith(PARAMETER_PREFIX) for key in configuration):
                yield os.path.relpath(sample, ROOT), configuration


def writers(whole):
    """[EN] (file name, function) of the three outputs, for the flat or the whole-file mapping. [CN] 三种输出的（文件名，函数），分别用于扁平映射或整个文件映射。"""
    return (("template.json", lambda configuration: template_json(configuration, whole).encode()),
            ("defaults.xml", lambda configuration: defaults_xml(configuration, whole).encode()),
            ("defaults.plist", lambda configuration: defaults_plist(configuration, whole)))


def round_trip_problem(configuration, writer, path):
    """[EN] Why `configuration` written by `writer` to `path` does not read back as itself (the geometry strings come back as the
    JSON arrays of Remote Config), or None. [CN] `writer` 写入 `path` 的 `configuration` 为什么读不回自身（几何字符串读回时是 Remote Config 的 JSON 数组），没有问题时为 None。"""
    try:
        with open(path, "wb") as handle:
            handle.write(writer(configuration))
        back = read_remote_config_file(path)
    except (ConversionError, ValueError, ElementTree.ParseError) as error:
        return str(error)
    expected = {key: native_geometry(value, key) for key, value in configuration.items()}
    return None if back == expected else "reads back differently"


def self_test():
    """[EN] Every JSON, property list and TOML sample: each output reads back into the input, and the files written are
    valid (a template is JSON, a defaults file is a <defaultsMap>). [CN] 每个 JSON、属性列表与 TOML 示例文件：每种输出都能读取回输入，且写出的
    文件有效（模板是 JSON，默认值文件是 <defaultsMap>）。"""
    failures = checks = samples = 0
    with tempfile.TemporaryDirectory() as work:
        for relative, configuration in sample_configurations():
            samples += 1
            flat_ok = all(key.startswith(PARAMETER_PREFIX) for key in configuration)
            for whole in ([False, True] if flat_ok else [True]):
                for suffix, writer in writers(whole):
                    checks += 1
                    problem = round_trip_problem(configuration, writer, os.path.join(work, ("whole-" if whole else "") + suffix))
                    if problem:
                        failures += 1
                        print(f"  FAIL {relative} → {suffix}{' (whole)' if whole else ''}: {problem}")
    print(f"{checks} round trips, {failures} failures, {samples} sample configurations looked at")
    return failures == 0 and checks > 0


def build_parser():
    """[EN] The command line. [CN] 命令行。"""
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--self-test", action="store_true", help="round trips of the sample files")
    sub = parser.add_subparsers(dest="command")
    for name in ("to-template", "to-defaults-xml", "to-defaults-plist", "to-config"):
        command = sub.add_parser(name)
        command.add_argument("input")
        command.add_argument("-o", "--output", help="the file to write (default: standard output)")
        if name != "to-config":
            command.add_argument("--whole", action="store_true",
                                 help=f"one JSON parameter, {WHOLE_CONFIGURATION_KEY}, holding the whole file")
    return parser


def convert(arguments):
    """[EN] The bytes of the output file of the command `arguments` names. [CN] `arguments` 所指命令的输出文件内容。"""
    if arguments.command == "to-config":
        return (json.dumps(read_remote_config_file(arguments.input), ensure_ascii=False, indent=2) + "\n").encode()
    configuration = read_configuration(arguments.input)
    if arguments.command == "to-template":
        return template_json(configuration, arguments.whole).encode()
    if arguments.command == "to-defaults-xml":
        return defaults_xml(configuration, arguments.whole).encode()
    return defaults_plist(configuration, arguments.whole)


def write_output(output, destination):
    """[EN] `output` into `destination` (a path checked like the inputs), or to standard output. [CN] 将 `output` 写入 `destination`（路径与输入一样检查），没有时写到标准输出。"""
    if destination:
        with open(checked_path(destination, False), "wb") as handle:
            handle.write(output)
    else:
        sys.stdout.buffer.write(output)


def main(argv=None):
    parser = build_parser()
    arguments = parser.parse_args(argv)
    if arguments.self_test:
        return 0 if self_test() else 1
    if not arguments.command:
        parser.print_help()
        return 2
    try:
        write_output(convert(arguments), arguments.output)
    except (ConversionError, ValueError, OSError, ElementTree.ParseError) as error:
        print(f"remote-config.py: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
