#!/bin/bash

set -e

# This script sets up the built PHP extension for testing in development/CI environments.
# It finds the compiled extension and makes it available to PHP/PHPUnit.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
TARGET_DIR="$REPO_ROOT/target/release/deps"

echo "=== Setting up PHP extension for testing ==="
echo "Repo root: $REPO_ROOT"
echo "Target dir: $TARGET_DIR"
echo ""

# Determine the extension file based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  EXT_FILE="libkreuzberg_php.so"
  EXT_NAME="kreuzberg_php.so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  EXT_FILE="libkreuzberg_php.dylib"
  EXT_NAME="kreuzberg_php.so"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
  EXT_FILE="kreuzberg_php.dll"
  EXT_NAME="kreuzberg_php.dll"
else
  echo "Warning: Unknown OS type: $OSTYPE - assuming Linux"
  EXT_FILE="libkreuzberg_php.so"
  EXT_NAME="kreuzberg_php.so"
fi

BUILT_EXT="$TARGET_DIR/$EXT_FILE"

if [ ! -f "$BUILT_EXT" ]; then
  echo "ERROR: Built extension not found at $BUILT_EXT"
  echo ""
  echo "Available files in $TARGET_DIR:"
  find "$TARGET_DIR" -maxdepth 1 -iname "*kreuzberg*" -type f 2>/dev/null || echo "No kreuzberg files found"
  exit 1
fi

echo "Found built extension: $BUILT_EXT"
echo "Extension file size: $(du -h "$BUILT_EXT" | cut -f1)"
echo ""

# Get PHP extension directory
PHP_EXT_DIR=$(php-config --extension-dir 2>/dev/null || echo "")

if [ -z "$PHP_EXT_DIR" ] || [ ! -d "$PHP_EXT_DIR" ]; then
  echo "Warning: Could not determine PHP extension directory"
  echo "PHP extension directory: $PHP_EXT_DIR"
  echo "Extension will not be installed to system directory."
  echo ""
  echo "Extension is available at: $BUILT_EXT"
  echo "You can load it with: php -d extension=$BUILT_EXT"
  exit 0
fi

echo "PHP extension directory: $PHP_EXT_DIR"
echo ""

# Copy the extension to PHP's extension directory
echo "Copying extension to PHP extension directory..."
if sudo cp -f "$BUILT_EXT" "$PHP_EXT_DIR/$EXT_NAME"; then
  echo "✓ Extension copied successfully"
  echo ""
  echo "Verifying installation..."
  php -m | grep -i kreuzberg && echo "✓ Extension is loadable" || echo "✗ Extension not found in php -m"
else
  echo "✗ Failed to copy extension"
  exit 1
fi

echo ""
echo "=== Extension setup complete ==="
