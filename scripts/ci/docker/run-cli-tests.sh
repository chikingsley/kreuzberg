#!/usr/bin/env bash
set -euo pipefail

echo "=== Running Docker CLI feature tests ==="
./scripts/test_docker_cli.sh --skip-build --image "kreuzberg:cli" --verbose
