using System;
using System.Text.Json;
using Xunit;

namespace Kreuzberg.Tests.Config;

/// <summary>
/// Comprehensive configuration tests for ExtractionConfig.
/// Tests serialization, immutability, nesting, and validation.
/// </summary>
public class ExtractionConfigTests
{
    [Fact]
    public void Constructor_ShouldCreateWithDefaults()
    {
        var config = new ExtractionConfig();

        Assert.Null(config.UseCache);
        Assert.Null(config.EnableQualityProcessing);
        Assert.Null(config.Ocr);
        Assert.Null(config.Chunking);
        Assert.Null(config.Images);
    }

    [Fact]
    public void Constructor_ShouldCreateWithCustomValues()
    {
        var ocrConfig = new OcrConfig { Backend = "tesseract", Language = "eng" };
        var chunkingConfig = new ChunkingConfig { MaxChars = 1000, MaxOverlap = 100 };

        var config = new ExtractionConfig
        {
            UseCache = true,
            EnableQualityProcessing = false,
            ForceOcr = true,
            Ocr = ocrConfig,
            Chunking = chunkingConfig,
            MaxConcurrentExtractions = 5
        };

        Assert.True(config.UseCache);
        Assert.False(config.EnableQualityProcessing);
        Assert.True(config.ForceOcr);
        Assert.Equal(5, config.MaxConcurrentExtractions);
        Assert.NotNull(config.Ocr);
        Assert.NotNull(config.Chunking);
    }

    [Fact]
    public void Serialize_ShouldRoundTrip()
    {
        var original = new ExtractionConfig
        {
            UseCache = true,
            EnableQualityProcessing = false,
            ForceOcr = true,
            MaxConcurrentExtractions = 3
        };

        var json = JsonSerializer.Serialize(original);
        var restored = JsonSerializer.Deserialize<ExtractionConfig>(json);

        Assert.NotNull(restored);
        Assert.Equal(original.UseCache, restored.UseCache);
        Assert.Equal(original.EnableQualityProcessing, restored.EnableQualityProcessing);
        Assert.Equal(original.ForceOcr, restored.ForceOcr);
        Assert.Equal(original.MaxConcurrentExtractions, restored.MaxConcurrentExtractions);
    }

    [Fact]
    public void Serialize_ShouldIncludeNestedConfigs()
    {
        var config = new ExtractionConfig
        {
            UseCache = true,
            Ocr = new OcrConfig { Backend = "tesseract" },
            Chunking = new ChunkingConfig { MaxChars = 2000 }
        };

        var json = JsonSerializer.Serialize(config);
        var restored = JsonSerializer.Deserialize<ExtractionConfig>(json);

        Assert.NotNull(restored?.Ocr);
        Assert.Equal("tesseract", restored.Ocr.Backend);
        Assert.NotNull(restored.Chunking);
        Assert.Equal(2000, restored.Chunking.MaxChars);
    }

    [Fact]
    public void Immutability_ShouldEnforceInitOnly()
    {
        var config = new ExtractionConfig { UseCache = true };

        var useCacheProperty = typeof(ExtractionConfig).GetProperty("UseCache");
        var setMethod = useCacheProperty?.GetSetMethod();

        Assert.NotNull(setMethod);
        Assert.True(setMethod.ReturnParameter
            .GetRequiredCustomModifiers()
            .Any(m => m.Name == "IsExternalInit"),
            "UseCache must have init-only accessor");
    }

    [Fact]
    public void NullHandling_ShouldHandleNullableFields()
    {
        var config = new ExtractionConfig
        {
            Ocr = null,
            Chunking = null,
            Images = null
        };

        Assert.Null(config.Ocr);
        Assert.Null(config.Chunking);
        Assert.Null(config.Images);
    }

    [Fact]
    public void Nesting_ShouldWorkWithMultipleConfigs()
    {
        var ocrConfig = new OcrConfig { Backend = "paddle", Language = "fra" };
        var chunkingConfig = new ChunkingConfig { MaxChars = 3000, Enabled = true };
        var pdfConfig = new PdfConfig { ExtractImages = true, ExtractMetadata = true };

        var config = new ExtractionConfig
        {
            Ocr = ocrConfig,
            Chunking = chunkingConfig,
            PdfOptions = pdfConfig
        };

        Assert.Equal("paddle", config.Ocr?.Backend);
        Assert.Equal(3000, config.Chunking?.MaxChars);
        Assert.True(config.PdfOptions?.ExtractImages);
    }

    [Fact]
    public void MaxConcurrentExtractions_ShouldAcceptValidValues()
    {
        var config1 = new ExtractionConfig { MaxConcurrentExtractions = 1 };
        var config2 = new ExtractionConfig { MaxConcurrentExtractions = 10 };
        var config3 = new ExtractionConfig { MaxConcurrentExtractions = 100 };

        Assert.Equal(1, config1.MaxConcurrentExtractions);
        Assert.Equal(10, config2.MaxConcurrentExtractions);
        Assert.Equal(100, config3.MaxConcurrentExtractions);
    }

    [Fact]
    public void Serialization_ShouldUseJsonPropertyNames()
    {
        var config = new ExtractionConfig { UseCache = true };
        var json = JsonSerializer.Serialize(config);

        Assert.Contains("use_cache", json);
        Assert.Contains("true", json);
    }

    [Fact]
    public void AllPropertiesAreInitOnly()
    {
        var properties = typeof(ExtractionConfig)
            .GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)
            .Where(p => p.SetMethod != null)
            .ToList();

        Assert.True(properties.Count > 0, "ExtractionConfig should have at least one settable property");

        foreach (var prop in properties)
        {
            var hasInitOnly = prop.SetMethod.ReturnParameter?
                .GetRequiredCustomModifiers()
                .Any(m => m.Name == "IsExternalInit") ?? false;

            Assert.True(hasInitOnly, $"{prop.Name} must have init-only accessor");
        }
    }

    [Fact]
    public void ComplexNesting_ShouldPreservePath()
    {
        var config = new ExtractionConfig
        {
            Ocr = new OcrConfig
            {
                Backend = "tesseract",
                TesseractConfig = new TesseractConfig
                {
                    Psm = 6,
                    Language = "eng"
                }
            }
        };

        Assert.Equal("tesseract", config.Ocr?.Backend);
        Assert.Equal(6, config.Ocr?.TesseractConfig?.Psm);
        Assert.Equal("eng", config.Ocr?.TesseractConfig?.Language);
    }

    [Fact]
    public void TestOutputFormat_ShouldAcceptValidValues()
    {
        var config1 = new ExtractionConfig { OutputFormat = "plain" };
        var config2 = new ExtractionConfig { OutputFormat = "markdown" };
        var config3 = new ExtractionConfig { OutputFormat = "djot" };
        var config4 = new ExtractionConfig { OutputFormat = "html" };

        Assert.Equal("plain", config1.OutputFormat);
        Assert.Equal("markdown", config2.OutputFormat);
        Assert.Equal("djot", config3.OutputFormat);
        Assert.Equal("html", config4.OutputFormat);
    }

    [Fact]
    public void TestResultFormat_ShouldAcceptValidValues()
    {
        var config1 = new ExtractionConfig { ResultFormat = "unified" };
        var config2 = new ExtractionConfig { ResultFormat = "element_based" };

        Assert.Equal("unified", config1.ResultFormat);
        Assert.Equal("element_based", config2.ResultFormat);
    }

    [Fact]
    public void TestOutputFormat_AndResultFormat_TogetherSerialization()
    {
        var config = new ExtractionConfig
        {
            OutputFormat = "markdown",
            ResultFormat = "element_based"
        };

        var json = JsonSerializer.Serialize(config);
        var restored = JsonSerializer.Deserialize<ExtractionConfig>(json);

        Assert.NotNull(restored);
        Assert.Equal("markdown", restored.OutputFormat);
        Assert.Equal("element_based", restored.ResultFormat);
    }

    [Fact]
    public void TestOutputAndResultFormats_WithOtherConfigs()
    {
        var config = new ExtractionConfig
        {
            UseCache = true,
            OutputFormat = "markdown",
            ResultFormat = "unified",
            Ocr = new OcrConfig { Backend = "tesseract" }
        };

        Assert.True(config.UseCache);
        Assert.Equal("markdown", config.OutputFormat);
        Assert.Equal("unified", config.ResultFormat);
        Assert.NotNull(config.Ocr);
        Assert.Equal("tesseract", config.Ocr.Backend);
    }

    [Fact]
    public void TestOutputAndResultFormats_JsonSerialization()
    {
        var config = new ExtractionConfig
        {
            OutputFormat = "djot",
            ResultFormat = "element_based"
        };

        var json = JsonSerializer.Serialize(config);

        Assert.Contains("output_format", json);
        Assert.Contains("djot", json);
        Assert.Contains("result_format", json);
        Assert.Contains("element_based", json);
    }

    [Fact]
    public void TestOutputFormat_CanBeNull()
    {
        var config = new ExtractionConfig { OutputFormat = null };
        Assert.Null(config.OutputFormat);
    }

    [Fact]
    public void TestResultFormat_CanBeNull()
    {
        var config = new ExtractionConfig { ResultFormat = null };
        Assert.Null(config.ResultFormat);
    }

}
