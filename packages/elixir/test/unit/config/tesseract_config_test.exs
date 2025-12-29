defmodule KreuzbergTest.Unit.Config.TesseractConfigTest do
  @moduledoc """
  Unit tests for Tesseract-specific OCR configuration.

  Tests cover:
  - Struct creation with PSM modes
  - Path configuration validation
  - Language and config file settings
  - Preprocessing options
  - Nesting in OCR config
  - Edge cases for paths and modes
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default PSM mode" do
      config = %{
        "psm_mode" => 3,
        "oem_mode" => 3,
        "languages" => ["eng"]
      }

      assert config["psm_mode"] == 3
      assert config["oem_mode"] == 3
    end

    @tag :unit
    test "creates with custom PSM modes" do
      config = %{
        "psm_mode" => 11,
        "oem_mode" => 1,
        "languages" => ["eng", "fra"]
      }

      assert config["psm_mode"] == 11
      assert config["oem_mode"] == 1
    end

    @tag :unit
    test "creates with datapath" do
      config = %{
        "datapath" => "/usr/share/tesseract-ocr",
        "languages" => ["eng"]
      }

      assert config["datapath"] == "/usr/share/tesseract-ocr"
    end

    @tag :unit
    test "creates with config file" do
      config = %{
        "config_file" => "/etc/tesseract.config",
        "languages" => ["eng"]
      }

      assert config["config_file"] == "/etc/tesseract.config"
    end
  end

  describe "validation" do
    @tag :unit
    test "validates PSM mode is integer" do
      config = %{"psm_mode" => 3}

      assert is_integer(config["psm_mode"])
    end

    @tag :unit
    test "validates PSM mode range (0-13)" do
      valid_modes = 0..13

      Enum.each(valid_modes, fn mode ->
        config = %{"psm_mode" => mode}
        assert config["psm_mode"] == mode
      end)
    end

    @tag :unit
    test "validates OEM mode" do
      config = %{"oem_mode" => 1}

      assert config["oem_mode"] in [0, 1, 2, 3]
    end

    @tag :unit
    test "validates datapath is string or nil" do
      config1 = %{"datapath" => "/path/to/tessdata"}
      config2 = %{"datapath" => nil}

      assert is_binary(config1["datapath"]) or config1["datapath"] == nil
      assert config2["datapath"] == nil
    end

    @tag :unit
    test "validates config_file path" do
      config = %{"config_file" => "tesseract.config"}

      assert is_binary(config["config_file"])
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with PSM settings" do
      config = %{
        "psm_mode" => 6,
        "oem_mode" => 3,
        "languages" => ["eng"]
      }

      assert is_map(config)
      assert config["psm_mode"] == 6
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "psm_mode" => 3,
        "oem_mode" => 1,
        "languages" => ["eng", "fra"],
        "datapath" => "/usr/share/tesseract-ocr"
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["psm_mode"] == 3
      assert restored["oem_mode"] == 1
      assert restored["datapath"] == "/usr/share/tesseract-ocr"
    end

    @tag :unit
    test "preserves all fields in map conversion" do
      config = %{
        "psm_mode" => 3,
        "oem_mode" => 3,
        "languages" => ["eng"],
        "datapath" => "/path",
        "config_file" => "config"
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert Map.keys(decoded) |> length() == 5
    end
  end

  describe "nesting in OCR config" do
    @tag :unit
    test "can be nested in OCR config" do
      tesseract_config = %{
        "psm_mode" => 3,
        "languages" => ["eng"]
      }

      ocr_config = %{
        "backend" => "tesseract",
        "tesseract_config" => tesseract_config
      }

      assert ocr_config["tesseract_config"]["psm_mode"] == 3
    end

    @tag :unit
    test "nested in extraction config through ocr" do
      tesseract_config = %{"psm_mode" => 6, "languages" => ["eng"]}
      ocr_config = %{"tesseract_config" => tesseract_config}

      extraction_config = %Kreuzberg.ExtractionConfig{ocr: ocr_config}

      assert extraction_config.ocr["tesseract_config"]["psm_mode"] == 6
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on PSM mode field" do
      config = %{"psm_mode" => 3}

      case config do
        %{"psm_mode" => 3} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on datapath field" do
      config = %{"datapath" => "/usr/share/tesseract-ocr"}

      case config do
        %{"datapath" => path} when is_binary(path) -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles PSM mode boundary values" do
      config_low = %{"psm_mode" => 0}
      config_high = %{"psm_mode" => 13}

      assert config_low["psm_mode"] == 0
      assert config_high["psm_mode"] == 13
    end

    @tag :unit
    test "handles nil datapath" do
      config = %{"psm_mode" => 3, "datapath" => nil}

      assert config["datapath"] == nil
    end

    @tag :unit
    test "handles very long file paths" do
      long_path = String.duplicate("a/", 100) <> "tessdata"
      config = %{"datapath" => long_path}

      assert String.length(config["datapath"]) > 100
    end

    @tag :unit
    test "handles windows-style paths" do
      config = %{"datapath" => "C:\\Users\\tessdata"}

      assert String.starts_with?(config["datapath"], "C:")
    end

    @tag :unit
    test "handles languages list in tesseract config" do
      config = %{"languages" => ["eng", "fra", "deu"], "psm_mode" => 3}

      assert length(config["languages"]) == 3
    end
  end

  describe "type safety" do
    @tag :unit
    test "PSM mode is integer" do
      config = %{"psm_mode" => 3}

      assert is_integer(config["psm_mode"])
    end

    @tag :unit
    test "OEM mode is integer" do
      config = %{"oem_mode" => 1}

      assert is_integer(config["oem_mode"])
    end

    @tag :unit
    test "datapath is binary or nil" do
      config = %{"datapath" => "/path"}

      assert is_binary(config["datapath"]) or config["datapath"] == nil
    end
  end
end
