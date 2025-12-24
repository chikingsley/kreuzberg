#!/usr/bin/env bash
# Install kreuzberg-ffi pre-built binaries for Go
#
# Downloads pre-built FFI binaries from GitHub releases with automatic fallback to
# building from source. Handles platform detection, extraction, and environment setup.
#
# Usage:
#   ./scripts/go/install-binaries.sh [OPTIONS]
#
# Options:
#   -t, --tag TAG                Release tag (default: auto-detect latest)
#   -d, --dest DEST              Installation destination (default: ~/.local)
#   --skip-build-fallback        Don't attempt to build from source if download fails
#   -v, --verbose                Verbose output
#   -h, --help                   Show this help message
#
# Environment:
#   KREUZBERG_INSTALL_DEST       Override installation destination
#   KREUZBERG_SKIP_BUILD         Skip build fallback
#
# Examples:
#   # Default: download to ~/.local with source build fallback
#   ./scripts/go/install-binaries.sh
#
#   # Install specific version to custom location
#   ./scripts/go/install-binaries.sh --tag v4.0.0 --dest /usr/local
#
#   # Download only, fail if not available
#   ./scripts/go/install-binaries.sh --skip-build-fallback -v

set -euo pipefail

# Color output
# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
# shellcheck disable=SC2034
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
tag=""
dest="${KREUZBERG_INSTALL_DEST:-}"
skip_build="${KREUZBERG_SKIP_BUILD:-false}"
verbose="false"

while [[ $# -gt 0 ]]; do
	case $1 in
	-t | --tag)
		tag="$2"
		shift 2
		;;
	-d | --dest)
		dest="$2"
		shift 2
		;;
	--skip-build-fallback)
		skip_build="true"
		shift
		;;
	-v | --verbose)
		verbose="true"
		shift
		;;
	-h | --help)
		head -28 "$0" | tail -n +2
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

# Build arguments for Go script
go_args=("-v" "scripts/go/download-binaries.go")
if [[ -n "$tag" ]]; then
	go_args+=("-tag" "$tag")
fi
if [[ -n "$dest" ]]; then
	go_args+=("-dest" "$dest")
fi
if [[ "$skip_build" == "true" ]]; then
	go_args+=("-skip-build-fallback")
fi
if [[ "$verbose" == "true" ]]; then
	go_args+=("-verbose")
fi

# Run Go script
if [[ "$verbose" == "true" ]]; then
	echo -e "${BLUE}Running: go run ${go_args[*]}${NC}"
fi

exec go run "${go_args[@]}"
