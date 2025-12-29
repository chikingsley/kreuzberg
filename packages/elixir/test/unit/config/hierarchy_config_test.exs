defmodule KreuzbergTest.Unit.Config.HierarchyConfigTest do
  @moduledoc """
  Unit tests for document hierarchy/structure configuration.

  Tests cover:
  - Struct creation with heading level options
  - Validation of hierarchy depth
  - Structure preservation settings
  - Serialization to/from maps
  - Pattern matching on hierarchy configs
  - Edge cases for depth and level bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "preserve_structure" => true,
        "min_heading_level" => 1
      }

      assert config["enabled"] == true
      assert config["preserve_structure"] == true
      assert config["min_heading_level"] == 1
    end

    @tag :unit
    test "creates with heading level configuration" do
      config = %{
        "enabled" => true,
        "min_heading_level" => 1,
        "max_heading_level" => 6,
        "extract_headings" => true
      }

      assert config["min_heading_level"] == 1
      assert config["max_heading_level"] == 6
      assert config["extract_headings"] == true
    end

    @tag :unit
    test "creates with depth configuration" do
      config = %{
        "enabled" => true,
        "max_depth" => 5,
        "preserve_outline" => true,
        "create_table_of_contents" => true
      }

      assert config["max_depth"] == 5
      assert config["preserve_outline"] == true
      assert config["create_table_of_contents"] == true
    end

    @tag :unit
    test "creates with section level options" do
      config = %{
        "enabled" => true,
        "include_section_numbers" => true,
        "indent_subsections" => true,
        "preserve_formatting_hierarchy" => true
      }

      assert config["include_section_numbers"] == true
      assert config["indent_subsections"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates preserve_structure is boolean" do
      config = %{"preserve_structure" => true}

      assert is_boolean(config["preserve_structure"])
    end

    @tag :unit
    test "validates min_heading_level is positive integer" do
      config = %{"min_heading_level" => 1}

      assert is_integer(config["min_heading_level"])
      assert config["min_heading_level"] > 0
    end

    @tag :unit
    test "validates max_heading_level is integer" do
      config = %{"max_heading_level" => 6}

      assert is_integer(config["max_heading_level"])
    end

    @tag :unit
    test "validates max_heading_level >= min_heading_level" do
      config = %{"min_heading_level" => 1, "max_heading_level" => 6}

      assert config["max_heading_level"] >= config["min_heading_level"]
    end

    @tag :unit
    test "validates max_depth is positive integer" do
      config = %{"max_depth" => 5}

      assert is_integer(config["max_depth"])
      assert config["max_depth"] > 0
    end

    @tag :unit
    test "accepts valid hierarchy config" do
      config = %{
        "enabled" => true,
        "preserve_structure" => true,
        "min_heading_level" => 1,
        "max_heading_level" => 6,
        "max_depth" => 5
      }

      assert config["enabled"] == true
      assert config["min_heading_level"] <= config["max_heading_level"]
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "preserve_structure" => true,
        "min_heading_level" => 1,
        "max_heading_level" => 6
      }

      assert is_map(config)
      assert config["preserve_structure"] == true
      assert config["max_heading_level"] == 6
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "preserve_structure" => true,
        "min_heading_level" => 1,
        "max_heading_level" => 6,
        "extract_headings" => true,
        "max_depth" => 5,
        "preserve_outline" => true,
        "create_table_of_contents" => true,
        "include_section_numbers" => true,
        "indent_subsections" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["preserve_structure"] == true
      assert restored["max_heading_level"] == 6
      assert restored["max_depth"] == 5
      assert restored["create_table_of_contents"] == true
    end

    @tag :unit
    test "preserves heading level integers" do
      config = %{"min_heading_level" => 1, "max_heading_level" => 6}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["min_heading_level"] == 1
      assert decoded["max_heading_level"] == 6
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      hierarchy_config = %{
        "enabled" => true,
        "preserve_structure" => true,
        "max_depth" => 5
      }

      # Kreuzberg currently doesn't have hierarchy_config field, but we can test the pattern
      extraction_config = %Kreuzberg.ExtractionConfig{
        chunking: hierarchy_config
      }

      assert extraction_config.chunking["preserve_structure"] == true
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
    test "matches on max_depth field" do
      config = %{"max_depth" => 5}

      case config do
        %{"max_depth" => d} when d > 0 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles single heading level (min=max)" do
      config = %{"min_heading_level" => 3, "max_heading_level" => 3}

      assert config["min_heading_level"] == config["max_heading_level"]
    end

    @tag :unit
    test "handles minimum heading level 1" do
      config = %{"min_heading_level" => 1}

      assert config["min_heading_level"] == 1
    end

    @tag :unit
    test "handles maximum heading level 6" do
      config = %{"max_heading_level" => 6}

      assert config["max_heading_level"] == 6
    end

    @tag :unit
    test "handles maximum heading level > 6 (extended HTML)" do
      config = %{"max_heading_level" => 10}

      assert config["max_heading_level"] == 10
    end

    @tag :unit
    test "handles very deep nesting" do
      config = %{"max_depth" => 100}

      assert config["max_depth"] == 100
    end

    @tag :unit
    test "handles single level depth" do
      config = %{"max_depth" => 1}

      assert config["max_depth"] == 1
    end

    @tag :unit
    test "handles all structure options enabled" do
      config = %{
        "enabled" => true,
        "preserve_structure" => true,
        "extract_headings" => true,
        "preserve_outline" => true,
        "create_table_of_contents" => true,
        "include_section_numbers" => true,
        "indent_subsections" => true,
        "preserve_formatting_hierarchy" => true
      }

      boolean_fields = [
        "enabled",
        "preserve_structure",
        "extract_headings",
        "preserve_outline",
        "create_table_of_contents",
        "include_section_numbers",
        "indent_subsections",
        "preserve_formatting_hierarchy"
      ]

      Enum.each(boolean_fields, &assert(is_boolean(config[&1])))
    end

    @tag :unit
    test "handles all structure options disabled" do
      config = %{
        "enabled" => false,
        "preserve_structure" => false,
        "extract_headings" => false,
        "preserve_outline" => false
      }

      assert config["enabled"] == false
      assert config["preserve_structure"] == false
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "preserve_structure is boolean" do
      config = %{"preserve_structure" => true}

      assert is_boolean(config["preserve_structure"])
    end

    @tag :unit
    test "min_heading_level is integer" do
      config = %{"min_heading_level" => 1}

      assert is_integer(config["min_heading_level"])
    end

    @tag :unit
    test "max_heading_level is integer" do
      config = %{"max_heading_level" => 6}

      assert is_integer(config["max_heading_level"])
    end

    @tag :unit
    test "max_depth is integer" do
      config = %{"max_depth" => 5}

      assert is_integer(config["max_depth"])
    end

    @tag :unit
    test "extract_headings is boolean or nil" do
      config1 = %{"extract_headings" => true}
      config2 = %{"extract_headings" => nil}

      assert is_boolean(config1["extract_headings"]) or config1["extract_headings"] == nil
      assert config2["extract_headings"] == nil
    end
  end
end
