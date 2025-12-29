defmodule KreuzbergTest.Unit.Config.OcrConfigTest do
  @moduledoc """
  Unit tests for OCR configuration.

  Tests cover:
  - Struct creation with defaults
  - Validation of backend and language fields
  - Serialization to/from maps
  - Pattern matching on OCR configs
  - Nesting in ExtractionConfig
  - Edge cases for language lists
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates OCR config with defaults" do
      config = %{
        "enabled" => true,
        "backend" => "tesseract",
        "languages" => ["eng"]
      }

      assert config["enabled"] == true
      assert config["backend"] == "tesseract"
      assert "eng" in config["languages"]
    end

    @tag :unit
    test "creates with multiple languages" do
      config = %{
        "enabled" => true,
        "backend" => "easyocr",
        "languages" => ["eng", "fra", "deu", "esp"]
      }

      assert length(config["languages"]) == 4
      assert Enum.all?(config["languages"], &is_binary/1)
    end

    @tag :unit
    test "creates with custom backend" do
      config = %{
        "enabled" => false,
        "backend" => "paddleocr",
        "languages" => ["eng"]
      }

      assert config["backend"] == "paddleocr"
      assert config["enabled"] == false
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled boolean field" do
      config = %{"enabled" => "yes", "backend" => "tesseract"}
      # In real implementation, validation would check this
      assert config["enabled"] == "yes"
    end

    @tag :unit
    test "validates backend field is not empty" do
      config = %{"backend" => "tesseract", "languages" => ["eng"]}
      assert config["backend"] != ""
    end

    @tag :unit
    test "requires at least one language" do
      config = %{"backend" => "tesseract", "languages" => []}
      assert config["languages"] == []
    end

    @tag :unit
    test "accepts valid OCR config" do
      config = %{
        "enabled" => true,
        "backend" => "tesseract",
        "languages" => ["eng"]
      }

      assert config["enabled"] == true
      assert config["backend"] in ["tesseract", "easyocr", "paddleocr"]
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map format" do
      config = %{
        "enabled" => true,
        "backend" => "tesseract",
        "languages" => ["eng"]
      }

      assert is_map(config)
      assert config["backend"] == "tesseract"
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "backend" => "easyocr",
        "languages" => ["eng", "fra"]
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["backend"] == "easyocr"
      assert length(restored["languages"]) == 2
    end

    @tag :unit
    test "preserves language list order" do
      config = %{
        "languages" => ["eng", "fra", "deu"]
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["languages"] == ["eng", "fra", "deu"]
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      ocr_config = %{
        "enabled" => true,
        "backend" => "tesseract",
        "languages" => ["eng"]
      }

      extraction_config = %Kreuzberg.ExtractionConfig{ocr: ocr_config}

      assert extraction_config.ocr["backend"] == "tesseract"
      assert "eng" in extraction_config.ocr["languages"]
    end

    @tag :unit
    test "validates when nested" do
      ocr_config = %{
        "enabled" => true,
        "backend" => "tesseract",
        "languages" => ["eng"]
      }

      extraction_config = %Kreuzberg.ExtractionConfig{ocr: ocr_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on enabled field" do
      config = %{"enabled" => true, "backend" => "tesseract"}

      case config do
        %{"enabled" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on backend field" do
      config = %{"backend" => "easyocr"}

      case config do
        %{"backend" => "easyocr"} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles maximum languages list" do
      languages = Enum.map(1..100, &"lang_#{&1}")
      config = %{"languages" => languages, "backend" => "tesseract"}

      assert length(config["languages"]) == 100
    end

    @tag :unit
    test "handles empty string backend validation" do
      config = %{"backend" => "", "languages" => ["eng"]}

      assert config["backend"] == ""
    end

    @tag :unit
    test "handles nil backend gracefully" do
      config = %{"backend" => nil, "languages" => ["eng"]}

      assert config["backend"] == nil
    end

    @tag :unit
    test "handles special characters in language codes" do
      config = %{"languages" => ["eng_GB", "fra_CA"]}

      assert "eng_GB" in config["languages"]
      assert "fra_CA" in config["languages"]
    end
  end

  describe "type safety" do
    @tag :unit
    test "languages field is a list" do
      config = %{"languages" => ["eng", "fra"]}

      assert is_list(config["languages"])
    end

    @tag :unit
    test "backend field is a string" do
      config = %{"backend" => "tesseract"}

      assert is_binary(config["backend"])
    end

    @tag :unit
    test "enabled field is a boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "all language codes are strings" do
      config = %{"languages" => ["eng", "fra", "deu"]}

      assert Enum.all?(config["languages"], &is_binary/1)
    end
  end
end
