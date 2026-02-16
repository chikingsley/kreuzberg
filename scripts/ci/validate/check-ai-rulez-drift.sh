#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

RULES_DIR=".ai-rulez"
IGNORE_FILE="$RULES_DIR/drift-ignore-paths.txt"
PATH_PATTERN='(crates|packages|scripts|tests|tools|\.task)/[A-Za-z0-9_./-]+'

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: ripgrep (rg) is required for AI-rulez drift checks." >&2
  exit 1
fi

refs_file="$(mktemp)"
filtered_file="$(mktemp)"
ignore_active_file="$(mktemp)"
missing_file="$(mktemp)"
trap 'rm -f "$refs_file" "$filtered_file" "$ignore_active_file" "$missing_file"' EXIT

rg -o --no-filename "$PATH_PATTERN" "$RULES_DIR" \
  --glob '*.md' \
  --glob '*.yaml' \
  --glob '*.yml' \
  | sort -u > "$refs_file"

cp "$refs_file" "$filtered_file"

if [ -f "$IGNORE_FILE" ]; then
  grep -vE '^[[:space:]]*(#|$)' "$IGNORE_FILE" > "$ignore_active_file" || true
  if [ -s "$ignore_active_file" ]; then
    grep -Fxv -f "$ignore_active_file" "$refs_file" > "$filtered_file" || true
  fi
fi

total=0
missing=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  total=$((total + 1))
  if [ ! -e "$ref" ]; then
    printf '%s\n' "$ref" >> "$missing_file"
    missing=$((missing + 1))
  fi
done < "$filtered_file"

if [ "$missing" -gt 0 ]; then
  echo "AI-rulez drift check failed: ${missing} missing path reference(s) out of ${total}." >&2
  echo "Missing references:" >&2
  sed 's/^/  - /' "$missing_file" >&2
  printf '\nIf a reference is intentional and not a filesystem path, add it to %s.\n' "$IGNORE_FILE" >&2
  exit 1
fi

echo "AI-rulez drift check passed (${total} path references validated)." >&2
