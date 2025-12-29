# Elixir Binding for Kreuzberg

<div align="center" style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 20px 0;">
  <!-- Language Bindings -->
  <a href="https://crates.io/crates/kreuzberg">
    <img src="https://img.shields.io/crates/v/kreuzberg?label=Rust&color=007ec6" alt="Rust">
  </a>
  <a href="https://hex.pm/packages/kreuzberg">
    <img src="https://img.shields.io/hexpm/v/kreuzberg?label=Elixir&color=007ec6" alt="Elixir">
  </a>
  <a href="https://pypi.org/project/kreuzberg/">
    <img src="https://img.shields.io/pypi/v/kreuzberg?label=Python&color=007ec6" alt="Python">
  </a>
  <a href="https://www.npmjs.com/package/@kreuzberg/node">
    <img src="https://img.shields.io/npm/v/@kreuzberg/node?label=Node.js&color=007ec6" alt="Node.js">
  </a>
  <a href="https://www.npmjs.com/package/@kreuzberg/wasm">
    <img src="https://img.shields.io/npm/v/@kreuzberg/wasm?label=WASM&color=007ec6" alt="WASM">
  </a>

<a href="https://central.sonatype.com/artifact/dev.kreuzberg/kreuzberg">
    <img src="https://img.shields.io/maven-central/v/dev.kreuzberg/kreuzberg?label=Java&color=007ec6" alt="Java">
  </a>
  <a href="https://github.com/kreuzberg-dev/kreuzberg/releases">
    <img src="https://img.shields.io/github/v/tag/kreuzberg-dev/kreuzberg?label=Go&color=007ec6&filter=v4.0.0-*" alt="Go">
  </a>
  <a href="https://www.nuget.org/packages/Kreuzberg/">
    <img src="https://img.shields.io/nuget/v/Kreuzberg?label=C%23&color=007ec6" alt="C#">
  </a>
  <a href="https://packagist.org/packages/kreuzberg/kreuzberg">
    <img src="https://img.shields.io/packagist/v/kreuzberg/kreuzberg?label=PHP&color=007ec6" alt="PHP">
  </a>
  <a href="https://rubygems.org/gems/kreuzberg">
    <img src="https://img.shields.io/gem/v/kreuzberg?label=Ruby&color=007ec6" alt="Ruby">
  </a>

<!-- Project Info -->

<a href="https://github.com/kreuzberg-dev/kreuzberg/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  </a>
  <a href="https://docs.kreuzberg.dev">
    <img src="https://img.shields.io/badge/docs-kreuzberg.dev-blue" alt="Documentation">
  </a>
</div>

<img width="1128" height="191" alt="Banner2" src="https://github.com/user-attachments/assets/419fc06c-8313-4324-b159-4b4d3cfce5c0" />

<div align="center" style="margin-top: 20px;">
  <a href="https://discord.gg/pXxagNK2zN">
      <img height="22" src="https://img.shields.io/badge/Discord-Join%20our%20community-7289da?logo=discord&logoColor=white" alt="Discord">
  </a>
</div>

Extract text, tables, images, and metadata from 56+ file formats. The Elixir binding provides idiomatic API, native BEAM concurrency, Rustler NIF integration, OTP supervision, and comprehensive E2E testing with zero flakiness.

> **Version 4.0.0 Release Candidate**
> Kreuzberg v4.0.0 is in **Release Candidate** stage. Bugs and breaking changes are expected.
> This is a pre-release version. Please test the library and [report any issues](https://github.com/kreuzberg-dev/kreuzberg/issues) you encounter.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Usage Patterns](#usage-patterns)
- [E2E Workflow](#e2e-workflow)
- [NIF Integration](#nif-integration)
- [Features](#features)
- [Configuration](#configuration)
- [Testing](#testing)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

## Installation

### Via Hex Package Manager

Add to your `mix.exs` dependencies:

```elixir
def deps do
  [
    kreuzberg: "~> 4.0"
  ]
end
```

Then run:

```bash
mix deps.get
```

The package will automatically compile the Rust NIF using Rustler precompiled binaries.

### System Requirements

- **Elixir 1.14+** and **Erlang/OTP 24+**
- C compiler (gcc, clang, or MSVC)
- Optional: [ONNX Runtime](https://github.com/microsoft/onnxruntime/releases) version 1.21 or lower for embeddings support
- Optional: [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) for OCR functionality

### Native Build

If precompiled binaries are unavailable for your platform, Rustler will automatically compile from source:

```bash
# Install Rust if not already installed
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build the project
mix compile
```

## Architecture

The Elixir binding uses Rustler to safely call high-performance Rust code from Erlang/OTP:

```
┌─────────────────────────────────────┐
│   Elixir Application (Idiomatic)    │
│  - Pattern matching on {:ok, result}│
│  - Task-based async concurrency     │
│  - OTP supervisor integration       │
└────────────┬────────────────────────┘
             │
      Rustler NIF Boundary
       (Safe term exchange)
             │
┌────────────▼────────────────────────┐
│  Rust Native Implementation         │
│  - High-performance extraction      │
│  - Memory-safe term handling        │
│  - Native concurrency support       │
└─────────────────────────────────────┘
```

Key design principles:

- **Safety**: NIF boundary crossing is automatically validated
- **Concurrency**: BEAM scheduler handles concurrent calls without blocking
- **Memory**: Rust manages memory; Elixir handles distribution and caching
- **Idiomatic**: Elixir patterns like `{:ok, result}` and `{:error, reason}` throughout

## Quick Start

### Basic Extraction with Error Handling

Extract text from files with idiomatic Elixir error handling:

```elixir
# Simple extraction with pattern matching
case Kreuzberg.extract_file("document.pdf") do
  {:ok, result} ->
    IO.puts("Content: #{result.content}")
    IO.puts("Tables: #{length(result.tables)}")
    IO.puts("Pages: #{length(result.pages)}")

  {:error, reason} ->
    IO.puts("Extraction failed: #{reason}")
end
```

### Binary Data Extraction

Extract from bytes instead of files:

```elixir
# Process binary data directly
pdf_binary = File.read!("document.pdf")

{:ok, result} = Kreuzberg.extract(pdf_binary, "application/pdf")

IO.puts("Extracted #{byte_size(result.content)} bytes of content")
IO.puts("Detected language: #{inspect(result.detected_languages)}")
```

## Usage Patterns

### Pattern 1: Synchronous Extraction

Blocking call, simple and straightforward:

```elixir
{:ok, result} = Kreuzberg.extract_file("document.pdf")
# or handle error
case Kreuzberg.extract_file("document.pdf") do
  {:ok, result} -> process_result(result)
  {:error, reason} -> log_error(reason)
end
```

### Pattern 2: Asynchronous Extraction with Task

Non-blocking extraction using BEAM tasks:

```elixir
# Spawn extraction in background
task = Kreuzberg.extract_async("document.pdf")

# Do other work...
do_other_work()

# Collect result when ready
{:ok, result} = Task.await(task, 30_000)
```

### Pattern 3: Concurrent Batch Processing

Process multiple files concurrently:

```elixir
files = ["file1.pdf", "file2.pdf", "file3.pdf"]

results =
  files
  |> Enum.map(&Task.async(fn -> Kreuzberg.extract_file(&1) end))
  |> Task.await_many(30_000)

# results is list of {:ok, result} or {:error, reason}
successful =
  Enum.filter(results, &match?({:ok, _}, &1))
  |> Enum.map(fn {:ok, result} -> result end)

IO.puts("Processed #{length(successful)}/#{length(files)} files")
```

### Pattern 4: Batch API for Optimal Performance

Use batch extraction for multiple files with internal optimization:

```elixir
files = ["file1.pdf", "file2.pdf", "file3.pdf"]

{:ok, results} = Kreuzberg.batch_extract_files(files)

Enum.each(results, fn result ->
  IO.puts("File: #{result.mime_type}")
  IO.puts("Content length: #{byte_size(result.content)}")
end)
```

## E2E Workflow

The Elixir binding includes comprehensive end-to-end tests covering real-world scenarios.

### NIF Boundary Safety

Tests verify safe Erlang term exchange across the NIF boundary:

```elixir
# Unicode, binary data, and null bytes all cross safely
unicode_text = "Hello 你好 مرحبا שלום"
{:ok, result} = Kreuzberg.extract(unicode_text, "text/plain")
assert result.content == unicode_text  # Perfect round-trip

# Large data (10MB+) handled without crashes
large_binary = String.duplicate("X", 10_000_000)
{:ok, result} = Kreuzberg.extract(large_binary, "text/plain")
assert byte_size(result.content) > 0
```

### Concurrent Safety

High concurrency tested without deadlocks:

```elixir
# 50 concurrent NIF calls complete successfully
tasks = Enum.map(1..50, fn i ->
  Task.async(fn -> Kreuzberg.extract("Task #{i}", "text/plain") end)
end)

results = Task.await_many(tasks, 60_000)
assert length(results) == 50  # All completed
assert Enum.all?(results, &match?({:ok, _}, &1))  # All successful
```

### Memory Safety

Extraction doesn't cause resource leaks or excessive memory growth:

```elixir
initial_memory = Process.info(self(), :memory) |> elem(1)

# 100 extractions
Enum.each(1..100, fn i ->
  {:ok, _result} = Kreuzberg.extract("Test #{i}", "text/plain")
end)

:erlang.garbage_collect()
final_memory = Process.info(self(), :memory) |> elem(1)

# Memory should not grow unbounded
assert final_memory <= initial_memory * 5
```

### Error Recovery

NIF errors don't crash the VM; extraction continues normally:

```elixir
# Invalid MIME type returns error
{:error, reason} = Kreuzberg.extract("data", "invalid/type")
assert is_binary(reason)

# Next call works normally
{:ok, result} = Kreuzberg.extract("valid", "text/plain")
assert result.content == "valid"
```

## Common Use Cases

### Extract with Custom Configuration

Most use cases benefit from configuration to control extraction behavior:

**With OCR (for scanned documents):**

```elixir
alias Kreuzberg.ExtractionConfig

config = %ExtractionConfig{
  ocr: %{"enabled" => true, "backend" => "tesseract"}
}

{:ok, result} = Kreuzberg.extract_file("scanned_document.pdf", nil, config)

content = result.content
IO.puts("OCR Extracted content:")
IO.puts(content)
IO.puts("Metadata: #{inspect(result.metadata)}")
```

#### Table Extraction

See [Table Extraction Guide](https://kreuzberg.dev/features/table-extraction/) for detailed examples.

#### Processing Multiple Files

```elixir title="Elixir"
file_paths = ["document1.pdf", "document2.pdf", "document3.pdf"]

{:ok, results} = Kreuzberg.batch_extract_files(file_paths)

Enum.each(results, fn result ->
  IO.puts("File: #{result.mime_type}")
  IO.puts("Content length: #{byte_size(result.content)} characters")
  IO.puts("Tables: #{length(result.tables)}")
  IO.puts("---")
end)

IO.puts("Total files processed: #{length(results)}")
```

#### Async Processing

For non-blocking document processing:

```elixir title="Elixir"
# Extract from different file types (PDF, DOCX, etc.)

case Kreuzberg.extract_file("document.pdf") do
  {:ok, result} ->
    IO.puts("Content: #{result.content}")
    IO.puts("MIME Type: #{result.metadata.format_type}")
    IO.puts("Tables: #{length(result.tables)}")

  {:error, reason} ->
    IO.puts("Extraction failed: #{inspect(reason)}")
end
```

### Next Steps

- **[Installation Guide](https://kreuzberg.dev/getting-started/installation/)** - Platform-specific setup
- **[API Documentation](https://kreuzberg.dev/api/)** - Complete API reference
- **[Examples & Guides](https://kreuzberg.dev/guides/)** - Full code examples and usage guides
- **[Configuration Guide](https://kreuzberg.dev/configuration/)** - Advanced configuration options
- **[Troubleshooting](https://kreuzberg.dev/troubleshooting/)** - Common issues and solutions

## Features

### Supported File Formats (56+)

56 file formats across 8 major categories with intelligent format detection and comprehensive metadata extraction.

#### Office Documents

| Category | Formats | Capabilities |
|----------|---------|--------------|
| **Word Processing** | `.docx`, `.odt` | Full text, tables, images, metadata, styles |
| **Spreadsheets** | `.xlsx`, `.xlsm`, `.xlsb`, `.xls`, `.xla`, `.xlam`, `.xltm`, `.ods` | Sheet data, formulas, cell metadata, charts |
| **Presentations** | `.pptx`, `.ppt`, `.ppsx` | Slides, speaker notes, images, metadata |
| **PDF** | `.pdf` | Text, tables, images, metadata, OCR support |
| **eBooks** | `.epub`, `.fb2` | Chapters, metadata, embedded resources |

#### Images (OCR-Enabled)

| Category | Formats | Features |
|----------|---------|----------|
| **Raster** | `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.tiff`, `.tif` | OCR, table detection, EXIF metadata, dimensions, color space |
| **Advanced** | `.jp2`, `.jpx`, `.jpm`, `.mj2`, `.pnm`, `.pbm`, `.pgm`, `.ppm` | OCR, table detection, format-specific metadata |
| **Vector** | `.svg` | DOM parsing, embedded text, graphics metadata |

#### Web & Data

| Category | Formats | Features |
|----------|---------|----------|
| **Markup** | `.html`, `.htm`, `.xhtml`, `.xml`, `.svg` | DOM parsing, metadata (Open Graph, Twitter Card), link extraction |
| **Structured Data** | `.json`, `.yaml`, `.yml`, `.toml`, `.csv`, `.tsv` | Schema detection, nested structures, validation |
| **Text & Markdown** | `.txt`, `.md`, `.markdown`, `.rst`, `.org`, `.rtf` | CommonMark, GFM, reStructuredText, Org Mode |

#### Email & Archives

| Category | Formats | Features |
|----------|---------|----------|
| **Email** | `.eml`, `.msg` | Headers, body (HTML/plain), attachments, threading |
| **Archives** | `.zip`, `.tar`, `.tgz`, `.gz`, `.7z` | File listing, nested archives, metadata |

#### Academic & Scientific

| Category | Formats | Features |
|----------|---------|----------|
| **Citations** | `.bib`, `.biblatex`, `.ris`, `.enw`, `.csl` | Bibliography parsing, citation extraction |
| **Scientific** | `.tex`, `.latex`, `.typst`, `.jats`, `.ipynb`, `.docbook` | LaTeX, Jupyter notebooks, PubMed JATS |
| **Documentation** | `.opml`, `.pod`, `.mdoc`, `.troff` | Technical documentation formats |

**[Complete Format Reference](https://kreuzberg.dev/reference/formats/)**

### Key Capabilities

- **Text Extraction** - Extract all text content with position and formatting information

- **Metadata Extraction** - Retrieve document properties, creation date, author, etc.

- **Table Extraction** - Parse tables with structure and cell content preservation

- **Image Extraction** - Extract embedded images and render page previews

- **OCR Support** - Integrate multiple OCR backends for scanned documents

- **Async/Await** - Non-blocking document processing with concurrent operations

- **Plugin System** - Extensible post-processing for custom text transformation

- **Embeddings** - Generate vector embeddings using ONNX Runtime models

- **Batch Processing** - Efficiently process multiple documents in parallel

- **Memory Efficient** - Stream large files without loading entirely into memory

- **Language Detection** - Detect and support multiple languages in documents

- **Configuration** - Fine-grained control over extraction behavior

### Performance Characteristics

| Format | Speed | Memory | Notes |
|--------|-------|--------|-------|
| **PDF (text)** | 10-100 MB/s | ~50MB per doc | Fastest extraction |
| **Office docs** | 20-200 MB/s | ~100MB per doc | DOCX, XLSX, PPTX |
| **Images (OCR)** | 1-5 MB/s | Variable | Depends on OCR backend |
| **Archives** | 5-50 MB/s | ~200MB per doc | ZIP, TAR, etc. |
| **Web formats** | 50-200 MB/s | Streaming | HTML, XML, JSON |

## OCR Support

Kreuzberg supports multiple OCR backends for extracting text from scanned documents and images:

- **Tesseract**

### OCR Configuration Example

```elixir title="Elixir"
alias Kreuzberg.ExtractionConfig

config = %ExtractionConfig{
  ocr: %{"enabled" => true, "backend" => "tesseract"}
}

{:ok, result} = Kreuzberg.extract_file("scanned_document.pdf", nil, config)

content = result.content
IO.puts("OCR Extracted content:")
IO.puts(content)
IO.puts("Metadata: #{inspect(result.metadata)}")
```

## Async Support

This binding provides full async/await support for non-blocking document processing:

```elixir title="Elixir"
# Extract from different file types (PDF, DOCX, etc.)

case Kreuzberg.extract_file("document.pdf") do
  {:ok, result} ->
    IO.puts("Content: #{result.content}")
    IO.puts("MIME Type: #{result.metadata.format_type}")
    IO.puts("Tables: #{length(result.tables)}")

  {:error, reason} ->
    IO.puts("Extraction failed: #{inspect(reason)}")
end
```

## Plugin System

Kreuzberg supports extensible post-processing plugins for custom text transformation and filtering.

For detailed plugin documentation, visit [Plugin System Guide](https://kreuzberg.dev/plugins/).

### Plugin Example

```elixir title="Elixir"
alias Kreuzberg.Plugin

# Word Count Post-Processor Plugin
# This post-processor automatically counts words in extracted content
# and adds the word count to the metadata.

defmodule MyApp.Plugins.WordCountProcessor do
  @behaviour Kreuzberg.Plugin.PostProcessor
  require Logger

  @impl true
  def name do
    "WordCountProcessor"
  end

  @impl true
  def processing_stage do
    :post
  end

  @impl true
  def version do
    "1.0.0"
  end

  @impl true
  def initialize do
    :ok
  end

  @impl true
  def shutdown do
    :ok
  end

  @impl true
  def process(result, _options) do
    content = result["content"] || ""
    word_count = content
      |> String.split(~r/\s+/, trim: true)
      |> length()

    # Update metadata with word count
    metadata = Map.get(result, "metadata", %{})
    updated_metadata = Map.put(metadata, "word_count", word_count)

    {:ok, Map.put(result, "metadata", updated_metadata)}
  end
end

# Register the word count post-processor
Plugin.register_post_processor(:word_count_processor, MyApp.Plugins.WordCountProcessor)

# Example usage
result = %{
  "content" => "The quick brown fox jumps over the lazy dog. This is a sample document with multiple words.",
  "metadata" => %{
    "source" => "document.pdf",
    "pages" => 1
  }
}

case MyApp.Plugins.WordCountProcessor.process(result, %{}) do
  {:ok, processed_result} ->
    word_count = processed_result["metadata"]["word_count"]
    IO.puts("Word count added: #{word_count} words")
    IO.inspect(processed_result, label: "Processed Result")

  {:error, reason} ->
    IO.puts("Processing failed: #{reason}")
end

# List all registered post-processors
{:ok, processors} = Plugin.list_post_processors()
IO.inspect(processors, label: "Registered Post-Processors")
```

## Embeddings Support

Generate vector embeddings for extracted text using the built-in ONNX Runtime support. Requires ONNX Runtime installation.

**[Embeddings Guide](https://kreuzberg.dev/features/#embeddings)**

## NIF Integration

### Rustler NIF Architecture

The binding is implemented as a Rustler NIF (Native Implemented Function) for safe boundary crossing:

```
Elixir Code
    ↓
Kreuzberg Module (lib/kreuzberg.ex)
    ↓
Rustler NIF Interface (native/src/lib.rs)
    ↓
Rust Implementation (kreuzberg_core)
    ↓
High-Performance Document Extraction
```

Key NIF patterns:

**Synchronous NIF calls:**
```elixir
# Directly calls Rust through NIF boundary
{:ok, result} = Kreuzberg.extract(data, mime_type, config)
```

**Error handling at boundary:**
```elixir
case Kreuzberg.extract(data, "invalid/type") do
  {:ok, result} -> result
  {:error, reason} -> IO.puts("NIF error: #{reason}")
end
```

### Memory Management Across Boundary

- **Erlang terms**: Automatically encoded/decoded by Rustler
- **Binary data**: Zero-copy where possible, bounds checked
- **Structures**: Complex structs serialized to maps for Elixir compatibility
- **GC integration**: Rust allocations cleaned up when Elixir terms are garbage collected

### Concurrent NIF Access

The NIF implementation is designed for concurrent access:

```elixir
# Multiple processes can call NIF simultaneously without blocking each other
task1 = Task.async(fn -> Kreuzberg.extract("data1", "text/plain") end)
task2 = Task.async(fn -> Kreuzberg.extract("data2", "text/plain") end)

{:ok, result1} = Task.await(task1)
{:ok, result2} = Task.await(task2)
```

## Batch Processing

Process multiple documents efficiently:

```elixir
file_paths = ["document1.pdf", "document2.pdf", "document3.pdf"]

{:ok, results} = Kreuzberg.batch_extract_files(file_paths)

Enum.each(results, fn result ->
  IO.puts("File: #{result.mime_type}")
  IO.puts("Content length: #{byte_size(result.content)} characters")
  IO.puts("Tables: #{length(result.tables)}")
  IO.puts("---")
end)

IO.puts("Total files processed: #{length(results)}")
```

## Configuration

For advanced configuration options including language detection, table extraction, OCR settings, and more:

**[Configuration Guide](https://kreuzberg.dev/configuration/)**

## Testing

The Elixir binding includes comprehensive test suites ensuring production-ready quality:

### Test Structure

```
test/
├── unit/                          # Unit tests (583 total)
│   ├── extraction_test.exs        # Core extraction functions
│   ├── batch_api_test.exs         # Batch operations
│   ├── async_api_test.exs         # Async Task patterns
│   ├── error_test.exs             # Error handling
│   ├── validators_test.exs        # Configuration validation
│   └── ...
├── e2e/                           # End-to-end tests
│   ├── nif_integration_test.exs   # NIF boundary safety (47 tests)
│   ├── pdf_extraction_test.exs    # Real PDF extraction
│   ├── html_extraction_test.exs   # HTML parsing
│   ├── table_extraction_test.exs  # Table detection
│   └── ...
└── support/
    └── document_fixtures.exs      # Test data generators
```

### Running Tests

```bash
# Run all tests
mix test

# Run only unit tests
mix test test/unit

# Run only E2E tests
mix test test/e2e

# Run with coverage
mix coveralls

# Run specific test file
mix test test/e2e/nif_integration_test.exs

# Run with tags
mix test --only :e2e
```

### Test Highlights

**NIF Integration Tests** (47 comprehensive tests):
- NIF boundary crossing safety with unicode, binary, and large data
- Concurrent NIF calls (up to 50 simultaneous)
- Memory safety and leak detection
- Error propagation and recovery
- OTP supervisor integration

**End-to-End Tests** (4 test suites):
- Real document extraction workflows
- Multi-format extraction (PDF, HTML, tables)
- Configuration variations and error conditions
- Performance and stability assertions

**Zero Flakiness**:
- All tests marked with `@tag :e2e` or `@tag :unit`
- Deterministic assertions without timing assumptions
- Resource cleanup and proper process management
- No external service dependencies

## Documentation

- **[Official Documentation](https://kreuzberg.dev/)**
- **[API Reference](https://kreuzberg.dev/reference/api-elixir/)**
- **[Examples & Guides](https://kreuzberg.dev/guides/)**
- **[Rustler Documentation](https://hexdocs.pm/rustler/)**

## Troubleshooting

### Common Issues

**Compilation errors with NIF:**
```bash
# Clean and rebuild
mix clean
mix compile
```

**Memory usage spikes:**
- Use batch processing for large files
- Call `:erlang.garbage_collect()` after large extractions
- Monitor process memory with `Process.info(self(), :memory)`

**Timeout errors:**
```elixir
# Increase timeout for large documents
{:ok, result} = Kreuzberg.extract_file("large.pdf")
# Max timeout is configured per operation
```

For detailed troubleshooting: [Troubleshooting Guide](https://kreuzberg.dev/troubleshooting/)

## Contributing

Contributions are welcome! See [Contributing Guide](https://github.com/kreuzberg-dev/kreuzberg/blob/main/CONTRIBUTING.md).

Development setup:
```bash
git clone https://github.com/kreuzberg-dev/kreuzberg.git
cd packages/elixir
mix deps.get
mix test
```

## License

MIT License - see LICENSE file for details.

## Support

- **Discord Community**: [Join our Discord](https://discord.gg/pXxagNK2zN)
- **GitHub Issues**: [Report bugs](https://github.com/kreuzberg-dev/kreuzberg/issues)
- **Discussions**: [Ask questions](https://github.com/kreuzberg-dev/kreuzberg/discussions)
