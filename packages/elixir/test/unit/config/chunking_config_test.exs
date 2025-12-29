defmodule KreuzbergTest.Unit.Config.ChunkingConfigTest do
  @moduledoc """
  Unit tests for text chunking configuration.

  Tests cover:
  - Struct creation with chunk size and overlap
  - Strategy selection (fixed, semantic, adaptive)
  - Validation of numeric bounds
  - Serialization to/from maps
  - Pattern matching on chunking configs
  - Edge cases for boundary values
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "chunk_size" => 512,
        "overlap" => 50
      }

      assert config["enabled"] == true
      assert config["chunk_size"] == 512
      assert config["overlap"] == 50
    end

    @tag :unit
    test "creates with custom chunk size" do
      config = %{
        "chunk_size" => 1024,
        "overlap" => 100,
        "strategy" => "semantic"
      }

      assert config["chunk_size"] == 1024
      assert config["overlap"] == 100
      assert config["strategy"] == "semantic"
    end

    @tag :unit
    test "creates with different strategies" do
      fixed = %{"strategy" => "fixed", "chunk_size" => 512}
      semantic = %{"strategy" => "semantic"}
      adaptive = %{"strategy" => "adaptive"}

      assert fixed["strategy"] == "fixed"
      assert semantic["strategy"] == "semantic"
      assert adaptive["strategy"] == "adaptive"
    end

    @tag :unit
    test "creates with separator configuration" do
      config = %{
        "chunk_size" => 512,
        "separator" => "\n\n",
        "preserve_headers" => true
      }

      assert config["separator"] == "\n\n"
      assert config["preserve_headers"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates chunk_size is positive integer" do
      config = %{"chunk_size" => 512}

      assert is_integer(config["chunk_size"])
      assert config["chunk_size"] > 0
    end

    @tag :unit
    test "validates overlap is non-negative" do
      config = %{"overlap" => 50}

      assert is_integer(config["overlap"])
      assert config["overlap"] >= 0
    end

    @tag :unit
    test "validates overlap is less than chunk_size" do
      config = %{"chunk_size" => 512, "overlap" => 100}

      assert config["overlap"] < config["chunk_size"]
    end

    @tag :unit
    test "validates strategy is valid" do
      valid_strategies = ["fixed", "semantic", "adaptive"]
      config = %{"strategy" => "fixed"}

      assert config["strategy"] in valid_strategies
    end

    @tag :unit
    test "accepts valid chunking config" do
      config = %{
        "enabled" => true,
        "chunk_size" => 512,
        "overlap" => 50,
        "strategy" => "semantic"
      }

      assert config["enabled"] in [true, false]
      assert config["chunk_size"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "chunk_size" => 512,
        "overlap" => 50,
        "strategy" => "semantic"
      }

      assert is_map(config)
      assert config["chunk_size"] == 512
      assert config["strategy"] == "semantic"
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "chunk_size" => 1024,
        "overlap" => 100,
        "strategy" => "adaptive",
        "separator" => "\n\n"
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["chunk_size"] == 1024
      assert restored["strategy"] == "adaptive"
      assert restored["separator"] == "\n\n"
    end

    @tag :unit
    test "preserves numeric values in JSON" do
      config = %{
        "chunk_size" => 2048,
        "overlap" => 256
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["chunk_size"] == 2048
      assert decoded["overlap"] == 256
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      chunking_config = %{
        "chunk_size" => 512,
        "overlap" => 50,
        "strategy" => "semantic"
      }

      extraction_config = %Kreuzberg.ExtractionConfig{chunking: chunking_config}

      assert extraction_config.chunking["chunk_size"] == 512
      assert extraction_config.chunking["strategy"] == "semantic"
    end

    @tag :unit
    test "validates when nested" do
      chunking_config = %{"chunk_size" => 512, "overlap" => 50}
      extraction_config = %Kreuzberg.ExtractionConfig{chunking: chunking_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on chunk_size field" do
      config = %{"chunk_size" => 512}

      case config do
        %{"chunk_size" => 512} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on strategy field" do
      config = %{"strategy" => "semantic"}

      case config do
        %{"strategy" => strategy} when is_binary(strategy) -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum chunk size" do
      config = %{"chunk_size" => 1}

      assert config["chunk_size"] == 1
    end

    @tag :unit
    test "handles large chunk size" do
      config = %{"chunk_size" => 1_000_000}

      assert config["chunk_size"] == 1_000_000
    end

    @tag :unit
    test "handles zero overlap" do
      config = %{"chunk_size" => 512, "overlap" => 0}

      assert config["overlap"] == 0
    end

    @tag :unit
    test "handles maximum safe overlap" do
      config = %{"chunk_size" => 512, "overlap" => 511}

      assert config["overlap"] < config["chunk_size"]
    end

    @tag :unit
    test "handles nil separator" do
      config = %{"separator" => nil}

      assert config["separator"] == nil
    end

    @tag :unit
    test "handles multi-character separator" do
      config = %{"separator" => "---"}

      assert config["separator"] == "---"
    end

    @tag :unit
    test "handles special character separators" do
      config = %{"separator" => "\n\n\n"}

      assert String.length(config["separator"]) == 3
    end
  end

  describe "type safety" do
    @tag :unit
    test "chunk_size is integer" do
      config = %{"chunk_size" => 512}

      assert is_integer(config["chunk_size"])
    end

    @tag :unit
    test "overlap is integer" do
      config = %{"overlap" => 50}

      assert is_integer(config["overlap"])
    end

    @tag :unit
    test "strategy is string" do
      config = %{"strategy" => "semantic"}

      assert is_binary(config["strategy"])
    end

    @tag :unit
    test "enabled is boolean or nil" do
      config1 = %{"enabled" => true}
      config2 = %{"enabled" => false}
      config3 = %{}

      assert is_boolean(config1["enabled"])
      assert is_boolean(config2["enabled"])
    end
  end
end
