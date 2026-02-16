#!/usr/bin/env bash
set -euo pipefail

FEATURES="${AI_RULEZ_CHECK_FEATURES:-pdf ocr bundled-pdfium}"

echo "=== AI-rulez hardening checks ===" >&2
echo "Using Cargo features: ${FEATURES}" >&2

# Keep AI-rulez references aligned with the repo layout.
scripts/ci/validate/check-ai-rulez-drift.sh

# Plugin registry priority/fallback ordering guarantees.
cargo test -p kreuzberg --lib document_extractor_get_all --features "${FEATURES}"

# OCR backend pluggability and error-surface invariants.
cargo test -p kreuzberg --test plugin_ocr_backend_test --features "${FEATURES}"

# PDF table extraction regressions tied to table detection behavior.
cargo test -p kreuzberg --test pdf_table_finder --features "${FEATURES}" test_order_issue_336_multiple_tables
cargo test -p kreuzberg --test pdf_table_finder --features "${FEATURES}" test_pymupdf_md_styles_strict

echo "AI-rulez hardening checks passed." >&2
