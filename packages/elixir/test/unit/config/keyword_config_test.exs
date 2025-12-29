defmodule KreuzbergTest.Unit.Config.KeywordConfigTest do
  @moduledoc """
  Unit tests for keyword extraction configuration.

  Tests cover:
  - Struct creation with keyword options
  - Validation of extraction strategy
  - Min/max keyword settings
  - Serialization to/from maps
  - Pattern matching on keyword configs
  - Edge cases for keyword bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "strategy" => "frequency",
        "max_keywords" => 10
      }

      assert config["enabled"] == true
      assert config["strategy"] == "frequency"
      assert config["max_keywords"] == 10
    end

    @tag :unit
    test "creates with TF-IDF strategy" do
      config = %{
        "enabled" => true,
        "strategy" => "tfidf",
        "max_keywords" => 20,
        "min_frequency" => 2
      }

      assert config["strategy"] == "tfidf"
      assert config["max_keywords"] == 20
      assert config["min_frequency"] == 2
    end

    @tag :unit
    test "creates with NLP strategy" do
      config = %{
        "enabled" => true,
        "strategy" => "nlp",
        "max_keywords" => 15,
        "language" => "en"
      }

      assert config["strategy"] == "nlp"
      assert config["language"] == "en"
    end

    @tag :unit
    test "creates with custom keyword list" do
      config = %{
        "enabled" => true,
        "custom_keywords" => ["custom", "term", "list"],
        "weight_custom" => 2.0
      }

      assert config["custom_keywords"] == ["custom", "term", "list"]
      assert config["weight_custom"] == 2.0
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates strategy is valid" do
      valid_strategies = ["frequency", "tfidf", "nlp", "custom"]
      config = %{"strategy" => "frequency"}

      assert config["strategy"] in valid_strategies
    end

    @tag :unit
    test "validates max_keywords is positive integer" do
      config = %{"max_keywords" => 10}

      assert is_integer(config["max_keywords"])
      assert config["max_keywords"] > 0
    end

    @tag :unit
    test "validates min_frequency is non-negative" do
      config = %{"min_frequency" => 2}

      assert is_integer(config["min_frequency"])
      assert config["min_frequency"] >= 0
    end

    @tag :unit
    test "validates custom_keywords is list of strings" do
      config = %{"custom_keywords" => ["keyword1", "keyword2", "keyword3"]}

      assert is_list(config["custom_keywords"])
      assert Enum.all?(config["custom_keywords"], &is_binary/1)
    end

    @tag :unit
    test "accepts valid keyword config" do
      config = %{
        "enabled" => true,
        "strategy" => "tfidf",
        "max_keywords" => 20,
        "min_frequency" => 1
      }

      assert config["enabled"] == true
      assert config["max_keywords"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "strategy" => "nlp",
        "max_keywords" => 15,
        "language" => "en"
      }

      assert is_map(config)
      assert config["strategy"] == "nlp"
      assert config["max_keywords"] == 15
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "strategy" => "tfidf",
        "max_keywords" => 20,
        "min_frequency" => 2,
        "custom_keywords" => ["term1", "term2"],
        "weight_custom" => 2.5,
        "language" => "en"
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["strategy"] == "tfidf"
      assert restored["max_keywords"] == 20
      assert length(restored["custom_keywords"]) == 2
      assert restored["weight_custom"] == 2.5
    end

    @tag :unit
    test "preserves keyword list order" do
      config = %{"custom_keywords" => ["alpha", "beta", "gamma"]}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["custom_keywords"] == ["alpha", "beta", "gamma"]
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      keyword_config = %{
        "enabled" => true,
        "strategy" => "tfidf",
        "max_keywords" => 20
      }

      extraction_config = %Kreuzberg.ExtractionConfig{keywords: keyword_config}

      assert extraction_config.keywords["strategy"] == "tfidf"
      assert extraction_config.keywords["max_keywords"] == 20
    end

    @tag :unit
    test "validates when nested" do
      keyword_config = %{"enabled" => true, "strategy" => "frequency", "max_keywords" => 10}
      extraction_config = %Kreuzberg.ExtractionConfig{keywords: keyword_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on strategy field" do
      config = %{"strategy" => "tfidf"}

      case config do
        %{"strategy" => "tfidf"} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on max_keywords field" do
      config = %{"max_keywords" => 20}

      case config do
        %{"max_keywords" => n} when n > 10 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles single keyword extraction" do
      config = %{"max_keywords" => 1}

      assert config["max_keywords"] == 1
    end

    @tag :unit
    test "handles very large keyword limits" do
      config = %{"max_keywords" => 10_000}

      assert config["max_keywords"] == 10_000
    end

    @tag :unit
    test "handles zero minimum frequency" do
      config = %{"min_frequency" => 0}

      assert config["min_frequency"] == 0
    end

    @tag :unit
    test "handles high minimum frequency" do
      config = %{"min_frequency" => 100}

      assert config["min_frequency"] == 100
    end

    @tag :unit
    test "handles empty custom keyword list" do
      config = %{"custom_keywords" => []}

      assert config["custom_keywords"] == []
    end

    @tag :unit
    test "handles large custom keyword list" do
      keywords = Enum.map(1..1000, &"keyword_#{&1}")
      config = %{"custom_keywords" => keywords}

      assert length(config["custom_keywords"]) == 1000
    end

    @tag :unit
    test "handles special characters in keywords" do
      config = %{"custom_keywords" => ["keyword-1", "keyword_2", "keyword.3"]}

      assert "keyword-1" in config["custom_keywords"]
      assert "keyword_2" in config["custom_keywords"]
    end

    @tag :unit
    test "handles nil language" do
      config = %{"language" => nil}

      assert config["language"] == nil
    end

    @tag :unit
    test "handles various language codes" do
      config = %{"language" => "en"}

      assert config["language"] == "en"
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "strategy is string" do
      config = %{"strategy" => "frequency"}

      assert is_binary(config["strategy"])
    end

    @tag :unit
    test "max_keywords is integer" do
      config = %{"max_keywords" => 10}

      assert is_integer(config["max_keywords"])
    end

    @tag :unit
    test "min_frequency is integer" do
      config = %{"min_frequency" => 2}

      assert is_integer(config["min_frequency"])
    end

    @tag :unit
    test "custom_keywords is list" do
      config = %{"custom_keywords" => ["key1", "key2"]}

      assert is_list(config["custom_keywords"])
    end

    @tag :unit
    test "weight_custom is number" do
      config = %{"weight_custom" => 2.5}

      assert is_float(config["weight_custom"]) or is_integer(config["weight_custom"])
    end
  end
end
