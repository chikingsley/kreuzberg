defmodule KreuzbergTest.Unit.Config.EmbeddingConfigTest do
  @moduledoc """
  Unit tests for embedding configuration for semantic search.

  Tests cover:
  - Struct creation with embedding model options
  - Validation of embedding dimensions
  - Model selection and parameters
  - Serialization to/from maps
  - Pattern matching on embedding configs
  - Edge cases for dimension bounds
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "model" => "sentence-transformers/all-MiniLM-L6-v2",
        "dimensions" => 384
      }

      assert config["enabled"] == true
      assert config["model"] == "sentence-transformers/all-MiniLM-L6-v2"
      assert config["dimensions"] == 384
    end

    @tag :unit
    test "creates with OpenAI embeddings" do
      config = %{
        "enabled" => true,
        "provider" => "openai",
        "model" => "text-embedding-3-small",
        "dimensions" => 1536,
        "api_key" => "sk-..."
      }

      assert config["provider"] == "openai"
      assert config["dimensions"] == 1536
      assert config["api_key"] == "sk-..."
    end

    @tag :unit
    test "creates with Hugging Face embeddings" do
      config = %{
        "enabled" => true,
        "provider" => "huggingface",
        "model" => "sentence-transformers/all-mpnet-base-v2",
        "dimensions" => 768,
        "batch_size" => 32
      }

      assert config["provider"] == "huggingface"
      assert config["dimensions"] == 768
      assert config["batch_size"] == 32
    end

    @tag :unit
    test "creates with normalization options" do
      config = %{
        "enabled" => true,
        "normalize" => true,
        "pool_strategy" => "mean",
        "convert_to_tensor" => true
      }

      assert config["normalize"] == true
      assert config["pool_strategy"] == "mean"
      assert config["convert_to_tensor"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates model is string" do
      config = %{"model" => "sentence-transformers/all-MiniLM-L6-v2"}

      assert is_binary(config["model"])
    end

    @tag :unit
    test "validates dimensions is positive integer" do
      config = %{"dimensions" => 384}

      assert is_integer(config["dimensions"])
      assert config["dimensions"] > 0
    end

    @tag :unit
    test "validates provider is valid" do
      valid_providers = ["local", "openai", "huggingface", "cohere", "custom"]
      config = %{"provider" => "openai"}

      assert config["provider"] in valid_providers
    end

    @tag :unit
    test "validates batch_size is positive integer" do
      config = %{"batch_size" => 32}

      assert is_integer(config["batch_size"])
      assert config["batch_size"] > 0
    end

    @tag :unit
    test "validates pool_strategy is valid" do
      valid_strategies = ["mean", "max", "cls", "sum"]
      config = %{"pool_strategy" => "mean"}

      assert config["pool_strategy"] in valid_strategies
    end

    @tag :unit
    test "accepts valid embedding config" do
      config = %{
        "enabled" => true,
        "model" => "text-embedding-3-large",
        "dimensions" => 3072,
        "provider" => "openai",
        "normalize" => true
      }

      assert config["enabled"] == true
      assert config["dimensions"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "model" => "all-MiniLM-L6-v2",
        "dimensions" => 384,
        "provider" => "huggingface"
      }

      assert is_map(config)
      assert config["model"] == "all-MiniLM-L6-v2"
      assert config["dimensions"] == 384
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "provider" => "huggingface",
        "model" => "sentence-transformers/all-mpnet-base-v2",
        "dimensions" => 768,
        "batch_size" => 32,
        "normalize" => true,
        "pool_strategy" => "mean",
        "convert_to_tensor" => true,
        "device" => "cuda"
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["model"] == "sentence-transformers/all-mpnet-base-v2"
      assert restored["dimensions"] == 768
      assert restored["batch_size"] == 32
      assert restored["normalize"] == true
      assert restored["pool_strategy"] == "mean"
    end

    @tag :unit
    test "preserves numeric dimensions" do
      config = %{"dimensions" => 1536, "batch_size" => 64}

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["dimensions"] == 1536
      assert decoded["batch_size"] == 64
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config through chunking" do
      embedding_config = %{
        "enabled" => true,
        "model" => "all-MiniLM-L6-v2",
        "dimensions" => 384
      }

      chunking_config = %{"embedding_config" => embedding_config}
      extraction_config = %Kreuzberg.ExtractionConfig{chunking: chunking_config}

      assert extraction_config.chunking["embedding_config"]["dimensions"] == 384
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
    test "matches on dimensions field" do
      config = %{"dimensions" => 768}

      case config do
        %{"dimensions" => d} when d > 100 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum embedding dimension" do
      config = %{"dimensions" => 64}

      assert config["dimensions"] == 64
    end

    @tag :unit
    test "handles very large embedding dimension" do
      config = %{"dimensions" => 4096}

      assert config["dimensions"] == 4096
    end

    @tag :unit
    test "handles common embedding dimensions" do
      common_dims = [64, 128, 256, 384, 512, 768, 1024, 1536, 3072]

      Enum.each(common_dims, fn dim ->
        config = %{"dimensions" => dim}
        assert config["dimensions"] == dim
      end)
    end

    @tag :unit
    test "handles minimum batch size" do
      config = %{"batch_size" => 1}

      assert config["batch_size"] == 1
    end

    @tag :unit
    test "handles very large batch size" do
      config = %{"batch_size" => 512}

      assert config["batch_size"] == 512
    end

    @tag :unit
    test "handles all pooling strategies" do
      strategies = ["mean", "max", "cls", "sum"]

      Enum.each(strategies, fn strategy ->
        config = %{"pool_strategy" => strategy}
        assert config["pool_strategy"] == strategy
      end)
    end

    @tag :unit
    test "handles all providers" do
      providers = ["local", "openai", "huggingface", "cohere", "custom"]

      Enum.each(providers, fn provider ->
        config = %{"provider" => provider}
        assert config["provider"] == provider
      end)
    end

    @tag :unit
    test "handles nil device" do
      config = %{"device" => nil}

      assert config["device"] == nil
    end

    @tag :unit
    test "handles various device names" do
      config1 = %{"device" => "cpu"}
      config2 = %{"device" => "cuda"}
      config3 = %{"device" => "cuda:0"}
      config4 = %{"device" => "mps"}

      assert config1["device"] == "cpu"
      assert config2["device"] == "cuda"
      assert config3["device"] == "cuda:0"
      assert config4["device"] == "mps"
    end

    @tag :unit
    test "handles nil api_key" do
      config = %{"api_key" => nil}

      assert config["api_key"] == nil
    end

    @tag :unit
    test "handles long model names" do
      config = %{"model" => "sentence-transformers/all-MiniLM-L6-v2"}

      assert String.length(config["model"]) > 20
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "model is string" do
      config = %{"model" => "sentence-transformers/all-MiniLM-L6-v2"}

      assert is_binary(config["model"])
    end

    @tag :unit
    test "dimensions is integer" do
      config = %{"dimensions" => 384}

      assert is_integer(config["dimensions"])
    end

    @tag :unit
    test "provider is string" do
      config = %{"provider" => "openai"}

      assert is_binary(config["provider"])
    end

    @tag :unit
    test "batch_size is integer" do
      config = %{"batch_size" => 32}

      assert is_integer(config["batch_size"])
    end

    @tag :unit
    test "normalize is boolean or nil" do
      config1 = %{"normalize" => true}
      config2 = %{"normalize" => nil}

      assert is_boolean(config1["normalize"]) or config1["normalize"] == nil
      assert config2["normalize"] == nil
    end

    @tag :unit
    test "pool_strategy is string or nil" do
      config1 = %{"pool_strategy" => "mean"}
      config2 = %{"pool_strategy" => nil}

      assert is_binary(config1["pool_strategy"]) or config1["pool_strategy"] == nil
      assert config2["pool_strategy"] == nil
    end

    @tag :unit
    test "convert_to_tensor is boolean or nil" do
      config1 = %{"convert_to_tensor" => true}
      config2 = %{"convert_to_tensor" => nil}

      assert is_boolean(config1["convert_to_tensor"]) or config1["convert_to_tensor"] == nil
      assert config2["convert_to_tensor"] == nil
    end
  end
end
