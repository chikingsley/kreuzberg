# Deprecation Markers for C# and Elixir Bindings

This guide documents how to properly mark deprecated code in C# and Elixir bindings to guide users toward recommended alternatives.

## C# Deprecation Standards

### Using [Obsolete] Attribute

The `[Obsolete]` attribute is the standard way to mark deprecated code in C#. It appears in IntelliSense and generates compiler warnings.

#### Syntax

```csharp
[Obsolete("Message", error: false)]
public SomeType DeprecatedMember { get; set; }
```

#### Parameters

- **message** (required): String describing the deprecation reason and recommended alternative
- **error** (optional): 
  - `false` (default): Generate CS0618 warning
  - `true`: Generate CS0619 error, preventing compilation

#### Examples

**Simple Property Deprecation:**

```csharp
/// <summary>
/// Deprecated: Use the Ocr configuration property instead.
/// </summary>
[Obsolete("Use ExtractionConfig.Ocr property instead", false)]
public bool EnableOcr { get; set; }
```

**Method Deprecation with Timeline:**

```csharp
/// <summary>
/// Extract text using legacy method.
/// 
/// Deprecated: This method will be removed in version 2.0.0.
/// Use ExtractAsync() instead for better performance.
/// </summary>
[Obsolete("Use ExtractAsync() instead. This method will be removed in v2.0.0.", false)]
public string Extract(string input)
{
    // Legacy implementation
}
```

**Error-Level Deprecation (prevents compilation):**

```csharp
[Obsolete("This API has been completely replaced. See migration guide at https://...", error: true)]
public void ObsoleteMethod()
{
    throw new NotImplementedException();
}
```

### Best Practices

1. **Always document the reason**: Explain why the code is deprecated
2. **Provide alternatives**: Clearly state what users should use instead
3. **Add timeline**: Indicate when the code will be removed
4. **Link to migration guides**: Provide documentation URLs for complex transitions
5. **Update XML docs**: Add `<remarks>` section noting deprecation

#### Complete Example

```csharp
/// <summary>
/// Extracts content with deprecated OCR configuration method.
/// </summary>
/// <remarks>
/// This method uses the old boolean-based OCR configuration pattern.
/// It will be removed in v2.0.0. Please migrate to the new configuration-based approach.
/// 
/// See migration guide: https://docs.kreuzberg.io/v1-to-v2-migration
/// </remarks>
/// <param name="input">Document input</param>
/// <param name="enableOcr">Enable OCR (deprecated)</param>
/// <returns>Extraction result</returns>
[Obsolete(
    "Use ExtractAsync(input, new ExtractionConfig { Ocr = new OcrConfig { ... } }) instead. " +
    "This method will be removed in v2.0.0.",
    error: false
)]
public async Task<ExtractionResult> ExtractWithOcrAsync(string input, bool enableOcr)
{
    return await ExtractAsync(input, new ExtractionConfig 
    { 
        Ocr = enableOcr ? new OcrConfig { Backend = "tesseract" } : null 
    });
}
```

## Elixir Deprecation Standards

### Using @deprecated Module Attribute

Elixir uses the `@deprecated` module attribute to mark deprecated functions. This works with ExDoc to generate deprecation notices in documentation.

#### Syntax

```elixir
@deprecated "Description of deprecation and recommended alternative"
def deprecated_function(args) do
  # implementation
end
```

#### Examples

**Simple Function Deprecation:**

```elixir
@deprecated "Use extract_with_config/3 instead"
def extract(input, mime_type) do
  extract_with_config(input, mime_type, nil)
end
```

**Function Deprecation with Timeline:**

```elixir
@deprecated "Use extract_with_config/3 instead. This function will be removed in v2.0.0."
def extract_with_ocr(input, mime_type, enable_ocr) do
  config = if enable_ocr do
    %ExtractionConfig{ocr: %{"enabled" => true}}
  else
    nil
  end
  extract_with_config(input, mime_type, config)
end
```

**Deprecation with Migration Instructions:**

```elixir
@doc """
Extract content using legacy configuration pattern.

Deprecated: Use `extract_with_config/3` with the new configuration format instead.
This function will be removed in v2.0.0.

See migration guide at: https://docs.kreuzberg.io/v1-to-v2-migration
"""
@deprecated "Use extract_with_config/3 with new config format. Removes in v2.0.0. See docs."
@spec extract_legacy(binary(), String.t(), keyword()) :: {:ok, any()} | {:error, String.t()}
def extract_legacy(input, mime_type, opts \\ []) do
  config = convert_legacy_opts_to_config(opts)
  extract_with_config(input, mime_type, config)
end
```

### Best Practices

1. **Add @doc with deprecation notice**: Document the reason in docstring
2. **Use @spec**: Include type specification for clarity
3. **Provide implementation**: Deprecated functions should delegate to new implementations
4. **Add timeline**: Indicate removal version
5. **Link resources**: Reference migration guides when applicable
6. **Test deprecations**: Ensure deprecated functions work correctly

#### Complete Example

```elixir
defmodule Kreuzberg.LegacyAPI do
  @moduledoc """
  Legacy API functions deprecated in favor of configuration-based approach.
  
  These functions will be removed in v2.0.0.
  See the migration guide: https://docs.kreuzberg.io/v1-to-v2-migration
  """

  alias Kreuzberg.{ExtractionConfig, ExtractionResult}

  @doc """
  Extract content with deprecated OCR enabled/disabled boolean.

  This function is deprecated. Use `Kreuzberg.extract/3` with configuration instead:

      # Old way (deprecated):
      Kreuzberg.LegacyAPI.extract_with_ocr_bool(input, "application/pdf", true)

      # New way (recommended):
      config = %ExtractionConfig{ocr: %{"enabled" => true}}
      Kreuzberg.extract(input, "application/pdf", config)

  The boolean `enable_ocr` parameter has been replaced by the more flexible
  `ExtractionConfig.ocr` nested configuration map.
  """
  @deprecated "Use Kreuzberg.extract/3 with ExtractionConfig.ocr instead. Removes in v2.0.0."
  @spec extract_with_ocr_bool(binary(), String.t(), boolean()) :: 
          {:ok, ExtractionResult.t()} | {:error, String.t()}
  def extract_with_ocr_bool(input, mime_type, enable_ocr) do
    config = if enable_ocr do
      %ExtractionConfig{ocr: %{"enabled" => true, "backend" => "tesseract"}}
    else
      nil
    end

    Kreuzberg.extract(input, mime_type, config)
  end

  @doc """
  Extract file with deprecated configuration format.

  Deprecated: Use `Kreuzberg.extract_file/3` instead.
  This function converts old keyword list configuration to the new config format.
  """
  @deprecated "Use Kreuzberg.extract_file/3 with ExtractionConfig struct. Removes in v2.0.0."
  @spec extract_file_legacy(String.t() | Path.t(), String.t() | nil, keyword()) ::
          {:ok, ExtractionResult.t()} | {:error, String.t()}
  def extract_file_legacy(path, mime_type \\ nil, opts \\ []) do
    config = convert_keyword_opts_to_config(opts)
    Kreuzberg.extract_file(path, mime_type, config)
  end

  # Private helper to convert old-style options to new config
  defp convert_keyword_opts_to_config(opts) do
    %ExtractionConfig{
      use_cache: Keyword.get(opts, :use_cache, true),
      force_ocr: Keyword.get(opts, :force_ocr, false),
      ocr: convert_ocr_opts(Keyword.get(opts, :ocr, nil)),
      chunking: Keyword.get(opts, :chunking, nil)
    }
  end

  defp convert_ocr_opts(nil), do: nil
  defp convert_ocr_opts(enable_ocr) when is_boolean(enable_ocr) do
    if enable_ocr, do: %{"enabled" => true}, else: nil
  end
  defp convert_ocr_opts(ocr_config), do: ocr_config
end
```

## Testing Deprecation Warnings

### C# Testing

```csharp
// This code should generate a CS0618 warning:
#pragma warning disable CS0618
var result = client.ExtractWithOcrAsync(input, true);
#pragma warning restore CS0618

// Or compile with /warnaserror:CS0618 to treat as error
```

### Elixir Testing

```elixir
defmodule DeprecationTest do
  test "deprecated function works but generates warning" do
    # Elixir's compiler will emit a warning when building
    # Use mix compile to see warnings:
    # warning: Kreuzberg.LegacyAPI.extract_with_ocr_bool/3 is deprecated
    result = Kreuzberg.LegacyAPI.extract_with_ocr_bool(input, "application/pdf", true)
    assert {:ok, _} = result
  end
end
```

## Documentation Generation

### C# (with DocFX)

The `[Obsolete]` attribute automatically appears in DocFX-generated documentation with a "Obsolete" badge.

### Elixir (with ExDoc)

The `@deprecated` attribute generates an "Deprecated" notice in the rendered documentation:

```bash
mix docs
```

## Deprecation Removal Checklist

Before removing deprecated code:

- [ ] Deprecated at least 2 minor versions ago
- [ ] Major version bump in release notes
- [ ] Migration guide published and accessible
- [ ] All deprecated code removed from examples
- [ ] Tests updated to use non-deprecated APIs
- [ ] Changelog documents removal
- [ ] Release notes highlight breaking change

## Common Patterns to Deprecate

1. **Configuration format changes**: Old boolean flags → new configuration objects
2. **Parameter reordering**: Changing method signature
3. **Type changes**: Updating parameter or return types
4. **Method extraction**: Splitting functionality into focused methods
5. **Namespace reorganization**: Moving types to new namespaces
6. **Feature consolidation**: Combining multiple methods into single configurable method

## References

- [C# Obsolete Attribute (Microsoft Docs)](https://learn.microsoft.com/en-us/dotnet/api/system.obsoleteattribute)
- [Elixir @deprecated (ExDoc Docs)](https://hexdocs.pm/ex_doc/ExDoc.Markdown.html#deprecated)
- [Semantic Versioning](https://semver.org/)
