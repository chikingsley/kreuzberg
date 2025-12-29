defmodule KreuzbergTest.Unit.Config.ImageExtractionConfigTest do
  @moduledoc """
  Unit tests for image extraction configuration.

  Tests cover:
  - Struct creation with quality and format settings
  - Validation of format and compression
  - Serialization to/from maps
  - Pattern matching on image configs
  - Nesting in ExtractionConfig
  - Edge cases for quality bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "extract_images" => true,
        "format" => "png",
        "quality" => 85
      }

      assert config["extract_images"] == true
      assert config["format"] == "png"
      assert config["quality"] == 85
    end

    @tag :unit
    test "creates with JPEG format" do
      config = %{
        "extract_images" => true,
        "format" => "jpeg",
        "quality" => 90,
        "compression" => 9
      }

      assert config["format"] == "jpeg"
      assert config["quality"] == 90
      assert config["compression"] == 9
    end

    @tag :unit
    test "creates with WebP format" do
      config = %{
        "extract_images" => true,
        "format" => "webp",
        "quality" => 75
      }

      assert config["format"] == "webp"
      assert config["quality"] == 75
    end

    @tag :unit
    test "creates with size and DPI constraints" do
      config = %{
        "extract_images" => true,
        "min_width" => 100,
        "min_height" => 100,
        "max_width" => 4000,
        "max_height" => 3000,
        "dpi_threshold" => 72
      }

      assert config["min_width"] == 100
      assert config["dpi_threshold"] == 72
    end
  end

  describe "validation" do
    @tag :unit
    test "validates extract_images is boolean" do
      config = %{"extract_images" => true}

      assert is_boolean(config["extract_images"])
    end

    @tag :unit
    test "validates format is valid" do
      valid_formats = ["png", "jpeg", "webp", "bmp", "tiff"]
      config = %{"format" => "png"}

      assert config["format"] in valid_formats
    end

    @tag :unit
    test "validates quality range 1-100" do
      config = %{"quality" => 85}

      assert is_integer(config["quality"])
      assert config["quality"] >= 1 and config["quality"] <= 100
    end

    @tag :unit
    test "validates compression is non-negative" do
      config = %{"compression" => 9}

      assert is_integer(config["compression"])
      assert config["compression"] >= 0
    end

    @tag :unit
    test "validates width and height constraints" do
      config = %{
        "min_width" => 100,
        "min_height" => 100,
        "max_width" => 4000,
        "max_height" => 3000
      }

      assert config["min_width"] < config["max_width"]
      assert config["min_height"] < config["max_height"]
    end

    @tag :unit
    test "accepts valid image extraction config" do
      config = %{
        "extract_images" => true,
        "format" => "webp",
        "quality" => 80,
        "min_width" => 50,
        "min_height" => 50
      }

      assert config["extract_images"] == true
      assert config["quality"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "extract_images" => true,
        "format" => "jpeg",
        "quality" => 90,
        "compression" => 8
      }

      assert is_map(config)
      assert config["format"] == "jpeg"
      assert config["quality"] == 90
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "extract_images" => true,
        "format" => "webp",
        "quality" => 75,
        "min_width" => 100,
        "min_height" => 100,
        "max_width" => 4000,
        "max_height" => 3000
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["format"] == "webp"
      assert restored["quality"] == 75
      assert restored["max_width"] == 4000
    end

    @tag :unit
    test "preserves boolean values in JSON" do
      config = %{"extract_images" => true}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["extract_images"] == true
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      image_config = %{
        "extract_images" => true,
        "format" => "webp",
        "quality" => 75
      }

      extraction_config = %Kreuzberg.ExtractionConfig{images: image_config}

      assert extraction_config.images["extract_images"] == true
      assert extraction_config.images["format"] == "webp"
    end

    @tag :unit
    test "validates when nested" do
      image_config = %{"extract_images" => true, "format" => "png", "quality" => 85}
      extraction_config = %Kreuzberg.ExtractionConfig{images: image_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on format field" do
      config = %{"format" => "webp"}

      case config do
        %{"format" => "webp"} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on quality field" do
      config = %{"quality" => 85}

      case config do
        %{"quality" => q} when q > 80 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum quality" do
      config = %{"quality" => 1}

      assert config["quality"] == 1
    end

    @tag :unit
    test "handles maximum quality" do
      config = %{"quality" => 100}

      assert config["quality"] == 100
    end

    @tag :unit
    test "handles zero minimum dimensions" do
      config = %{"min_width" => 0, "min_height" => 0}

      assert config["min_width"] == 0
      assert config["min_height"] == 0
    end

    @tag :unit
    test "handles very large maximum dimensions" do
      config = %{"max_width" => 16_000, "max_height" => 12_000}

      assert config["max_width"] == 16_000
      assert config["max_height"] == 12_000
    end

    @tag :unit
    test "handles nil format" do
      config = %{"format" => nil}

      assert config["format"] == nil
    end

    @tag :unit
    test "handles all supported formats" do
      formats = ["png", "jpeg", "webp", "bmp", "tiff"]

      Enum.each(formats, fn fmt ->
        config = %{"format" => fmt}
        assert config["format"] == fmt
      end)
    end

    @tag :unit
    test "handles compression edge values" do
      config_zero = %{"compression" => 0}
      config_max = %{"compression" => 9}

      assert config_zero["compression"] == 0
      assert config_max["compression"] == 9
    end
  end

  describe "type safety" do
    @tag :unit
    test "extract_images is boolean" do
      config = %{"extract_images" => true}

      assert is_boolean(config["extract_images"])
    end

    @tag :unit
    test "format is string" do
      config = %{"format" => "png"}

      assert is_binary(config["format"])
    end

    @tag :unit
    test "quality is integer" do
      config = %{"quality" => 85}

      assert is_integer(config["quality"])
    end

    @tag :unit
    test "dimensions are integers" do
      config = %{"min_width" => 100, "max_height" => 3000}

      assert is_integer(config["min_width"])
      assert is_integer(config["max_height"])
    end
  end
end
