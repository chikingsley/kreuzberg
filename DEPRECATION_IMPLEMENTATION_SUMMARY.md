# Deprecation Markers Implementation Summary

This document summarizes the deprecation markers added to C# and Elixir bindings in the Kreuzberg project.

## Overview

Deprecation markers have been implemented to help guide users from old APIs toward recommended alternatives. These markers appear in IDE IntelliSense, compiler warnings, and generated documentation.

## C# Implementation

### Files Created

1. **DeprecationExamples.cs** (`packages/csharp/Kreuzberg/DeprecationExamples.cs`)
   - Contains example deprecated functions and properties
   - Demonstrates proper use of `[Obsolete]` attribute

2. **DeprecationTests** (`tests/csharp_deprecation_test.cs`)
   - Unit tests verifying deprecation markers are properly applied
   - Tests verify attribute presence and message content

### Key Patterns

**Method Deprecation:**

```csharp
[Obsolete(
    "Use ExtractAsyncWithConfig() with ExtractionConfig.Ocr instead. " +
    "This method will be removed in v2.0.0.",
    error: false
)]
public static async Task<ExtractionResult> ExtractAsyncWithOcr(
    byte[] input,
    string mimeType,
    bool enableOcr = false
)
```

**Property Deprecation:**

```csharp
[Obsolete("Use ExtractionConfig.Ocr.Backend instead", error: false)]
public string? OcrBackend { get; init; }
```

**Extension Method Deprecation:**

```csharp
[Obsolete(
    "Set ExtractionConfig.EnableQualityProcessing directly instead. " +
    "This extension will be removed in v2.0.0.",
    error: false
)]
public static ExtractionConfig WithQualityProcessing(
    this ExtractionConfig config,
    bool enable
)
```

### Deprecation Attributes

- **error: false** - Generates CS0618 warning (default)
- **error: true** - Generates CS0619 error, prevents compilation

### Documentation Features

- Clear explanation in message string
- Alternative API suggestion
- Removal version specified
- Link to migration guide (when applicable)
- XML doc comments with `<remarks>` section

## Elixir Implementation

### Files Created

1. **LegacyAPI.ex** (`packages/elixir/lib/kreuzberg/legacy_api.ex`)
   - Contains deprecated functions using `@deprecated` attribute
   - Demonstrates proper Elixir deprecation patterns

2. **DeprecationTests** (`tests/elixir_deprecation_test.exs`)
   - ExUnit tests verifying deprecation implementation
   - Tests validate function exports, documentation, and behavior

### Key Patterns

**Simple Function Deprecation:**

```elixir
@deprecated "Use Kreuzberg.extract/3 with ExtractionConfig.ocr map instead. Removes in v2.0.0."
@spec extract_with_ocr(binary(), String.t(), boolean()) ::
        {:ok, ExtractionResult.t()} | {:error, String.t()}
def extract_with_ocr(input, mime_type, enable_ocr) do
  config = if enable_ocr do
    %ExtractionConfig{ocr: %{"enabled" => true, "backend" => "tesseract"}}
  else
    nil
  end
  Kreuzberg.extract(input, mime_type, config)
end
```

**Function with Comprehensive Documentation:**

```elixir
@doc """
Extract content with deprecated boolean OCR parameter.

This function is deprecated. Use `Kreuzberg.extract/3` with the new
`ExtractionConfig` structure containing an `ocr` nested configuration map.

## Deprecated

This function will be removed in v2.0.0. Use:

    config = %ExtractionConfig{ocr: %{"enabled" => true}}
    Kreuzberg.extract(input, mime_type, config)

## Examples

    # Deprecated way (old):
    {:ok, result} = Kreuzberg.LegacyAPI.extract_with_ocr(pdf_binary, "application/pdf", true)

    # Recommended way (new):
    config = %ExtractionConfig{ocr: %{"enabled" => true}}
    {:ok, result} = Kreuzberg.extract(pdf_binary, "application/pdf", config)
"""
@deprecated "Use Kreuzberg.extract/3 with ExtractionConfig.ocr map instead. Removes in v2.0.0."
def extract_with_ocr(input, mime_type, enable_ocr) do
  # implementation
end
```

### ExDoc Integration

The `@deprecated` attribute automatically:
- Adds "Deprecated" badge in generated docs
- Shows deprecation notice in function documentation
- Appears when viewing docs with `mix docs`

### Module-Level Documentation

```elixir
@moduledoc """
Legacy API functions using deprecated patterns.

These functions will be removed in v2.0.0.

## Migration Guide

### Old Pattern (Deprecated)
    {:ok, result} = Kreuzberg.LegacyAPI.extract_with_ocr(input, "application/pdf", true)

### New Pattern (Recommended)
    config = %ExtractionConfig{ocr: %{"enabled" => true}}
    {:ok, result} = Kreuzberg.extract(input, "application/pdf", config)

See: https://docs.kreuzberg.io/v1-to-v2-migration
"""
```

## Deprecated Functions/Methods

### C# LegacyExtractionAPI

1. **ExtractAsyncWithOcr** - Boolean OCR parameter (→ ExtractionConfig.Ocr)
2. **WithQualityProcessing** - Extension method (→ ExtractionConfig.EnableQualityProcessing)
3. **WithOcrBackend** - Extension method (→ ExtractionConfig.Ocr direct usage)
4. **IsOcrEnabledDeprecated** - Validation helper (→ direct config checks)

### C# DeprecatedConfigurationModel Properties

1. **OcrBackend** - (→ ExtractionConfig.Ocr.Backend)
2. **EnableOcr** - (→ ExtractionConfig.Ocr nested config)
3. **OcrLanguage** - (→ ExtractionConfig.Ocr.Language)

### Elixir LegacyAPI

1. **extract_with_ocr/3** - Boolean OCR flag (→ config with ocr map)
2. **extract_with_chunking/4** - Separate chunk params (→ config.chunking)
3. **extract_file_legacy/3** - Old keyword opts (→ ExtractionConfig)
4. **extract_with_options/3** - Keyword configuration (→ ExtractionConfig)
5. **validate_extraction_request/3** - Explicit validation (→ automatic in API)

## Migration Pattern

All deprecated APIs follow a consistent pattern:

### Old API (Deprecated)
```csharp
// C#
var result = await LegacyExtractionAPI.ExtractAsyncWithOcr(input, mimeType, true);
```

```elixir
# Elixir
{:ok, result} = Kreuzberg.LegacyAPI.extract_with_ocr(input, mime_type, true)
```

### New API (Recommended)
```csharp
// C#
var config = new ExtractionConfig
{
    Ocr = new OcrConfig { Backend = "tesseract" }
};
var result = await KreuzbergClient.ExtractAsync(input, mimeType, config);
```

```elixir
# Elixir
config = %ExtractionConfig{ocr: %{"enabled" => true, "backend" => "tesseract"}}
{:ok, result} = Kreuzberg.extract(input, mime_type, config)
```

## Testing

### C# Tests

Run deprecation tests:
```bash
cd packages/csharp
dotnet test tests/csharp_deprecation_test.cs
```

Tests verify:
- Deprecated methods have `[Obsolete]` attribute
- Properties have `[Obsolete]` attribute
- Attribute messages contain migration guidance
- Removal version (v2.0.0) is specified

### Elixir Tests

Run deprecation tests:
```bash
cd packages/elixir
mix test test/elixir_deprecation_test.exs
```

Tests verify:
- Functions are exported and callable
- @deprecated markers are in place
- Module documentation includes migration guide
- Deprecated functions delegate correctly
- Validation works as expected

## Compiler Behavior

### C# Compiler Warnings

When using deprecated APIs, the C# compiler generates warnings:

```
CS0618: 'LegacyExtractionAPI.ExtractAsyncWithOcr(byte[], string, bool)' 
is obsolete: 'Use ExtractAsyncWithConfig() with ExtractionConfig.Ocr instead. 
This method will be removed in v2.0.0.'
```

Suppress with:
```csharp
#pragma warning disable CS0618
var result = await LegacyExtractionAPI.ExtractAsyncWithOcr(input, mimeType, true);
#pragma warning restore CS0618
```

### Elixir Compiler Warnings

When using deprecated functions, Elixir compiler generates warnings:

```
warning: Kreuzberg.LegacyAPI.extract_with_ocr/3 is deprecated, use 
Kreuzberg.extract/3 with ExtractionConfig.ocr map instead
```

Run with `mix compile` to see all deprecation warnings.

## Documentation Generation

### C# (DocFX)

The `[Obsolete]` attribute automatically adds an "Obsolete" badge in generated documentation.

Generate docs:
```bash
cd packages/csharp
dotnet build --configuration Release
```

### Elixir (ExDoc)

The `@deprecated` attribute generates a "Deprecated" notice in ExDoc-generated docs.

Generate docs:
```bash
cd packages/elixir
mix docs
```

The output will show:
- Function name with "Deprecated" badge
- Original @deprecated message
- Full @doc string with examples and migration guidance

## Migration Timeline

- **v1.x**: Deprecated APIs available with warnings
- **v2.0.0**: Deprecated APIs removed, migration guide published
- **Before v2.0.0**: Minimum 2 minor versions of deprecation warning

## Checklist for Complete Deprecation Implementation

To fully implement deprecation markers in existing code:

### C#

- [ ] Identify deprecated functions/properties
- [ ] Add `[Obsolete("message", error: false)]` attribute
- [ ] Include migration suggestion in message
- [ ] Specify removal version (e.g., "v2.0.0")
- [ ] Update XML doc comments with `<remarks>` section
- [ ] Provide delegate implementation to new API
- [ ] Add unit tests using reflection to verify attributes
- [ ] Generate documentation and verify "Obsolete" badge appears
- [ ] Test that code compiles with CS0618 warnings
- [ ] Document in CHANGELOG.md

### Elixir

- [ ] Identify deprecated functions
- [ ] Add `@deprecated "message"` attribute before function
- [ ] Include migration suggestion in deprecation message
- [ ] Specify removal version (e.g., "Removes in v2.0.0")
- [ ] Add comprehensive @doc with examples
- [ ] Include "Deprecated" section in doc string
- [ ] Provide implementation that delegates to new API
- [ ] Add @spec for proper typing
- [ ] Add ExUnit tests verifying functions work
- [ ] Generate ExDoc and verify deprecation notice appears
- [ ] Run `mix compile` to confirm warnings
- [ ] Document in CHANGELOG.md

## References

### C# Deprecation

- [ObsoleteAttribute Documentation](https://learn.microsoft.com/en-us/dotnet/api/system.obsoleteattribute)
- [C# Compiler Warning CS0618](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-messages/cs0618)
- [DocFX Obsolete Handling](https://dotnet.github.io/docfx/)

### Elixir Deprecation

- [Elixir @deprecated attribute](https://hexdocs.pm/elixir/Module.html#module-attributes)
- [ExDoc Deprecation Display](https://github.com/elixir-lang/ex_doc)
- [Elixir Compiler Warnings](https://hexdocs.pm/elixir/Code.html)

### General

- [Semantic Versioning](https://semver.org/)
- [API Stability and Deprecation Policies](https://opensource.google/documentation/reference/releasing/version-control)

## Questions and Support

For questions about deprecation implementation:

1. Review the `DEPRECATION_GUIDE.md` for detailed patterns
2. Check `DeprecationExamples.cs` for C# patterns
3. Check `LegacyAPI.ex` for Elixir patterns
4. Run the test suites to understand verification approaches

