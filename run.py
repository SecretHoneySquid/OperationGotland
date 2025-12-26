"""Helper entrypoint that wires the src/ layout into PYTHONPATH for quick runs."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).parent
SRC = ROOT / "src"
sys.path.append(str(SRC))

from operation_gotland.main import main  # noqa: E402

if __name__ == "__main__":
    main()
