# PDF Extraction Roadmap (30/60/90)

## 30 Days

1. Define benchmark corpus and scoring harness.
- Build fixed sets for digital PDFs, scanned PDFs, mixed-layout PDFs, and multilingual PDFs.
- Track: table structure F1, cell text F1, header detection accuracy, OCR CER/WER.

2. Add quality gates in CI.
- Run a fast eval subset on every PR.
- Run full eval nightly and alert on statistically significant regressions.

3. Stabilize table-finder test behavior.
- Replace brittle exact-string checks with behavior-accurate assertions where extraction is intentionally split.
- Ensure deterministic settings for repeatable outcomes.

## 60 Days

1. Improve hard-table scenarios.
- Multi-page table stitching with repeated header detection.
- Better merged/split cell recovery and borderless table heuristics.

2. Improve OCR + native PDF text fusion.
- Prefer native text where reliable; fallback to OCR regionally.
- Emit confidence per block/table/cell.

3. Add layout semantics v1.
- Detect headings, lists, captions, and footnotes with bounding boxes.
- Link tables to nearby title/caption context.

## 90 Days

1. Ship production trust guarantees.
- Version extraction schema and document migration expectations.
- Add reproducibility checks across target platforms.

2. Performance and scale hardening.
- Add memory caps and timeout policies for large documents.
- Target p95 latency and throughput improvements per document class.

3. Security and robustness hardening.
- Expand malformed-PDF fuzz corpus and parser guardrails.
- Add regression suite for hostile/degenerate inputs.

## Recommended KPIs

1. `table_structure_f1`: target +5-10% on hard corpus.
2. `ocr_text_wer`: target 10-20% relative reduction on scanned corpus.
3. `p95_latency_per_10_page_pdf`: target 20% reduction.
4. Nightly regression rate: target near zero.
