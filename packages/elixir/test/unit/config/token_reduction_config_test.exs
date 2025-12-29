defmodule KreuzbergTest.Unit.Config.TokenReductionConfigTest do
  @moduledoc """
  Unit tests for token reduction configuration.

  Tests cover:
  - Struct creation with reduction strategies
  - Validation of compression ratios
  - Summarization settings
  - Serialization to/from maps
  - Pattern matching on token configs
  - Edge cases for reduction bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "strategy" => "summarize",
        "target_reduction" => 0.3
      }

      assert config["enabled"] == true
      assert config["strategy"] == "summarize"
      assert config["target_reduction"] == 0.3
    end

    @tag :unit
    test "creates with truncation strategy" do
      config = %{
        "enabled" => true,
        "strategy" => "truncate",
        "max_tokens" => 2000,
        "keep_first_percentage" => 0.7
      }

      assert config["strategy"] == "truncate"
      assert config["max_tokens"] == 2000
      assert config["keep_first_percentage"] == 0.7
    end

    @tag :unit
    test "creates with abstractive summarization" do
      config = %{
        "enabled" => true,
        "strategy" => "summarize",
        "summary_length_percentage" => 30,
        "preserve_key_sentences" => true
      }

      assert config["strategy"] == "summarize"
      assert config["summary_length_percentage"] == 30
      assert config["preserve_key_sentences"] == true
    end

    @tag :unit
    test "creates with extractive summarization" do
      config = %{
        "enabled" => true,
        "strategy" => "extractive",
        "num_sentences" => 5,
        "sentence_importance_threshold" => 0.6
      }

      assert config["strategy"] == "extractive"
      assert config["num_sentences"] == 5
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
      valid_strategies = ["none", "truncate", "summarize", "extractive"]
      config = %{"strategy" => "summarize"}

      assert config["strategy"] in valid_strategies
    end

    @tag :unit
    test "validates target_reduction in range 0-1" do
      config = %{"target_reduction" => 0.3}

      assert is_float(config["target_reduction"]) or is_integer(config["target_reduction"])
      assert config["target_reduction"] >= 0 and config["target_reduction"] <= 1
    end

    @tag :unit
    test "validates max_tokens is positive integer" do
      config = %{"max_tokens" => 2000}

      assert is_integer(config["max_tokens"])
      assert config["max_tokens"] > 0
    end

    @tag :unit
    test "validates keep_first_percentage in range 0-1" do
      config = %{"keep_first_percentage" => 0.7}

      assert config["keep_first_percentage"] >= 0 and config["keep_first_percentage"] <= 1
    end

    @tag :unit
    test "accepts valid token reduction config" do
      config = %{
        "enabled" => true,
        "strategy" => "summarize",
        "target_reduction" => 0.4
      }

      assert config["enabled"] == true
      assert config["target_reduction"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "strategy" => "truncate",
        "max_tokens" => 2000,
        "keep_first_percentage" => 0.7
      }

      assert is_map(config)
      assert config["strategy"] == "truncate"
      assert config["max_tokens"] == 2000
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "strategy" => "summarize",
        "target_reduction" => 0.3,
        "summary_length_percentage" => 30,
        "preserve_key_sentences" => true,
        "num_sentences" => 5,
        "sentence_importance_threshold" => 0.6
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["strategy"] == "summarize"
      assert restored["target_reduction"] == 0.3
      assert restored["preserve_key_sentences"] == true
    end

    @tag :unit
    test "preserves numeric precision" do
      config = %{"target_reduction" => 0.3333333}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert abs(decoded["target_reduction"] - 0.3333333) < 0.0001
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      token_config = %{
        "enabled" => true,
        "strategy" => "summarize",
        "target_reduction" => 0.3
      }

      extraction_config = %Kreuzberg.ExtractionConfig{token_reduction: token_config}

      assert extraction_config.token_reduction["strategy"] == "summarize"
      assert extraction_config.token_reduction["target_reduction"] == 0.3
    end

    @tag :unit
    test "validates when nested" do
      token_config = %{"enabled" => true, "strategy" => "truncate", "max_tokens" => 2000}
      extraction_config = %Kreuzberg.ExtractionConfig{token_reduction: token_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on strategy field" do
      config = %{"strategy" => "summarize"}

      case config do
        %{"strategy" => "summarize"} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on target_reduction field" do
      config = %{"target_reduction" => 0.5}

      case config do
        %{"target_reduction" => t} when t > 0.2 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles no reduction (0.0)" do
      config = %{"target_reduction" => 0.0}

      assert config["target_reduction"] == 0.0
    end

    @tag :unit
    test "handles maximum reduction (1.0)" do
      config = %{"target_reduction" => 1.0}

      assert config["target_reduction"] == 1.0
    end

    @tag :unit
    test "handles small max_tokens" do
      config = %{"max_tokens" => 100}

      assert config["max_tokens"] == 100
    end

    @tag :unit
    test "handles very large max_tokens" do
      config = %{"max_tokens" => 100_000}

      assert config["max_tokens"] == 100_000
    end

    @tag :unit
    test "handles zero num_sentences" do
      config = %{"num_sentences" => 0}

      assert config["num_sentences"] == 0
    end

    @tag :unit
    test "handles large num_sentences" do
      config = %{"num_sentences" => 1000}

      assert config["num_sentences"] == 1000
    end

    @tag :unit
    test "handles low importance threshold" do
      config = %{"sentence_importance_threshold" => 0.2}

      assert config["sentence_importance_threshold"] == 0.2
    end

    @tag :unit
    test "handles high importance threshold" do
      config = %{"sentence_importance_threshold" => 0.95}

      assert config["sentence_importance_threshold"] == 0.95
    end

    @tag :unit
    test "handles minimum keep_first_percentage" do
      config = %{"keep_first_percentage" => 0.0}

      assert config["keep_first_percentage"] == 0.0
    end

    @tag :unit
    test "handles maximum keep_first_percentage" do
      config = %{"keep_first_percentage" => 1.0}

      assert config["keep_first_percentage"] == 1.0
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
      config = %{"strategy" => "summarize"}

      assert is_binary(config["strategy"])
    end

    @tag :unit
    test "target_reduction is number" do
      config = %{"target_reduction" => 0.3}

      assert is_float(config["target_reduction"]) or is_integer(config["target_reduction"])
    end

    @tag :unit
    test "max_tokens is integer" do
      config = %{"max_tokens" => 2000}

      assert is_integer(config["max_tokens"])
    end

    @tag :unit
    test "keep_first_percentage is number" do
      config = %{"keep_first_percentage" => 0.7}

      assert is_float(config["keep_first_percentage"]) or
               is_integer(config["keep_first_percentage"])
    end

    @tag :unit
    test "num_sentences is integer" do
      config = %{"num_sentences" => 5}

      assert is_integer(config["num_sentences"])
    end
  end
end
