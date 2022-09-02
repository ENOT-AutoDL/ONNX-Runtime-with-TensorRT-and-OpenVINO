import ctypes
import logging
from pathlib import Path
from typing import Sequence

__all__ = [
    'load_shared_libraries',
]

_LOGGER = logging.getLogger(__name__)
_HANDLERS = []
_EXTRA_LIB_PATH = []

try:
    import nvidia
    _EXTRA_LIB_PATH.append(next(iter(nvidia.__path__)))
except ImportError:
    pass

try:
    import tensorrt
    _EXTRA_LIB_PATH.append(next(iter(tensorrt.__path__)))
except ImportError:
    pass

try:
    import openvino
    _EXTRA_LIB_PATH.append(next(iter(openvino.__path__)) + '/libs')
except ImportError:
    pass


def load_shared_libraries(so_names: Sequence[str]) -> None:
    for so in so_names:
        _load_shared_library(so)


def _load_shared_library(library: str) -> None:
    global _HANDLERS
    try:
        _HANDLERS.append(ctypes.CDLL(library, mode=ctypes.RTLD_GLOBAL))
    except OSError:
        for path in _EXTRA_LIB_PATH:
            path = Path(path)
            for file in path.rglob('*.so*'):
                if library in file.name:
                    _HANDLERS.append(ctypes.CDLL(str(file), mode=ctypes.RTLD_GLOBAL))
                    return
        _LOGGER.warning(f'Cannot load "{library}"')
