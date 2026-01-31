#!/usr/bin/env bash
# Measure installed disk sizes for non-Kreuzberg benchmark frameworks.
#
# For each Python framework, creates a fresh venv, measures size before and after
# pip install, and reports the delta as the installed size.
#
# Output: JSON mapping framework name -> DiskSizeInfo
#
# Usage:
#   scripts/benchmarks/measure-disk-sizes.sh [--output PATH]

set -euo pipefail

OUTPUT_FILE="${1:---}"
TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Python frameworks to measure
declare -A PYTHON_PACKAGES=(
  ["docling"]="docling"
  ["markitdown"]="markitdown"
  ["unstructured"]="unstructured"
  ["pymupdf4llm"]="pymupdf4llm"
  ["pdfplumber"]="pdfplumber"
)

# Results accumulator
RESULTS="{"
FIRST=true

measure_python_package() {
  local name="$1"
  local package="$2"
  local venv_dir="$TMPDIR_BASE/venv-$name"

  echo "Measuring $name ($package)..." >&2

  python3 -m venv "$venv_dir" 2>/dev/null
  local before
  before=$(du -sb "$venv_dir" 2>/dev/null | awk '{print $1}' || du -sk "$venv_dir" | awk '{print $1 * 1024}')

  "$venv_dir/bin/pip" install --quiet "$package" 2>/dev/null || {
    echo "  Warning: Failed to install $package" >&2
    return 1
  }

  local after
  after=$(du -sb "$venv_dir" 2>/dev/null | awk '{print $1}' || du -sk "$venv_dir" | awk '{print $1 * 1024}')

  local delta=$((after - before))
  echo "  $name: $delta bytes ($((delta / 1024 / 1024)) MB)" >&2

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    RESULTS+=","
  fi

  RESULTS+="\"$name\":{\"size_bytes\":$delta,\"method\":\"pip_install_delta\",\"description\":\"pip install $package size delta\"}"

  # Clean up venv to save disk
  rm -rf "$venv_dir"
}

measure_binary() {
  local name="$1"
  local binary="$2"
  local method="$3"

  local binary_path
  binary_path=$(command -v "$binary" 2>/dev/null || echo "")

  if [ -z "$binary_path" ]; then
    echo "  $name: binary '$binary' not found, skipping" >&2
    return 1
  fi

  local size
  size=$(stat -f%z "$binary_path" 2>/dev/null || stat -c%s "$binary_path" 2>/dev/null || echo 0)
  echo "  $name: $size bytes" >&2

  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    RESULTS+=","
  fi

  RESULTS+="\"$name\":{\"size_bytes\":$size,\"method\":\"$method\",\"description\":\"$binary binary size\"}"
}

echo "=== Measuring Python framework disk sizes ===" >&2
for name in "${!PYTHON_PACKAGES[@]}"; do
  measure_python_package "$name" "${PYTHON_PACKAGES[$name]}" || true
done

echo "=== Measuring binary sizes ===" >&2
measure_binary "pandoc" "pandoc" "binary_size" || true

RESULTS+="}"

if [ "$OUTPUT_FILE" = "--" ]; then
  echo "$RESULTS"
else
  echo "$RESULTS" >"$OUTPUT_FILE"
  echo "Written to $OUTPUT_FILE" >&2
fi
