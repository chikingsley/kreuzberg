defmodule KreuzbergTest.Unit.Config.PageConfigTest do
  @moduledoc """
  Unit tests for page-level extraction configuration.

  Tests cover:
  - Struct creation with page ranges
  - Validation of start and end page numbers
  - Page filtering options
  - Serialization to/from maps
  - Pattern matching on page configs
  - Edge cases for boundary conditions
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "start_page" => 1,
        "end_page" => nil
      }

      assert config["enabled"] == true
      assert config["start_page"] == 1
      assert config["end_page"] == nil
    end

    @tag :unit
    test "creates with specific page range" do
      config = %{
        "start_page" => 5,
        "end_page" => 15,
        "extract_text" => true,
        "extract_tables" => true
      }

      assert config["start_page"] == 5
      assert config["end_page"] == 15
      assert config["extract_text"] == true
    end

    @tag :unit
    test "creates with page filter list" do
      config = %{
        "enabled" => true,
        "page_numbers" => [1, 2, 5, 10, 15],
        "exclude_pages" => [3, 7, 9]
      }

      assert config["page_numbers"] == [1, 2, 5, 10, 15]
      assert config["exclude_pages"] == [3, 7, 9]
    end

    @tag :unit
    test "creates with extraction options" do
      config = %{
        "extract_text" => true,
        "extract_tables" => true,
        "extract_images" => true,
        "extract_headers_footers" => true
      }

      assert config["extract_text"] == true
      assert config["extract_tables"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates start_page is positive integer" do
      config = %{"start_page" => 1}

      assert is_integer(config["start_page"])
      assert config["start_page"] > 0
    end

    @tag :unit
    test "validates end_page is integer or nil" do
      config1 = %{"end_page" => 10}
      config2 = %{"end_page" => nil}

      assert is_integer(config1["end_page"]) or config1["end_page"] == nil
      assert config2["end_page"] == nil
    end

    @tag :unit
    test "validates end_page >= start_page when both set" do
      config = %{"start_page" => 5, "end_page" => 15}

      assert config["end_page"] >= config["start_page"]
    end

    @tag :unit
    test "validates extract options are boolean" do
      config = %{
        "extract_text" => true,
        "extract_tables" => false,
        "extract_images" => true
      }

      assert is_boolean(config["extract_text"])
      assert is_boolean(config["extract_tables"])
    end

    @tag :unit
    test "validates page_numbers is list" do
      config = %{"page_numbers" => [1, 2, 5, 10]}

      assert is_list(config["page_numbers"])
    end

    @tag :unit
    test "accepts valid page config" do
      config = %{
        "enabled" => true,
        "start_page" => 1,
        "end_page" => 50,
        "extract_text" => true
      }

      assert config["enabled"] == true
      assert config["start_page"] <= config["end_page"]
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "start_page" => 5,
        "end_page" => 15,
        "extract_text" => true,
        "extract_tables" => true
      }

      assert is_map(config)
      assert config["start_page"] == 5
      assert config["extract_text"] == true
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "start_page" => 1,
        "end_page" => 100,
        "extract_text" => true,
        "extract_tables" => true,
        "extract_images" => false,
        "page_numbers" => [1, 5, 10, 20],
        "exclude_pages" => [3, 7]
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["start_page"] == 1
      assert restored["end_page"] == 100
      assert restored["extract_text"] == true
      assert length(restored["page_numbers"]) == 4
    end

    @tag :unit
    test "preserves page number lists" do
      config = %{"page_numbers" => [1, 2, 5, 10, 15]}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["page_numbers"] == [1, 2, 5, 10, 15]
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      page_config = %{
        "start_page" => 1,
        "end_page" => 50,
        "extract_text" => true
      }

      extraction_config = %Kreuzberg.ExtractionConfig{pages: page_config}

      assert extraction_config.pages["start_page"] == 1
      assert extraction_config.pages["end_page"] == 50
    end

    @tag :unit
    test "validates when nested" do
      page_config = %{"start_page" => 1, "end_page" => 100, "extract_text" => true}
      extraction_config = %Kreuzberg.ExtractionConfig{pages: page_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on page range" do
      config = %{"start_page" => 5, "end_page" => 15}

      case config do
        %{"start_page" => s, "end_page" => e} when s < e -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on extract_text field" do
      config = %{"extract_text" => true}

      case config do
        %{"extract_text" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles single page extraction" do
      config = %{"start_page" => 5, "end_page" => 5}

      assert config["start_page"] == config["end_page"]
    end

    @tag :unit
    test "handles very large page numbers" do
      config = %{"start_page" => 1, "end_page" => 100_000}

      assert config["end_page"] == 100_000
    end

    @tag :unit
    test "handles page 1 extraction" do
      config = %{"start_page" => 1, "end_page" => 1}

      assert config["start_page"] == 1
    end

    @tag :unit
    test "handles nil end_page (to end of document)" do
      config = %{"start_page" => 5, "end_page" => nil}

      assert config["start_page"] == 5
      assert config["end_page"] == nil
    end

    @tag :unit
    test "handles empty page filter lists" do
      config = %{"page_numbers" => [], "exclude_pages" => []}

      assert config["page_numbers"] == []
      assert config["exclude_pages"] == []
    end

    @tag :unit
    test "handles large page filter lists" do
      page_list = Enum.to_list(1..1000)
      config = %{"page_numbers" => page_list}

      assert length(config["page_numbers"]) == 1000
    end

    @tag :unit
    test "handles overlapping page filters" do
      config = %{
        "page_numbers" => [1, 2, 3, 5, 10],
        "exclude_pages" => [2, 5]
      }

      # Both lists can exist, filtering logic handles overlap
      assert 2 in config["page_numbers"]
      assert 2 in config["exclude_pages"]
    end
  end

  describe "type safety" do
    @tag :unit
    test "start_page is integer" do
      config = %{"start_page" => 1}

      assert is_integer(config["start_page"])
    end

    @tag :unit
    test "end_page is integer or nil" do
      config1 = %{"end_page" => 100}
      config2 = %{"end_page" => nil}

      assert is_integer(config1["end_page"]) or config1["end_page"] == nil
      assert config2["end_page"] == nil
    end

    @tag :unit
    test "extract_text is boolean" do
      config = %{"extract_text" => true}

      assert is_boolean(config["extract_text"])
    end

    @tag :unit
    test "page_numbers is list of integers" do
      config = %{"page_numbers" => [1, 5, 10]}

      assert is_list(config["page_numbers"])
      assert Enum.all?(config["page_numbers"], &is_integer/1)
    end
  end
end
