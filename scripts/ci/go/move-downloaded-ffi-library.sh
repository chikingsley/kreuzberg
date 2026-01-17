#!/usr/bin/env bash
set -euo pipefail

# Validate that ffi-download directory exists
if [ ! -d "ffi-download" ]; then
  echo "✗ Error: ffi-download directory not found"
  exit 1
fi

mkdir -p target/release
mkdir -p target/x86_64-pc-windows-gnu/release
mkdir -p packages/go/v4/internal/ffi
mkdir -p crates/kreuzberg-ffi

echo "Moving FFI artifacts from ffi-download..."
echo ""

# Move library files
LIBRARY_COUNT=0
find ffi-download -type f \( -name "libkreuzberg_ffi.*" -o -name "kreuzberg_ffi.*" \) | while read -r file; do
  filename="$(basename "$file")"
  if [[ "$file" == *"x86_64-pc-windows-gnu"* ]]; then
    cp "$file" target/x86_64-pc-windows-gnu/release/
    echo "✓ Copied $filename to target/x86_64-pc-windows-gnu/release/"
  else
    cp "$file" target/release/
    echo "✓ Copied $filename to target/release/"
  fi
  ((LIBRARY_COUNT++)) || true
done

if [ "$LIBRARY_COUNT" -eq 0 ]; then
  echo "⚠ Warning: No FFI library files found in ffi-download (may be a cross-platform build artifact)"
fi

# Copy header file to Go package
if [ -f "ffi-download/kreuzberg.h" ]; then
  cp ffi-download/kreuzberg.h packages/go/v4/internal/ffi/
  echo "✓ Copied kreuzberg.h to packages/go/v4/internal/ffi/"

  # Verify header was copied
  if [ ! -f "packages/go/v4/internal/ffi/kreuzberg.h" ]; then
    echo "✗ Error: Failed to copy kreuzberg.h to packages/go/v4/internal/ffi/"
    exit 1
  fi
else
  echo "✗ Error: Header file kreuzberg.h not found in ffi-download"
  echo "   Contents of ffi-download:"
  ls -la ffi-download/ || echo "   (unable to list directory)"
  exit 1
fi

# Copy pkg-config file
if [ -f "ffi-download/kreuzberg-ffi.pc" ]; then
  cp ffi-download/kreuzberg-ffi.pc crates/kreuzberg-ffi/
  echo "✓ Copied kreuzberg-ffi.pc to crates/kreuzberg-ffi/"
else
  echo "⚠ Warning: pkg-config file kreuzberg-ffi.pc not found in ffi-download"
fi

echo ""
echo "Cleaning up ffi-download directory..."
rm -rf ffi-download
echo "✓ Done"
