# AGENTS.md

Fast entrypoint for agents working in this repository.

## Purpose

Use this file for quick orientation and command routing.
Use `.ai-rulez/` for detailed domain rules and deep implementation guidance.

## Source of Truth

- Rule composition config: `.ai-rulez/config.yaml`
- Repository-specific rules: `.ai-rulez/custom-rules.yaml`
- Profiles/routing/quality gates: `.ai-rulez/custom-profiles.yaml`
- Specialized skills: `.ai-rulez/skills/`
- Rule-to-check audit map: `.ai-rulez/rule-enforcement-map.md`

## Non-Negotiables

1. Use Task commands for language tests; do not bypass task orchestration.
2. Keep `.ai-rulez` path references in sync with real files.
3. Run drift check after modifying any `.ai-rulez` docs.
4. For extraction/OCR/plugin changes, run hardening checks before merge.
5. Do not add ignore entries to `.ai-rulez/drift-ignore-paths.txt` without justification.

## Quick Commands

### AI-rulez drift and hardening

```bash
scripts/ci/validate/check-ai-rulez-drift.sh
scripts/ci/validate/check-ai-rulez-hardening.sh
```

### Common test entrypoints

```bash
task rust:test
task python:test
task node:test
task go:test
task wasm:test
```

### Full lint/check surface

```bash
task lint
python scripts/verify_api_parity.py
```

## Task Routing

- Extraction pipeline and MIME routing:
  - `.ai-rulez/domains/document-extraction/DOMAIN.md`
  - `.ai-rulez/skills/extraction-pipeline-patterns/SKILL.md`
- OCR behavior and backends:
  - `.ai-rulez/domains/ocr-integration/DOMAIN.md`
  - `.ai-rulez/skills/ocr-backend-management/SKILL.md`
- Plugin architecture and fallback ordering:
  - `.ai-rulez/domains/plugin-system/DOMAIN.md`
  - `.ai-rulez/skills/plugin-architecture-patterns/SKILL.md`
- Test orchestration and environment setup:
  - `.ai-rulez/skills/test-execution-patterns/SKILL.md`

## CI and Automation Integration

- CI enforces hardening in `.github/workflows/ci-validate.yaml` via
  `scripts/ci/validate/check-ai-rulez-hardening.sh`.
- Hardening script includes the drift check, so one run covers both.
- Codex automations that run the hardening script automatically include drift validation.

## Shared Include Pinning

`.ai-rulez/config.yaml` currently references shared rules with `ref: main`.
For reproducibility across repositories, prefer pinning that `ref` to a release tag or commit hash.

