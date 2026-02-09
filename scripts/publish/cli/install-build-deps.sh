#!/usr/bin/env bash

set -euo pipefail

target="${CLI_TARGET:-}"

sudo apt-get update
case "$target" in
aarch64-unknown-linux-gnu)
  sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
  ;;
x86_64-unknown-linux-musl | aarch64-unknown-linux-musl)
  sudo apt-get install -y musl-tools g++

  # musl-tools only ships musl-gcc (C). clipper-sys and other crates that
  # compile C++ need a musl-g++ wrapper. We derive the specs-file path from
  # the installed musl-gcc script so this works on both x86_64 and aarch64.
  MUSL_GCC="$(command -v musl-gcc)"
  SPECS_FILE="$(sed -n 's/.*-specs[[:space:]]*"\?\([^"]*musl-gcc\.specs\)"\?.*/\1/p' "$MUSL_GCC" | head -1)"
  if [ -z "$SPECS_FILE" ]; then
    echo "ERROR: could not extract specs path from musl-gcc" >&2
    exit 1
  fi
  sudo tee /usr/local/bin/musl-g++ >/dev/null <<WRAPPER
#!/bin/sh
exec "\${REALCXX:-g++}" "\$@" -specs "$SPECS_FILE"
WRAPPER
  sudo chmod +x /usr/local/bin/musl-g++
  echo "Created musl-g++ wrapper using specs: $SPECS_FILE"
  ;;
*) ;;
esac
