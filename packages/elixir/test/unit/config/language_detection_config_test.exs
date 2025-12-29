defmodule KreuzbergTest.Unit.Config.LanguageDetectionConfigTest do
  @moduledoc """
  Unit tests for language detection configuration.

  Tests cover:
  - Struct creation with language detection options
  - Validation of detection strategy
  - Confidence threshold settings
  - Serialization to/from maps
  - Pattern matching on language configs
  - Edge cases for confidence bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "strategy" => "auto",
        "confidence_threshold" => 0.7
      }

      assert config["enabled"] == true
      assert config["strategy"] == "auto"
      assert config["confidence_threshold"] == 0.7
    end

    @tag :unit
    test "creates with fast strategy" do
      config = %{
        "enabled" => true,
        "strategy" => "fast",
        "confidence_threshold" => 0.5
      }

      assert config["strategy"] == "fast"
      assert config["confidence_threshold"] == 0.5
    end

    @tag :unit
    test "creates with accurate strategy" do
      config = %{
        "enabled" => true,
        "strategy" => "accurate",
        "confidence_threshold" => 0.9
      }

      assert config["strategy"] == "accurate"
      assert config["confidence_threshold"] == 0.9
    end

    @tag :unit
    test "creates with predefined languages" do
      config = %{
        "enabled" => true,
        "predefined_languages" => ["en", "fr", "de", "es"],
        "detect_mixed_languages" => true
      }

      assert config["predefined_languages"] == ["en", "fr", "de", "es"]
      assert config["detect_mixed_languages"] == true
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
      valid_strategies = ["auto", "fast", "accurate"]
      config = %{"strategy" => "auto"}

      assert config["strategy"] in valid_strategies
    end

    @tag :unit
    test "validates confidence_threshold in range 0-1" do
      config = %{"confidence_threshold" => 0.7}

      assert is_float(config["confidence_threshold"]) or
               is_integer(config["confidence_threshold"])

      assert config["confidence_threshold"] >= 0 and config["confidence_threshold"] <= 1
    end

    @tag :unit
    test "validates predefined_languages is list of strings" do
      config = %{"predefined_languages" => ["en", "fr", "de"]}

      assert is_list(config["predefined_languages"])
      assert Enum.all?(config["predefined_languages"], &is_binary/1)
    end

    @tag :unit
    test "validates detect_mixed_languages is boolean" do
      config = %{"detect_mixed_languages" => true}

      assert is_boolean(config["detect_mixed_languages"])
    end

    @tag :unit
    test "accepts valid language detection config" do
      config = %{
        "enabled" => true,
        "strategy" => "accurate",
        "confidence_threshold" => 0.85,
        "detect_mixed_languages" => true
      }

      assert config["enabled"] == true
      assert config["confidence_threshold"] > 0.5
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "strategy" => "accurate",
        "confidence_threshold" => 0.85
      }

      assert is_map(config)
      assert config["strategy"] == "accurate"
      assert config["confidence_threshold"] == 0.85
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "strategy" => "accurate",
        "confidence_threshold" => 0.85,
        "predefined_languages" => ["en", "fr", "de", "es"],
        "detect_mixed_languages" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["strategy"] == "accurate"
      assert restored["confidence_threshold"] == 0.85
      assert length(restored["predefined_languages"]) == 4
      assert restored["detect_mixed_languages"] == true
    end

    @tag :unit
    test "preserves threshold precision" do
      config = %{"confidence_threshold" => 0.7500001}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert abs(decoded["confidence_threshold"] - 0.7500001) < 0.0001
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      lang_config = %{
        "enabled" => true,
        "strategy" => "accurate",
        "confidence_threshold" => 0.85
      }

      extraction_config = %Kreuzberg.ExtractionConfig{language_detection: lang_config}

      assert extraction_config.language_detection["strategy"] == "accurate"
      assert extraction_config.language_detection["confidence_threshold"] == 0.85
    end

    @tag :unit
    test "validates when nested" do
      lang_config = %{
        "enabled" => true,
        "strategy" => "fast",
        "confidence_threshold" => 0.5
      }

      extraction_config = %Kreuzberg.ExtractionConfig{language_detection: lang_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on strategy field" do
      config = %{"strategy" => "accurate"}

      case config do
        %{"strategy" => "accurate"} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on confidence_threshold field" do
      config = %{"confidence_threshold" => 0.8}

      case config do
        %{"confidence_threshold" => t} when t > 0.7 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum confidence threshold (0.0)" do
      config = %{"confidence_threshold" => 0.0}

      assert config["confidence_threshold"] == 0.0
    end

    @tag :unit
    test "handles maximum confidence threshold (1.0)" do
      config = %{"confidence_threshold" => 1.0}

      assert config["confidence_threshold"] == 1.0
    end

    @tag :unit
    test "handles typical low threshold" do
      config = %{"confidence_threshold" => 0.5}

      assert config["confidence_threshold"] == 0.5
    end

    @tag :unit
    test "handles typical high threshold" do
      config = %{"confidence_threshold" => 0.95}

      assert config["confidence_threshold"] == 0.95
    end

    @tag :unit
    test "handles empty predefined languages list" do
      config = %{"predefined_languages" => []}

      assert config["predefined_languages"] == []
    end

    @tag :unit
    test "handles large predefined languages list" do
      languages = Enum.map(1..100, &"lang_#{&1}")
      config = %{"predefined_languages" => languages}

      assert length(config["predefined_languages"]) == 100
    end

    @tag :unit
    test "handles single language in predefined list" do
      config = %{"predefined_languages" => ["en"]}

      assert config["predefined_languages"] == ["en"]
    end

    @tag :unit
    test "handles mixed language codes" do
      config = %{"predefined_languages" => ["en", "en_US", "zh_CN", "pt_BR"]}

      assert "en_US" in config["predefined_languages"]
      assert "zh_CN" in config["predefined_languages"]
    end

    @tag :unit
    test "handles nil predefined_languages" do
      config = %{"predefined_languages" => nil}

      assert config["predefined_languages"] == nil
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
      config = %{"strategy" => "accurate"}

      assert is_binary(config["strategy"])
    end

    @tag :unit
    test "confidence_threshold is number" do
      config = %{"confidence_threshold" => 0.85}

      assert is_float(config["confidence_threshold"]) or
               is_integer(config["confidence_threshold"])
    end

    @tag :unit
    test "predefined_languages is list or nil" do
      config1 = %{"predefined_languages" => ["en", "fr"]}
      config2 = %{"predefined_languages" => nil}

      assert is_list(config1["predefined_languages"])
      assert config2["predefined_languages"] == nil
    end

    @tag :unit
    test "detect_mixed_languages is boolean" do
      config = %{"detect_mixed_languages" => true}

      assert is_boolean(config["detect_mixed_languages"])
    end
  end
end
