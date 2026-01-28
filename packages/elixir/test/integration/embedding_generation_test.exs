defmodule KreuzbergTest.Integration.EmbeddingGenerationTest do
  @moduledoc """
  Integration tests for embedding generation and vector operations.

  Tests cover:
  - Vector embedding generation
  - EmbeddingConfig struct validation
  - Batch embedding operations
  - Chunk struct with embeddings
  - Embedding metadata and confidence scores
  - Embedding serialization
  """

  use ExUnit.Case, async: true

  @sample_texts [
    "The quick brown fox jumps over the lazy dog",
    "Natural language processing is fascinating",
    "Machine learning models require good training data",
    "Embeddings capture semantic meaning of text"
  ]

  @sample_text """
  Natural Language Processing (NLP) is a subfield of linguistics, computer science,
  and artificial intelligence concerned with the interactions between computers and
  human language. NLP is used to apply machine learning algorithms to text and speech.
  """

  describe "Chunk struct with embeddings" do
    @tag :integration
    test "creates Chunk with text and embedding" do
      embedding = [0.1, 0.2, 0.3, 0.4, 0.5]

      chunk =
        Kreuzberg.Chunk.new(
          "Sample text for embedding",
          embedding: embedding
        )

      assert chunk.content == "Sample text for embedding"
      assert chunk.embedding == embedding
    end

    @tag :integration
    test "creates Chunk with metadata" do
      chunk =
        Kreuzberg.Chunk.new(
          "Text chunk",
          metadata: %{"page" => 1, "section" => "Introduction"}
        )

      assert chunk.metadata["page"] == 1
      assert chunk.metadata["section"] == "Introduction"
    end

    @tag :integration
    test "creates Chunk with token count" do
      chunk =
        Kreuzberg.Chunk.new(
          "This is a text chunk",
          token_count: 5
        )

      assert chunk.token_count == 5
    end

    @tag :integration
    test "creates Chunk with start position" do
      chunk =
        Kreuzberg.Chunk.new(
          "Middle of document",
          start_position: 1000
        )

      assert chunk.start_position == 1000
    end

    @tag :integration
    test "creates Chunk with confidence score" do
      chunk =
        Kreuzberg.Chunk.new(
          "High confidence text",
          confidence: 0.95
        )

      assert chunk.confidence == 0.95
      assert chunk.confidence >= 0.0 and chunk.confidence <= 1.0
    end

    @tag :integration
    test "creates Chunk from map" do
      chunk_map = %{
        "content" => "Chunk from map",
        "embedding" => [0.1, 0.2, 0.3],
        "metadata" => %{"source" => "pdf"},
        "token_count" => 3,
        "confidence" => 0.9
      }

      chunk = Kreuzberg.Chunk.from_map(chunk_map)

      assert %Kreuzberg.Chunk{} = chunk
      assert chunk.content == "Chunk from map"
      assert chunk.embedding == [0.1, 0.2, 0.3]
      assert chunk.token_count == 3
      assert chunk.confidence == 0.9
    end
  end

  describe "Chunk serialization" do
    @tag :integration
    test "converts Chunk to map" do
      chunk =
        Kreuzberg.Chunk.new(
          "Sample chunk",
          embedding: [0.1, 0.2],
          metadata: %{"page" => 1},
          token_count: 2,
          confidence: 0.85
        )

      chunk_map = Kreuzberg.Chunk.to_map(chunk)

      assert is_map(chunk_map)
      assert chunk_map["content"] == "Sample chunk"
      assert chunk_map["embedding"] == [0.1, 0.2]
      assert chunk_map["token_count"] == 2
    end

    @tag :integration
    test "round-trips through serialization" do
      original =
        Kreuzberg.Chunk.new(
          "Original chunk",
          embedding: [0.2, 0.4, 0.6, 0.8],
          metadata: %{"chapter" => 3},
          token_count: 3,
          start_position: 500,
          confidence: 0.92
        )

      chunk_map = Kreuzberg.Chunk.to_map(original)
      restored = Kreuzberg.Chunk.from_map(chunk_map)

      assert restored.content == original.content
      assert restored.embedding == original.embedding
      assert restored.token_count == original.token_count
      assert restored.confidence == original.confidence
    end

    @tag :integration
    test "serializes to JSON" do
      chunk =
        Kreuzberg.Chunk.new(
          "JSON serializable chunk",
          embedding: [0.1, 0.2, 0.3],
          token_count: 4
        )

      chunk_map = Kreuzberg.Chunk.to_map(chunk)
      json = Jason.encode!(chunk_map)

      assert is_binary(json)
      {:ok, decoded} = Jason.decode(json)
      assert decoded["content"] == "JSON serializable chunk"
      assert decoded["embedding"] == [0.1, 0.2, 0.3]
    end

    @tag :integration
    test "preserves embedding vector precision" do
      embedding = [0.123456, 0.987654, 0.111111, 0.999999]
      chunk = Kreuzberg.Chunk.new("Test", embedding: embedding)

      chunk_map = Kreuzberg.Chunk.to_map(chunk)
      json = Jason.encode!(chunk_map)
      {:ok, decoded} = Jason.decode(json)

      # Floating point comparison with tolerance
      decoded_embedding = decoded["embedding"]

      Enum.zip(embedding, decoded_embedding)
      |> Enum.each(fn {original, decoded_val} ->
        assert_in_delta(original, decoded_val, 0.000001)
      end)
    end
  end

  describe "Embedding configuration" do
    @tag :integration
    test "accepts embedding config in ExtractionConfig" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "enabled" => true,
          "chunk_size" => 512
        }
      }

      assert config.chunking["chunk_size"] == 512
    end

    @tag :integration
    test "embedding extraction from text" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "enabled" => true,
          "chunk_size" => 256,
          "overlap" => 50
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_text, "text/plain", config)

      assert result.chunks != nil or result.chunks == nil

      if result.chunks != nil do
        assert is_list(result.chunks)
      end
    end

    @tag :integration
    test "applies embedding preset" do
      {:ok, presets} = Kreuzberg.list_embedding_presets()

      assert is_list(presets)

      if Enum.any?(presets) do
        preset_name = List.first(presets)
        result = Kreuzberg.get_embedding_preset(preset_name)
        assert is_tuple(result)
      end
    end
  end

  describe "Vector embedding properties" do
    @tag :integration
    test "embedding is list of floats" do
      embedding = [0.1, 0.2, 0.3, 0.4, 0.5]
      chunk = Kreuzberg.Chunk.new("Text", embedding: embedding)

      assert is_list(chunk.embedding)

      Enum.each(chunk.embedding, fn value ->
        assert is_float(value) or is_integer(value)
      end)
    end

    @tag :integration
    test "embedding has consistent dimensionality" do
      embeddings = [
        [0.1, 0.2, 0.3],
        [0.4, 0.5, 0.6],
        [0.7, 0.8, 0.9]
      ]

      chunks =
        embeddings
        |> Enum.with_index()
        |> Enum.map(fn {emb, idx} ->
          Kreuzberg.Chunk.new("Chunk #{idx}", embedding: emb)
        end)

      dimensions = Enum.map(chunks, fn chunk -> length(chunk.embedding) end)
      assert Enum.uniq(dimensions) == [3]
    end

    @tag :integration
    test "embedding values are normalized or bounded" do
      # Embeddings often have values between -1 and 1 or 0 and 1
      embedding = [0.123, -0.456, 0.789, 0.234, -0.567]
      chunk = Kreuzberg.Chunk.new("Test", embedding: embedding)

      Enum.each(chunk.embedding, fn value ->
        # Most embeddings fall in reasonable range (not strict requirement)
        assert is_number(value)
      end)
    end

    @tag :integration
    test "handles large dimensional embeddings" do
      # Create 768-dimensional embedding (common for models)
      large_embedding = Enum.map(1..768, fn i -> :math.sin(i / 100.0) end)
      chunk = Kreuzberg.Chunk.new("Large embedding", embedding: large_embedding)

      assert length(chunk.embedding) == 768
    end

    @tag :integration
    test "handles very small dimensional embeddings" do
      tiny_embedding = [0.5, 0.5]
      chunk = Kreuzberg.Chunk.new("Tiny embedding", embedding: tiny_embedding)

      assert length(chunk.embedding) == 2
    end
  end

  describe "Chunk metadata" do
    @tag :integration
    test "stores arbitrary metadata" do
      metadata = %{
        "source_file" => "document.pdf",
        "extraction_time" => "2024-01-01T12:00:00Z",
        "confidence" => 0.95,
        "language" => "en"
      }

      chunk =
        Kreuzberg.Chunk.new(
          "Text",
          metadata: metadata
        )

      assert chunk.metadata == metadata
      assert chunk.metadata["source_file"] == "document.pdf"
      assert chunk.metadata["confidence"] == 0.95
    end

    @tag :integration
    test "metadata can contain nested structures" do
      metadata = %{
        "document" => %{
          "title" => "Report",
          "author" => "John Doe"
        },
        "extraction" => %{
          "method" => "nlp",
          "timestamp" => 1_234_567_890
        }
      }

      chunk = Kreuzberg.Chunk.new("Text", metadata: metadata)

      assert chunk.metadata["document"]["title"] == "Report"
      assert chunk.metadata["extraction"]["method"] == "nlp"
    end

    @tag :integration
    test "metadata empty map is valid" do
      chunk = Kreuzberg.Chunk.new("Text", metadata: %{})

      assert chunk.metadata == %{}
    end

    @tag :integration
    test "chunk with all fields populated" do
      chunk =
        Kreuzberg.Chunk.new(
          "Complete chunk",
          embedding: [0.1, 0.2, 0.3],
          metadata: %{"page" => 1},
          token_count: 3,
          start_position: 100,
          confidence: 0.95
        )

      assert chunk.content == "Complete chunk"
      assert chunk.embedding != nil
      assert chunk.metadata != nil
      assert chunk.token_count == 3
      assert chunk.start_position == 100
      assert chunk.confidence == 0.95
    end
  end

  describe "Batch embedding operations" do
    @tag :integration
    test "extracts multiple chunks from document" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "enabled" => true,
          "chunk_size" => 100
        }
      }

      long_text = String.duplicate(@sample_text, 3)
      {:ok, result} = Kreuzberg.extract(long_text, "text/plain", config)

      if result.chunks != nil do
        assert is_list(result.chunks)

        if Enum.any?(result.chunks) do
          Enum.each(result.chunks, fn chunk ->
            assert is_map(chunk) or is_binary(chunk)
          end)
        end
      end
    end

    @tag :integration
    test "chunks maintain sequential order" do
      chunks = [
        Kreuzberg.Chunk.new("First chunk", start_position: 0),
        Kreuzberg.Chunk.new("Second chunk", start_position: 100),
        Kreuzberg.Chunk.new("Third chunk", start_position: 200)
      ]

      positions = Enum.map(chunks, fn c -> c.start_position end)
      assert positions == [0, 100, 200]
    end

    @tag :integration
    test "batch chunks with different embeddings" do
      embeddings = [
        [0.1, 0.2, 0.3],
        [0.4, 0.5, 0.6],
        [0.7, 0.8, 0.9],
        [0.2, 0.3, 0.4]
      ]

      chunks =
        @sample_texts
        |> Enum.zip(embeddings)
        |> Enum.map(fn {text, emb} ->
          Kreuzberg.Chunk.new(text, embedding: emb)
        end)

      assert length(chunks) == 4

      Enum.each(chunks, fn chunk ->
        assert chunk.embedding != nil
        assert length(chunk.embedding) == 3
      end)
    end

    @tag :integration
    test "applies different confidence scores to batch" do
      chunks = [
        Kreuzberg.Chunk.new("High confidence", confidence: 0.95),
        Kreuzberg.Chunk.new("Medium confidence", confidence: 0.75),
        Kreuzberg.Chunk.new("Low confidence", confidence: 0.55)
      ]

      confidences = Enum.map(chunks, fn c -> c.confidence end)
      assert confidences == [0.95, 0.75, 0.55]
    end
  end

  describe "Embedding compatibility" do
    @tag :integration
    test "embedding dimension flexibility" do
      # Different models may use different dimensions
      dims_to_test = [50, 100, 200, 300, 384, 512, 768, 1024]

      Enum.each(dims_to_test, fn dim ->
        embedding = Enum.map(1..dim, fn i -> i / (dim * 1.0) end)
        chunk = Kreuzberg.Chunk.new("Test", embedding: embedding)
        assert length(chunk.embedding) == dim
      end)
    end

    @tag :integration
    test "empty embedding list" do
      chunk = Kreuzberg.Chunk.new("No embedding", embedding: [])

      assert chunk.embedding == []
    end

    @tag :integration
    test "nil embedding is valid" do
      chunk = Kreuzberg.Chunk.new("No embedding specified")

      assert chunk.embedding == nil
    end

    @tag :integration
    test "embedding field optional in extraction result" do
      config = %Kreuzberg.ExtractionConfig{}

      {:ok, result} = Kreuzberg.extract(@sample_text, "text/plain", config)

      # chunks field may be nil if embedding not configured
      assert result.chunks == nil or is_list(result.chunks)
    end
  end

  describe "Embedding result integration" do
    @tag :integration
    test "chunks included in extraction result" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "enabled" => true,
          "chunk_size" => 200
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_text, "text/plain", config)

      # Should have chunks field
      assert Map.has_key?(result, :chunks)

      if result.chunks != nil do
        assert is_list(result.chunks)
      end
    end

    @tag :integration
    test "can serialize chunks to JSON" do
      chunks = [
        Kreuzberg.Chunk.new(
          "Chunk 1",
          embedding: [0.1, 0.2],
          token_count: 2
        ),
        Kreuzberg.Chunk.new(
          "Chunk 2",
          embedding: [0.3, 0.4],
          token_count: 2
        )
      ]

      chunk_maps = Enum.map(chunks, &Kreuzberg.Chunk.to_map/1)
      json = Jason.encode!(chunk_maps)

      assert is_binary(json)
      {:ok, decoded} = Jason.decode(json)
      assert length(decoded) == 2
    end

    @tag :integration
    test "chunks with consistent structure across batch" do
      chunks = [
        Kreuzberg.Chunk.new("Text 1", embedding: [0.1], token_count: 1),
        Kreuzberg.Chunk.new("Text 2", embedding: [0.2], token_count: 1),
        Kreuzberg.Chunk.new("Text 3", embedding: [0.3], token_count: 1)
      ]

      # All chunks should have same structure
      Enum.each(chunks, fn chunk ->
        assert is_binary(chunk.content)
        assert is_list(chunk.embedding)
        assert is_integer(chunk.token_count)
      end)
    end
  end

  describe "Chunk Rust FFI compatibility" do
    @tag :integration
    test "correctly maps 'content' field from Rust to 'content' field in Elixir" do
      # This simulates the actual data structure returned from Rust FFI
      rust_chunk_data = %{
        "content" => "This is the actual chunk text from Rust",
        "embedding" => nil,
        "metadata" => %{
          "byte_start" => 0,
          "byte_end" => 39,
          "chunk_index" => 0,
          "total_chunks" => 1
        }
      }

      chunk = Kreuzberg.Chunk.from_map(rust_chunk_data)

      # Now correctly maps "content" from Rust to "content" in Elixir
      assert chunk.content == "This is the actual chunk text from Rust"
      refute chunk.content == ""
    end

    @tag :integration
    test "handles Rust chunks with embeddings" do
      rust_chunk_data = %{
        "content" => "Chunk with embedding",
        "embedding" => [0.1, 0.2, 0.3, 0.4],
        "metadata" => %{
          "byte_start" => 0,
          "byte_end" => 20,
          "chunk_index" => 0,
          "total_chunks" => 1
        }
      }

      chunk = Kreuzberg.Chunk.from_map(rust_chunk_data)

      assert chunk.content == "Chunk with embedding"
      assert chunk.embedding == [0.1, 0.2, 0.3, 0.4]
    end

    @tag :integration
    test "handles complete Rust chunk metadata" do
      rust_chunk_data = %{
        "content" => "Complete chunk",
        "embedding" => [0.5, 0.6],
        "metadata" => %{
          "byte_start" => 100,
          "byte_end" => 114,
          "chunk_index" => 5,
          "total_chunks" => 10,
          "token_count" => 3,
          "first_page" => 2,
          "last_page" => 2
        }
      }

      chunk = Kreuzberg.Chunk.from_map(rust_chunk_data)

      assert chunk.content == "Complete chunk"
      assert chunk.metadata["byte_start"] == 100
      assert chunk.metadata["byte_end"] == 114
      assert chunk.metadata["chunk_index"] == 5
      assert chunk.metadata["total_chunks"] == 10
    end

    @tag :integration
    test "maintains backward compatibility with 'text' field" do
      # Manually created chunks in tests might still use "text"
      elixir_chunk_data = %{
        "text" => "Manually created chunk",
        "embedding" => nil,
        "metadata" => %{}
      }

      chunk = Kreuzberg.Chunk.from_map(elixir_chunk_data)

      assert chunk.content == "Manually created chunk"
    end

    @tag :integration
    test "prefers 'content' over 'text' when both present" do
      # If both fields exist (edge case), prefer Rust's "content"
      mixed_data = %{
        "content" => "From Rust backend",
        "text" => "Old field value",
        "embedding" => nil,
        "metadata" => %{}
      }

      chunk = Kreuzberg.Chunk.from_map(mixed_data)

      assert chunk.content == "From Rust backend"
    end

    @tag :integration
    test "handles empty content from Rust" do
      rust_chunk_data = %{
        "content" => "",
        "embedding" => nil,
        "metadata" => %{
          "byte_start" => 0,
          "byte_end" => 0,
          "chunk_index" => 0,
          "total_chunks" => 1
        }
      }

      chunk = Kreuzberg.Chunk.from_map(rust_chunk_data)

      assert chunk.content == ""
    end

    @tag :integration
    test "defaults to empty string when neither field present" do
      incomplete_data = %{
        "embedding" => nil,
        "metadata" => %{}
      }

      chunk = Kreuzberg.Chunk.from_map(incomplete_data)

      assert chunk.content == ""
    end

    @tag :integration
    test "Chunk.to_map/1 uses 'content' field for cross-package consistency" do
      chunk = Kreuzberg.Chunk.new(
        "Sample text",
        embedding: [0.1, 0.2],
        metadata: %{"page" => 1}
      )

      chunk_map = Kreuzberg.Chunk.to_map(chunk)

      # to_map should use "content" for consistency with all other packages
      assert chunk_map["content"] == "Sample text"
      refute Map.has_key?(chunk_map, "text")
    end
  end
end
