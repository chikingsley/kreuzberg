using System;
using System.Text.Json;
using Xunit;

namespace Kreuzberg.Tests;

/// <summary>
/// Tests for serialization of configuration objects, particularly ensuring
/// that empty options serialize to "{}" instead of "null" for FFI compatibility.
/// </summary>
public class SerializationTests
{
    [Fact]
    public void EmptyHtmlConversionOptions_SerializesAsEmptyObject()
    {
        // Arrange
        var options = new HtmlConversionOptions();

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Equal("{}", json);
        Assert.NotEqual("null", json);
    }

    [Fact]
    public void EmptyHtmlConversionOptions_DoesNotSerializeAsNull()
    {
        // Arrange
        var options = new HtmlConversionOptions();

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        // Verify we get an empty object, not null
        Assert.False(json.Contains("null", StringComparison.Ordinal),
            "Empty HtmlConversionOptions should serialize to '{}', not 'null'");
    }

    [Fact]
    public void HtmlConversionOptions_WithSingleProperty_SerializesProperty()
    {
        // Arrange
        var options = new HtmlConversionOptions
        {
            HeadingStyle = "atx"
        };

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Contains("atx", json);
        Assert.NotEqual("{}", json);
        // Verify the property name in snake_case (camelCase per ConfigOptions)
        Assert.Contains("headingStyle", json);
    }

    [Fact]
    public void HtmlConversionOptions_WithMultipleProperties_SerializesAll()
    {
        // Arrange
        var options = new HtmlConversionOptions
        {
            HeadingStyle = "setext",
            Bullets = "-",
            EscapeAsterisks = true
        };

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Contains("setext", json);
        Assert.Contains("bullets", json);
        Assert.Contains("escapeAsterisks", json);
        Assert.Contains("true", json);
    }

    [Fact]
    public void HtmlConversionOptions_WithNullProperties_SerializesOnlyNonNull()
    {
        // Arrange
        var options = new HtmlConversionOptions
        {
            HeadingStyle = "atx",
            Bullets = null,
            EscapeAsterisks = null
        };

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Contains("headingStyle", json);
        Assert.DoesNotContain("bullets", json);
        Assert.DoesNotContain("escapeAsterisks", json);
    }

    [Fact]
    public void EmptyHtmlPreprocessingOptions_SerializesAsEmptyObject()
    {
        // Arrange
        var options = new HtmlPreprocessingOptions();

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Equal("{}", json);
        Assert.NotEqual("null", json);
    }

    [Fact]
    public void HtmlPreprocessingOptions_WithProperties_SerializesAll()
    {
        // Arrange
        var options = new HtmlPreprocessingOptions
        {
            Enabled = true,
            Preset = "aggressive",
            RemoveNavigation = true
        };

        // Act
        var json = JsonSerializer.Serialize(options, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(json);
        Assert.Contains("enabled", json);
        Assert.Contains("preset", json);
        Assert.Contains("aggressive", json);
        Assert.Contains("removeNavigation", json);
        Assert.Contains("true", json);
    }

    [Fact]
    public void HtmlConversionOptions_RoundTrip_PreservesData()
    {
        // Arrange
        var original = new HtmlConversionOptions
        {
            HeadingStyle = "atx",
            ListIndentWidth = 4,
            Bullets = "-",
            EscapeAsterisks = true
        };

        // Act
        var json = JsonSerializer.Serialize(original, Serialization.ConfigOptions);
        var deserialized = JsonSerializer.Deserialize<HtmlConversionOptions>(json, Serialization.ConfigOptions);

        // Assert
        Assert.NotNull(deserialized);
        Assert.Equal(original.HeadingStyle, deserialized.HeadingStyle);
        Assert.Equal(original.ListIndentWidth, deserialized.ListIndentWidth);
        Assert.Equal(original.Bullets, deserialized.Bullets);
        Assert.Equal(original.EscapeAsterisks, deserialized.EscapeAsterisks);
    }
}
