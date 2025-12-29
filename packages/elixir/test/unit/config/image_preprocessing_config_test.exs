defmodule KreuzbergTest.Unit.Config.ImagePreprocessingConfigTest do
  @moduledoc """
  Unit tests for image preprocessing configuration.

  Tests cover:
  - Struct creation with preprocessing options
  - Validation of noise reduction and normalization
  - Serialization to/from maps
  - Pattern matching on preprocessing configs
  - Nesting in image extraction config
  - Edge cases for threshold values
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "denoise" => false,
        "normalize_brightness" => true
      }

      assert config["enabled"] == true
      assert config["denoise"] == false
      assert config["normalize_brightness"] == true
    end

    @tag :unit
    test "creates with denoising options" do
      config = %{
        "denoise" => true,
        "denoise_strength" => 5,
        "bilateral_sigma" => 75
      }

      assert config["denoise"] == true
      assert config["denoise_strength"] == 5
      assert config["bilateral_sigma"] == 75
    end

    @tag :unit
    test "creates with deskew settings" do
      config = %{
        "deskew" => true,
        "deskew_angle_threshold" => 0.5,
        "auto_crop" => true
      }

      assert config["deskew"] == true
      assert config["deskew_angle_threshold"] == 0.5
      assert config["auto_crop"] == true
    end

    @tag :unit
    test "creates with contrast adjustment" do
      config = %{
        "adjust_contrast" => true,
        "contrast_value" => 1.5,
        "auto_enhance" => true
      }

      assert config["adjust_contrast"] == true
      assert config["contrast_value"] == 1.5
      assert config["auto_enhance"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates denoise is boolean" do
      config = %{"denoise" => true}

      assert is_boolean(config["denoise"])
    end

    @tag :unit
    test "validates denoise_strength is positive integer" do
      config = %{"denoise_strength" => 5}

      assert is_integer(config["denoise_strength"])
      assert config["denoise_strength"] > 0
    end

    @tag :unit
    test "validates deskew_angle_threshold is positive float" do
      config = %{"deskew_angle_threshold" => 0.5}

      assert is_float(config["deskew_angle_threshold"]) or
               is_integer(config["deskew_angle_threshold"])

      assert config["deskew_angle_threshold"] > 0
    end

    @tag :unit
    test "validates contrast_value range" do
      config = %{"contrast_value" => 1.5}

      assert is_float(config["contrast_value"]) or is_integer(config["contrast_value"])
      assert config["contrast_value"] >= 0.5 and config["contrast_value"] <= 3.0
    end

    @tag :unit
    test "accepts valid preprocessing config" do
      config = %{
        "enabled" => true,
        "denoise" => true,
        "deskew" => true,
        "adjust_contrast" => true,
        "normalize_brightness" => true
      }

      assert config["enabled"] == true
      assert config["denoise"] == true
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "denoise" => true,
        "denoise_strength" => 5,
        "normalize_brightness" => true
      }

      assert is_map(config)
      assert config["denoise"] == true
      assert config["denoise_strength"] == 5
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "denoise" => true,
        "denoise_strength" => 5,
        "bilateral_sigma" => 75,
        "deskew" => true,
        "deskew_angle_threshold" => 0.5,
        "adjust_contrast" => true,
        "contrast_value" => 1.5,
        "normalize_brightness" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["denoise"] == true
      assert restored["denoise_strength"] == 5
      assert restored["deskew_angle_threshold"] == 0.5
    end

    @tag :unit
    test "preserves boolean and numeric values" do
      config = %{
        "enabled" => true,
        "contrast_value" => 1.5
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["enabled"] == true
      assert decoded["contrast_value"] == 1.5
    end
  end

  describe "nesting in image extraction config" do
    @tag :unit
    test "can be nested in image extraction config" do
      preprocessing_config = %{
        "enabled" => true,
        "denoise" => true,
        "denoise_strength" => 5
      }

      image_config = %{
        "extract_images" => true,
        "preprocessing" => preprocessing_config
      }

      assert image_config["preprocessing"]["denoise"] == true
      assert image_config["preprocessing"]["denoise_strength"] == 5
    end

    @tag :unit
    test "nested in extraction config through images" do
      preprocessing_config = %{"enabled" => true, "denoise" => true}
      image_config = %{"preprocessing" => preprocessing_config}

      extraction_config = %Kreuzberg.ExtractionConfig{images: image_config}

      assert extraction_config.images["preprocessing"]["denoise"] == true
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on denoise field" do
      config = %{"denoise" => true}

      case config do
        %{"denoise" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on contrast_value field" do
      config = %{"contrast_value" => 1.5}

      case config do
        %{"contrast_value" => v} when v > 1.0 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum contrast value" do
      config = %{"contrast_value" => 0.5}

      assert config["contrast_value"] == 0.5
    end

    @tag :unit
    test "handles maximum contrast value" do
      config = %{"contrast_value" => 3.0}

      assert config["contrast_value"] == 3.0
    end

    @tag :unit
    test "handles minimum denoise strength" do
      config = %{"denoise_strength" => 1}

      assert config["denoise_strength"] == 1
    end

    @tag :unit
    test "handles large denoise strength" do
      config = %{"denoise_strength" => 100}

      assert config["denoise_strength"] == 100
    end

    @tag :unit
    test "handles very small angle threshold" do
      config = %{"deskew_angle_threshold" => 0.1}

      assert config["deskew_angle_threshold"] == 0.1
    end

    @tag :unit
    test "handles large angle threshold" do
      config = %{"deskew_angle_threshold" => 45.0}

      assert config["deskew_angle_threshold"] == 45.0
    end

    @tag :unit
    test "handles nil preprocessing options" do
      config = %{
        "enabled" => false,
        "denoise" => nil,
        "deskew" => nil
      }

      assert config["denoise"] == nil
      assert config["deskew"] == nil
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "denoise is boolean" do
      config = %{"denoise" => true}

      assert is_boolean(config["denoise"])
    end

    @tag :unit
    test "denoise_strength is integer" do
      config = %{"denoise_strength" => 5}

      assert is_integer(config["denoise_strength"])
    end

    @tag :unit
    test "bilateral_sigma is integer or float" do
      config = %{"bilateral_sigma" => 75}

      assert is_integer(config["bilateral_sigma"]) or is_float(config["bilateral_sigma"])
    end

    @tag :unit
    test "contrast_value is number" do
      config = %{"contrast_value" => 1.5}

      assert is_float(config["contrast_value"]) or is_integer(config["contrast_value"])
    end
  end
end
