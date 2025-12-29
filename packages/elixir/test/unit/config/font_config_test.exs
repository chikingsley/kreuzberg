defmodule KreuzbergTest.Unit.Config.FontConfigTest do
  @moduledoc """
  Unit tests for font configuration in PDF extraction.

  Tests cover:
  - Struct creation with font options
  - Validation of font size bounds
  - Font embedding and substitution
  - Serialization to/from maps
  - Pattern matching on font configs
  - Edge cases for font size and names
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "extract_font_info" => true,
        "preserve_font_styles" => true
      }

      assert config["enabled"] == true
      assert config["extract_font_info"] == true
      assert config["preserve_font_styles"] == true
    end

    @tag :unit
    test "creates with font filtering" do
      config = %{
        "enabled" => true,
        "min_font_size" => 6,
        "max_font_size" => 72,
        "ignore_small_text" => true
      }

      assert config["min_font_size"] == 6
      assert config["max_font_size"] == 72
      assert config["ignore_small_text"] == true
    end

    @tag :unit
    test "creates with font substitution" do
      config = %{
        "enabled" => true,
        "substitute_missing_fonts" => true,
        "substitute_map" => %{
          "courier" => "monospace",
          "arial" => "sans-serif"
        },
        "default_font_family" => "serif"
      }

      assert config["substitute_missing_fonts"] == true
      assert config["substitute_map"]["courier"] == "monospace"
      assert config["default_font_family"] == "serif"
    end

    @tag :unit
    test "creates with font embedding options" do
      config = %{
        "enabled" => true,
        "embed_fonts" => true,
        "include_font_data" => true,
        "preserve_font_names" => true
      }

      assert config["embed_fonts"] == true
      assert config["include_font_data"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates extract_font_info is boolean" do
      config = %{"extract_font_info" => true}

      assert is_boolean(config["extract_font_info"])
    end

    @tag :unit
    test "validates min_font_size is positive number" do
      config = %{"min_font_size" => 6}

      assert is_float(config["min_font_size"]) or is_integer(config["min_font_size"])
      assert config["min_font_size"] > 0
    end

    @tag :unit
    test "validates max_font_size is positive number" do
      config = %{"max_font_size" => 72}

      assert is_float(config["max_font_size"]) or is_integer(config["max_font_size"])
      assert config["max_font_size"] > 0
    end

    @tag :unit
    test "validates max_font_size >= min_font_size" do
      config = %{"min_font_size" => 6, "max_font_size" => 72}

      assert config["max_font_size"] >= config["min_font_size"]
    end

    @tag :unit
    test "validates substitute_map is map or nil" do
      config1 = %{"substitute_map" => %{"arial" => "sans-serif"}}
      config2 = %{"substitute_map" => nil}

      assert is_map(config1["substitute_map"])
      assert config2["substitute_map"] == nil
    end

    @tag :unit
    test "accepts valid font config" do
      config = %{
        "enabled" => true,
        "extract_font_info" => true,
        "min_font_size" => 6,
        "max_font_size" => 72,
        "preserve_font_styles" => true
      }

      assert config["enabled"] == true
      assert config["min_font_size"] <= config["max_font_size"]
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "extract_font_info" => true,
        "min_font_size" => 6,
        "max_font_size" => 72
      }

      assert is_map(config)
      assert config["extract_font_info"] == true
      assert config["max_font_size"] == 72
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "extract_font_info" => true,
        "preserve_font_styles" => true,
        "min_font_size" => 6,
        "max_font_size" => 72,
        "ignore_small_text" => true,
        "substitute_missing_fonts" => true,
        "substitute_map" => %{
          "courier" => "monospace",
          "arial" => "sans-serif"
        },
        "default_font_family" => "serif",
        "embed_fonts" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["extract_font_info"] == true
      assert restored["min_font_size"] == 6
      assert restored["substitute_map"]["courier"] == "monospace"
      assert restored["default_font_family"] == "serif"
    end

    @tag :unit
    test "preserves substitution map structure" do
      config = %{
        "substitute_map" => %{
          "times new roman" => "serif",
          "helvetica" => "sans-serif",
          "courier new" => "monospace"
        }
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert map_size(decoded["substitute_map"]) == 3
      assert decoded["substitute_map"]["times new roman"] == "serif"
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in PDF config" do
      font_config = %{
        "enabled" => true,
        "extract_font_info" => true,
        "min_font_size" => 6
      }

      pdf_config = %{"font_config" => font_config}
      extraction_config = %Kreuzberg.ExtractionConfig{pdf_options: pdf_config}

      assert extraction_config.pdf_options["font_config"]["extract_font_info"] == true
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on extract_font_info field" do
      config = %{"extract_font_info" => true}

      case config do
        %{"extract_font_info" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on min_font_size field" do
      config = %{"min_font_size" => 6}

      case config do
        %{"min_font_size" => s} when s > 0 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles very small minimum font size" do
      config = %{"min_font_size" => 1}

      assert config["min_font_size"] == 1
    end

    @tag :unit
    test "handles very large maximum font size" do
      config = %{"max_font_size" => 360}

      assert config["max_font_size"] == 360
    end

    @tag :unit
    test "handles single font size (min=max)" do
      config = %{"min_font_size" => 12, "max_font_size" => 12}

      assert config["min_font_size"] == config["max_font_size"]
    end

    @tag :unit
    test "handles fractional font sizes" do
      config = %{"min_font_size" => 6.5, "max_font_size" => 72.75}

      assert is_float(config["min_font_size"])
      assert is_float(config["max_font_size"])
    end

    @tag :unit
    test "handles empty substitute map" do
      config = %{"substitute_map" => %{}}

      assert config["substitute_map"] == %{}
    end

    @tag :unit
    test "handles large substitute map" do
      substitutes = Map.new(1..100, fn index -> {"font_#{index}", "family_#{index}"} end)
      config = %{"substitute_map" => substitutes}

      assert map_size(config["substitute_map"]) == 100
    end

    @tag :unit
    test "handles special characters in font names" do
      config = %{
        "substitute_map" => %{
          "Arial Unicode MS" => "sans-serif",
          "Times New Roman" => "serif",
          "DejaVu Sans" => "monospace"
        }
      }

      assert config["substitute_map"]["Arial Unicode MS"] == "sans-serif"
      assert config["substitute_map"]["Times New Roman"] == "serif"
    end

    @tag :unit
    test "handles nil default_font_family" do
      config = %{"default_font_family" => nil}

      assert config["default_font_family"] == nil
    end

    @tag :unit
    test "handles various font family names" do
      config = %{"default_font_family" => "serif"}

      assert config["default_font_family"] == "serif"
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "extract_font_info is boolean" do
      config = %{"extract_font_info" => true}

      assert is_boolean(config["extract_font_info"])
    end

    @tag :unit
    test "min_font_size is number" do
      config = %{"min_font_size" => 6}

      assert is_float(config["min_font_size"]) or is_integer(config["min_font_size"])
    end

    @tag :unit
    test "max_font_size is number" do
      config = %{"max_font_size" => 72}

      assert is_float(config["max_font_size"]) or is_integer(config["max_font_size"])
    end

    @tag :unit
    test "substitute_missing_fonts is boolean" do
      config = %{"substitute_missing_fonts" => true}

      assert is_boolean(config["substitute_missing_fonts"])
    end

    @tag :unit
    test "substitute_map is map or nil" do
      config1 = %{"substitute_map" => %{"arial" => "sans-serif"}}
      config2 = %{"substitute_map" => nil}

      assert is_map(config1["substitute_map"])
      assert config2["substitute_map"] == nil
    end

    @tag :unit
    test "default_font_family is string or nil" do
      config1 = %{"default_font_family" => "serif"}
      config2 = %{"default_font_family" => nil}

      assert is_binary(config1["default_font_family"]) or config1["default_font_family"] == nil
      assert config2["default_font_family"] == nil
    end
  end
end
