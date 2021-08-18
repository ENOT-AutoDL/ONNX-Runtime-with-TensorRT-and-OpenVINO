import ctypes
import logging
from pathlib import Path
from typing import Sequence

__all__ = [
    'load_shared_libraries',
]

_LOGGER = logging.getLogger(__name__)
_HANDLERS = []


def load_shared_libraries(so_names: Sequence[str]) -> None:
    try:
        import nvidia
        import tensorrt
        import openvino
        paths = [
            next(iter(nvidia.__path__)),
            next(iter(tensorrt.__path__)),
            next(iter(openvino.__path__)),
        ]
        for so in so_names:
            _load_shared_library(so, paths)
    except ImportError:
        pass


def _load_shared_library(library: str, paths: Sequence[str]) -> None:
    global _HANDLERS
    mode = ctypes.RTLD_GLOBAL
    try:
        _HANDLERS.append(ctypes.CDLL(library, mode=mode))
    except OSError:
        for path in paths:
            path = Path(path)
            for file in path.rglob('**/*.so*'):
                if library in file.name:
                    _HANDLERS.append(ctypes.CDLL(str(file), mode=mode))
                    return
        _LOGGER.warning(f'Cannot load "{library}"')
