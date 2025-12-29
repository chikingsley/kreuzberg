# Changelog

All notable changes to the Kreuzberg PHP package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0-rc.21] - 2025-12-29

### Added

**Factory Methods (NEW)**
- `fromArray()` - Create config objects from associative arrays with key mapping
- `fromJson()` - Create config objects from JSON strings with validation
- `fromFile()` - Load config objects from JSON files with error handling
- Supported on all configuration classes for flexible instantiation

**Configuration Serialization (NEW)**
- `toArray()` - Convert config objects to associative arrays
- `toJson()` - Convert config objects to formatted JSON strings
- Enables config persistence and round-trip conversion

**New Configuration Classes**
- `HierarchyConfig` - Hierarchy detection and clustering (enabled, kClusters, includeBbox, ocrCoverageThreshold)
- `TokenReductionConfig` - Token reduction for embeddings (mode, preserveImportantWords)
- `PostProcessorConfig` - Post-processing pipeline configuration

**Documentation**
- Enhanced README with factory method examples
- Configuration usage patterns and best practices
- JSON configuration file examples
- Type-safe API documentation

**Testing**
- Complete PHPUnit test suites for all config classes
- Factory method tests covering array, JSON, and file operations
- Round-trip conversion tests (object -> JSON -> object)
- Error handling and edge case tests

### Changed
- Improved configuration hierarchy for nested objects
- Consistent naming convention for serialized keys (snake_case)
- Better error messages for invalid JSON/file inputs

### Fixed
- JSON encoding/decoding with proper error handling
- File access validation before reading configs
- Null property filtering in array/JSON output
- Type coercion for configuration values

### Notes
- Requires PHP 8.2+
- Requires Kreuzberg PHP extension (kreuzberg.so/.dll)
- Optional dependencies: Tesseract OCR, ONNX Runtime
- Full type hints with readonly classes
- PSR-4 autoloading
- Compatible with Kreuzberg 4.0.0-rc.21 core

## [4.0.0-rc.20] - 2025-12-26

### Added
- Initial PHP package structure
- Main `Kreuzberg` class for OOP API
- Procedural API functions (`extract_file`, `extract_bytes`, etc.)
- Complete configuration classes:
  - `ExtractionConfig` - Main extraction configuration
  - `OcrConfig` - OCR settings
  - `TesseractConfig` - Tesseract-specific options
  - `ImagePreprocessingConfig` - Image preprocessing options
  - `PdfConfig` - PDF extraction settings
  - `ChunkingConfig` - Text chunking configuration
  - `EmbeddingConfig` - Embedding generation settings
  - `ImageExtractionConfig` - Image extraction settings
  - `PageConfig` - Page extraction settings
  - `LanguageDetectionConfig` - Language detection settings
  - `KeywordConfig` - Keyword extraction settings
- Type-safe result classes:
  - `ExtractionResult` - Main extraction result
  - `Metadata` - Document metadata
  - `Table` - Extracted table structure
  - `Chunk` - Text chunk with embedding
  - `ChunkMetadata` - Chunk offset metadata
  - `ExtractedImage` - Extracted image with OCR
  - `PageContent` - Per-page content
- Exception handling with `KreuzbergException`
- Extension function stubs for IDE support
- Comprehensive README with examples
- Example files demonstrating all features
- PHPStan configuration (level: max)
- PHP CS Fixer configuration
- PHPUnit configuration
- MIT License

### Notes
- Requires PHP 8.2+
- Requires Kreuzberg PHP extension (kreuzberg.so/.dll)
- Optional dependencies: Tesseract OCR, ONNX Runtime
- Full type hints with readonly classes
- PSR-4 autoloading
- Compatible with Kreuzberg 4.0.0-rc.20 core
