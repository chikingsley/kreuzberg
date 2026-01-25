defmodule Kreuzberg.SerializationTest do
  @moduledoc """
  Cross-language serialization tests for Elixir bindings.

  Validates that ExtractionConfig serializes consistently with other language bindings.
  """

  use ExUnit.Case
  doctest Kreuzberg.ExtractionConfig

  describe "ExtractionConfig serialization" do
    test "minimal config serializes to JSON" do
      config = Kreuzberg.ExtractionConfig.new()
      json = Jason.encode!(config)

      assert is_binary(json)

      parsed = Jason.decode!(json)
      assert Map.has_key?(parsed, "use_cache")
      assert Map.has_key?(parsed, "enable_quality_processing")
      assert Map.has_key?(parsed, "force_ocr")
    end

    test "config with custom values serializes correctly" do
      config =
        Kreuzberg.ExtractionConfig.new(
          use_cache: true,
          enable_quality_processing: false,
          force_ocr: true
        )

      json = Jason.encode!(config)
      parsed = Jason.decode!(json)

      assert parsed["use_cache"] == true
      assert parsed["enable_quality_processing"] == false
      assert parsed["force_ocr"] == true
    end

    test "field values are preserved after serialization" do
      original =
        Kreuzberg.ExtractionConfig.new(
          use_cache: false,
          enable_quality_processing: true
        )

      json = Jason.encode!(original)
      parsed = Jason.decode!(json)

      assert parsed["use_cache"] == false
      assert parsed["enable_quality_processing"] == true
    end

    test "handles round-trip serialization" do
      config1 =
        Kreuzberg.ExtractionConfig.new(
          use_cache: true,
          enable_quality_processing: false
        )

      json1 = Jason.encode!(config1)
      parsed1 = Jason.decode!(json1)

      config2 = Kreuzberg.ExtractionConfig.new(parsed1)
      json2 = Jason.encode!(config2)

      # Parse both JSONs and compare
      assert Jason.decode!(json1) == Jason.decode!(json2)
    end

    test "uses snake_case field names" do
      config = Kreuzberg.ExtractionConfig.new(use_cache: true)
      json = Jason.encode!(config)

      assert String.contains?(json, "use_cache")
      assert not String.contains?(json, "useCache")
    end

    test "serializes nested ocr config" do
      config =
        Kreuzberg.ExtractionConfig.new(
          ocr: %{
            backend: "tesseract",
            language: "eng"
          }
        )

      json = Jason.encode!(config)
      parsed = Jason.decode!(json)

      assert Map.has_key?(parsed, "ocr")
      assert parsed["ocr"]["backend"] == "tesseract"
      assert parsed["ocr"]["language"] == "eng"
    end

    test "handles null/nil values correctly" do
      config =
        Kreuzberg.ExtractionConfig.new(
          ocr: nil,
          chunking: nil
        )

      json = Jason.encode!(config)
      parsed = Jason.decode!(json)

      assert is_map(parsed)
    end

    test "maintains immutability during serialization" do
      config = Kreuzberg.ExtractionConfig.new(use_cache: true)

      json1 = Jason.encode!(config)
      json2 = Jason.encode!(config)
      json3 = Jason.encode!(config)

      assert json1 == json2
      assert json2 == json3
    end

    test "serializes all mandatory fields" do
      config = Kreuzberg.ExtractionConfig.new()
      json = Jason.encode!(config)
      parsed = Jason.decode!(json)

      mandatory_fields = [
        "use_cache",
        "enable_quality_processing",
        "force_ocr"
      ]

      Enum.each(mandatory_fields, fn field ->
        assert Map.has_key?(parsed, field), "Mandatory field '#{field}' is missing"
      end)
    end

    test "deserializes from JSON string" do
      json =
        Jason.encode!(%{
          use_cache: true,
          enable_quality_processing: false,
          force_ocr: true
        })

      parsed = Jason.decode!(json)
      config = Kreuzberg.ExtractionConfig.new(parsed)

      assert config.use_cache == true
      assert config.enable_quality_processing == false
      assert config.force_ocr == true
    end

    test "produces valid JSON" do
      config = Kreuzberg.ExtractionConfig.new(use_cache: true)
      json = Jason.encode!(config)

      # Should not raise on decode
      assert Jason.decode!(json)
      assert is_binary(json)
    end

    test "pretty prints JSON" do
      config = Kreuzberg.ExtractionConfig.new(use_cache: true)
      json = Jason.encode!(config, pretty: true)

      # Pretty JSON should have newlines
      assert String.contains?(json, "\n")

      # Should still be valid JSON
      assert Jason.decode!(json)
    end
  end

  describe "ExtractionConfig field consistency" do
    test "all configs have same required fields" do
      configs = [
        Kreuzberg.ExtractionConfig.new(),
        Kreuzberg.ExtractionConfig.new(use_cache: true),
        Kreuzberg.ExtractionConfig.new(enable_quality_processing: false)
      ]

      mandatory_fields = ["use_cache", "enable_quality_processing", "force_ocr"]

      Enum.each(configs, fn config ->
        json = Jason.encode!(config)
        parsed = Jason.decode!(json)

        Enum.each(mandatory_fields, fn field ->
          assert Map.has_key?(parsed, field),
                 "Field '#{field}' missing in config: #{inspect(config)}"
        end)
      end)
    end
  end
end
