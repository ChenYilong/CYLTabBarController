"""Path checks shared by the configuration test scripts (lower.py, make-fixtures.py).

[EN] Python 3 standard library only. [CN] 配置测试脚本（lower.py、make-fixtures.py）共用的路径检查，仅使用 Python 3 标准库。
"""
import os
import sys
import tempfile

# [EN] The repository and the temporary folder. [CN] 仓库与临时目录。
ALLOWED_ROOTS = (os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), tempfile.gettempdir())


def confined_path(path, roots):
    """[EN] The real path of `path` when it lies inside one of `roots`, else exit: no path traversal from arguments.
    [CN] `path` 位于 `roots` 之一内时返回其真实路径，否则退出：防止通过参数进行路径穿越。"""
    real = os.path.realpath(path)
    for root in roots:
        root = os.path.realpath(root)
        if real == root or real.startswith(root + os.sep):
            return real
    sys.exit('%s: outside %s' % (path, ' / '.join(roots)))
