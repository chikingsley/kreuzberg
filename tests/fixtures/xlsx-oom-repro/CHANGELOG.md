# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.2.2] - 2026-01-27

### Fixed

#### Rust Core
- **XLSX OOM with Excel Solver files**: Fixed out-of-memory issue when processing XLSX files with sparse data at extreme cell positions ([#331](https://github.com/kreuzberg-dev/kreuzberg/issues/331))
  - Excel Solver add-in stores configuration in cells at extreme positions (XFD1048550-1048575 = column 16384, rows near 1M)
  - Calamine's `Range::from_sparse()` was allocating memory for the entire bounding box (16384 columns × 1048575 rows = 17 billion cells) even though actual data was only ~26 cells
  - Added streaming cell reader to detect pathological bounding boxes (>100M cells) before allocation
  - For sparse sheets with extreme dimensions, generate list-format markdown directly from cell stream
  - Normal sheets continue using the original fast path
  - Test file: 6.8KB with 26 cells, declared dimension A1:XFD1048575
  - Before: 100GB+ memory consumption, process killed
  - After: 901 char output, completes instantly

## [4.2.1] - 2026-01-27

**Patch Release: API Parity Fixes and CI Reliability Improvements**

### Fixed

#### Rust Core
- **PPTX image page numbers**: Fixed reversed page numbers when extracting images from PPTX files ([#329](https://github.com/kreuzberg-dev/kreuzberg/issues/329))
- **Plugin registry error logging**: Added comprehensive error logging for silent plugin failures ([#328](https://github.com/kreuzberg-dev/kreuzberg/issues/328))
- **Output format validation**: Extended `VALID_OUTPUT_FORMATS` to include all valid aliases
- **C# pre-commit hooks**: Added dotnet restore to format/lint check tasks
