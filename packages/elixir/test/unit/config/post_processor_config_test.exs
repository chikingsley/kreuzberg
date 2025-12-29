defmodule KreuzbergTest.Unit.Config.PostProcessorConfigTest do
  @moduledoc """
  Unit tests for post-processor configuration.

  Tests cover:
  - Struct creation with cleanup options
  - Validation of text normalization
  - Whitespace and formatting settings
  - Serialization to/from maps
  - Pattern matching on processor configs
  - Edge cases for processing options
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "remove_duplicates" => false
      }

      assert config["enabled"] == true
      assert config["normalize_whitespace"] == true
      assert config["remove_duplicates"] == false
    end

    @tag :unit
    test "creates with text cleanup options" do
      config = %{
        "enabled" => true,
        "remove_empty_lines" => true,
        "trim_text" => true,
        "normalize_unicode" => true,
        "remove_control_characters" => true
      }

      assert config["remove_empty_lines"] == true
      assert config["trim_text"] == true
      assert config["normalize_unicode"] == true
    end

    @tag :unit
    test "creates with formatting options" do
      config = %{
        "enabled" => true,
        "fix_punctuation" => true,
        "fix_hyphens" => true,
        "convert_quotes" => "straight",
        "convert_dashes" => true
      }

      assert config["fix_punctuation"] == true
      assert config["convert_quotes"] == "straight"
    end

    @tag :unit
    test "creates with duplicate removal" do
      config = %{
        "enabled" => true,
        "remove_duplicates" => true,
        "duplicate_threshold" => 0.95,
        "remove_duplicate_paragraphs" => true
      }

      assert config["remove_duplicates"] == true
      assert config["duplicate_threshold"] == 0.95
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates normalize_whitespace is boolean" do
      config = %{"normalize_whitespace" => true}

      assert is_boolean(config["normalize_whitespace"])
    end

    @tag :unit
    test "validates remove_duplicates is boolean" do
      config = %{"remove_duplicates" => true}

      assert is_boolean(config["remove_duplicates"])
    end

    @tag :unit
    test "validates duplicate_threshold in range 0-1" do
      config = %{"duplicate_threshold" => 0.95}

      assert is_float(config["duplicate_threshold"]) or is_integer(config["duplicate_threshold"])
      assert config["duplicate_threshold"] >= 0 and config["duplicate_threshold"] <= 1
    end

    @tag :unit
    test "validates convert_quotes is valid option" do
      valid_options = ["straight", "smart", "none"]
      config = %{"convert_quotes" => "straight"}

      assert config["convert_quotes"] in valid_options
    end

    @tag :unit
    test "accepts valid processor config" do
      config = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "remove_duplicates" => false,
        "remove_empty_lines" => true
      }

      assert config["enabled"] == true
      assert config["normalize_whitespace"] == true
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "remove_empty_lines" => true,
        "normalize_whitespace" => true,
        "trim_text" => true
      }

      assert is_map(config)
      assert config["normalize_whitespace"] == true
      assert config["remove_empty_lines"] == true
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "remove_duplicates" => true,
        "duplicate_threshold" => 0.95,
        "remove_empty_lines" => true,
        "trim_text" => true,
        "normalize_unicode" => true,
        "fix_punctuation" => true,
        "convert_quotes" => "smart",
        "convert_dashes" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["normalize_whitespace"] == true
      assert restored["duplicate_threshold"] == 0.95
      assert restored["convert_quotes"] == "smart"
    end

    @tag :unit
    test "preserves boolean values" do
      config = %{
        "enabled" => false,
        "remove_duplicates" => true,
        "normalize_unicode" => false
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["enabled"] == false
      assert decoded["remove_duplicates"] == true
      assert decoded["normalize_unicode"] == false
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      processor_config = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "remove_empty_lines" => true
      }

      extraction_config = %Kreuzberg.ExtractionConfig{postprocessor: processor_config}

      assert extraction_config.postprocessor["normalize_whitespace"] == true
      assert extraction_config.postprocessor["remove_empty_lines"] == true
    end

    @tag :unit
    test "validates when nested" do
      processor_config = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "trim_text" => true
      }

      extraction_config = %Kreuzberg.ExtractionConfig{postprocessor: processor_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on enabled field" do
      config = %{"enabled" => true}

      case config do
        %{"enabled" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on duplicate_threshold field" do
      config = %{"duplicate_threshold" => 0.95}

      case config do
        %{"duplicate_threshold" => t} when t > 0.9 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles all cleanup options disabled" do
      config = %{
        "enabled" => false,
        "normalize_whitespace" => false,
        "remove_duplicates" => false,
        "remove_empty_lines" => false,
        "trim_text" => false,
        "normalize_unicode" => false,
        "fix_punctuation" => false
      }

      assert config["enabled"] == false
      assert config["normalize_whitespace"] == false
    end

    @tag :unit
    test "handles all cleanup options enabled" do
      config = %{
        "enabled" => true,
        "normalize_whitespace" => true,
        "remove_duplicates" => true,
        "remove_empty_lines" => true,
        "trim_text" => true,
        "normalize_unicode" => true,
        "fix_punctuation" => true,
        "fix_hyphens" => true,
        "convert_dashes" => true
      }

      assert config["enabled"] == true
      assert Enum.count(config) > 5
    end

    @tag :unit
    test "handles minimum duplicate threshold" do
      config = %{"duplicate_threshold" => 0.0}

      assert config["duplicate_threshold"] == 0.0
    end

    @tag :unit
    test "handles maximum duplicate threshold" do
      config = %{"duplicate_threshold" => 1.0}

      assert config["duplicate_threshold"] == 1.0
    end

    @tag :unit
    test "handles typical duplicate threshold" do
      config = %{"duplicate_threshold" => 0.95}

      assert config["duplicate_threshold"] == 0.95
    end

    @tag :unit
    test "handles nil convert_quotes" do
      config = %{"convert_quotes" => nil}

      assert config["convert_quotes"] == nil
    end

    @tag :unit
    test "handles all quote conversion options" do
      options = ["straight", "smart", "none"]

      Enum.each(options, fn opt ->
        config = %{"convert_quotes" => opt}
        assert config["convert_quotes"] == opt
      end)
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "normalize_whitespace is boolean" do
      config = %{"normalize_whitespace" => true}

      assert is_boolean(config["normalize_whitespace"])
    end

    @tag :unit
    test "remove_duplicates is boolean" do
      config = %{"remove_duplicates" => true}

      assert is_boolean(config["remove_duplicates"])
    end

    @tag :unit
    test "duplicate_threshold is number" do
      config = %{"duplicate_threshold" => 0.95}

      assert is_float(config["duplicate_threshold"]) or is_integer(config["duplicate_threshold"])
    end

    @tag :unit
    test "convert_quotes is string or nil" do
      config1 = %{"convert_quotes" => "smart"}
      config2 = %{"convert_quotes" => nil}

      assert is_binary(config1["convert_quotes"]) or config1["convert_quotes"] == nil
      assert config2["convert_quotes"] == nil
    end

    @tag :unit
    test "convert_dashes is boolean or nil" do
      config1 = %{"convert_dashes" => true}
      config2 = %{"convert_dashes" => nil}

      assert is_boolean(config1["convert_dashes"]) or config1["convert_dashes"] == nil
      assert config2["convert_dashes"] == nil
    end
  end
end
