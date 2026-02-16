# AI-rulez Rule Enforcement Map

This map links high-impact rules to executable checks so enforcement is auditable.

## Scope

- Rule definitions live in:
  - `.ai-rulez/custom-rules.yaml`
  - `.ai-rulez/domains/*/rules.yaml`
- This file documents which checks currently enforce those rules.

## Enforced Rules

| Rule / Constraint | Rule Source | Enforcement Command | Where It Runs | Status |
|---|---|---|---|---|
| AI-rulez path/reference integrity | `.ai-rulez/*` docs and yaml | `scripts/ci/validate/check-ai-rulez-drift.sh` | Local + CI (`.github/workflows/ci-validate.yaml`) | Automated |
| `extraction-pipeline-architecture` and fallback ordering | `.ai-rulez/custom-rules.yaml` | `cargo test -p kreuzberg --lib document_extractor_get_all --features "pdf ocr bundled-pdfium"` | `scripts/ci/validate/check-ai-rulez-hardening.sh` | Automated |
| `plugin-system-abstraction` (priority/fallback safety) | `.ai-rulez/custom-rules.yaml` | `cargo test -p kreuzberg --lib document_extractor_get_all --features "pdf ocr bundled-pdfium"` | `scripts/ci/validate/check-ai-rulez-hardening.sh` | Automated |
| `ocr-backend-pluggability` and backend lifecycle behavior | `.ai-rulez/custom-rules.yaml` | `cargo test -p kreuzberg --test plugin_ocr_backend_test --features "pdf ocr bundled-pdfium"` | `scripts/ci/validate/check-ai-rulez-hardening.sh` | Automated |
| `hocr-parsing-and-table-extraction` regressions | `.ai-rulez/custom-rules.yaml` | `cargo test -p kreuzberg --test pdf_table_finder --features "pdf ocr bundled-pdfium" test_order_issue_336_multiple_tables` | `scripts/ci/validate/check-ai-rulez-hardening.sh` | Automated |
| `hocr-parsing-and-table-extraction` style strictness | `.ai-rulez/custom-rules.yaml` | `cargo test -p kreuzberg --test pdf_table_finder --features "pdf ocr bundled-pdfium" test_pymupdf_md_styles_strict` | `scripts/ci/validate/check-ai-rulez-hardening.sh` | Automated |
| API parity expectations | API contract checks | `python scripts/verify_api_parity.py` | CI validate workflow | Automated |
| `test-execution-patterns` (`task <lang>:test` orchestration) | `.ai-rulez/skills/test-execution-patterns/SKILL.md` | `task <language>:test` (for touched languages) | Local dev workflow | Process-enforced |

## Audit Notes

- The hardening runner includes drift as a first step:
  - `scripts/ci/validate/check-ai-rulez-hardening.sh`
- If you add/rename rules, update this map in the same change.
- If you add new hardening tests, wire them into:
  - `scripts/ci/validate/check-ai-rulez-hardening.sh`
  - `.github/workflows/ci-validate.yaml`

