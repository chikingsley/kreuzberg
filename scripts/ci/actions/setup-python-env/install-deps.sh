#!/usr/bin/env bash
set -euo pipefail

# Python 3.13: Exclude benchmark group due to missing wheels for av (via mineru -> qwen-vl-utils)
# See: https://github.com/PyAV-Org/PyAV/issues - av 16.1.0 only has wheels up to Python 3.12
PYTHON_VERSION=$(uv run python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$PYTHON_VERSION" == "3.13" ]]; then
  uv sync --all-packages --group dev --group docs --group doc --all-extras --no-install-project --no-install-workspace
else
  uv sync --all-packages --all-groups --all-extras --no-install-project --no-install-workspace
fi

if ! uv run python -c "import cv2; assert hasattr(cv2, 'cvtColor')" 2>/dev/null; then
  echo "⚠️  Detected broken cv2 module, reinstalling OpenCV packages..." >&2
  uv pip uninstall opencv-contrib-python opencv-python-headless --quiet 2>/dev/null || true
  uv pip install opencv-python-headless opencv-contrib-python
  echo "✅ OpenCV packages reinstalled" >&2
fi
