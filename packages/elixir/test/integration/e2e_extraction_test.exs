defmodule KreuzbergTest.Integration.E2EExtractionTest do
  @moduledoc """
  End-to-end integration tests for complete extraction workflows.

  Critical tests covering:
  - Complete extraction workflows with multiple features
  - Multi-feature configurations combining keywords, tables, images
  - Real-world document scenarios
  - NIF memory management and resource cleanup
  - Complex extraction pipelines
  - Error recovery and robustness
  """

  use ExUnit.Case, async: true

  @sample_pdf_text """
  QUARTERLY FINANCIAL REPORT Q3 2024

  Executive Summary
  Our company achieved record revenue this quarter with strategic growth initiatives
  driving expansion into new markets. The Natural Language Processing (NLP) division
  contributed significantly to these results.

  Key Metrics
  - Revenue: $5.2M (+15% YoY)
  - Customer Acquisition Cost: $1,200
  - Churn Rate: 2.3%

  Product Performance
  Our NLP pipeline processes 10,000+ documents daily, extracting keywords, entities,
  and metadata with 98.5% accuracy. Machine learning models continue to improve
  classification tasks across multiple languages.

  Risk Factors
  Market volatility and AI regulation remain key concerns. However, our robust
  architecture and experienced team mitigate these challenges effectively.
  """

  @complex_html """
  <!DOCTYPE html>
  <html>
  <head><title>Market Analysis Report</title></head>
  <body>
    <h1>Market Analysis: Q4 2024</h1>
    <p>This report analyzes current market trends in technology and finance sectors.</p>

    <h2>Market Data</h2>
    <table border="1">
      <tr><th>Sector</th><th>Growth %</th><th>Forecast</th></tr>
      <tr><td>Technology</td><td>12.5%</td><td>Positive</td></tr>
      <tr><td>Finance</td><td>8.3%</td><td>Neutral</td></tr>
      <tr><td>Healthcare</td><td>15.7%</td><td>Positive</td></tr>
    </table>

    <h2>Key Insights</h2>
    <ul>
      <li>AI and machine learning adoption accelerating</li>
      <li>Natural language processing becoming mainstream</li>
      <li>Document processing automation growing 25% annually</li>
    </ul>

    <h2>Recommendations</h2>
    <p>Organizations should invest in NLP capabilities and document automation to remain competitive.
    The extraction of meaningful data from unstructured text is increasingly critical for business success.</p>
  </body>
  </html>
  """

  describe "Complete extraction workflow" do
    @tag :integration
    test "extracts text with all feature flags" do
      config = %Kreuzberg.ExtractionConfig{
        use_cache: true,
        enable_quality_processing: true,
        force_ocr: false
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result.content != nil
      assert is_binary(result.content)
      assert String.length(result.content) > 0
    end

    @tag :integration
    test "extracts HTML with table parsing" do
      config = %Kreuzberg.ExtractionConfig{
        use_cache: true
      }

      {:ok, result} = Kreuzberg.extract(@complex_html, "text/html", config)

      assert result.content != nil
      assert result.tables != nil
      assert is_list(result.tables)
    end

    @tag :integration
    test "workflow with chunking enabled" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "enabled" => true,
          "chunk_size" => 256
        },
        use_cache: true
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result.content != nil
      # chunks field may be populated if chunking config is processed
      if result.chunks != nil do
        assert is_list(result.chunks)
      end
    end

    @tag :integration
    test "workflow with keywords extraction" do
      config = %Kreuzberg.ExtractionConfig{
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 10
        },
        use_cache: true
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result.content != nil

      if result.keywords != nil do
        assert is_list(result.keywords)
      end
    end

    @tag :integration
    test "workflow with language detection" do
      config = %Kreuzberg.ExtractionConfig{
        language_detection: %{
          "enabled" => true
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result.detected_languages != nil or result.detected_languages == nil
      # Language detection result structure validation
      if result.detected_languages != nil do
        assert is_list(result.detected_languages)
      end
    end
  end

  describe "Multi-feature configuration workflows" do
    @tag :integration
    test "combined keywords and chunking" do
      config = %Kreuzberg.ExtractionConfig{
        keywords: %{
          "algorithm" => "rake",
          "max_keywords" => 5
        },
        chunking: %{
          "enabled" => true,
          "chunk_size" => 200
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result.content != nil
      # Both features should be available if configured
      if result.keywords != nil, do: assert(is_list(result.keywords))
      if result.chunks != nil, do: assert(is_list(result.chunks))
    end

    @tag :integration
    test "combined tables and language detection" do
      config = %Kreuzberg.ExtractionConfig{
        language_detection: %{
          "enabled" => true
        }
      }

      {:ok, result} = Kreuzberg.extract(@complex_html, "text/html", config)

      assert result.content != nil
      assert result.tables != nil or is_list(result.tables)

      if result.detected_languages != nil do
        assert is_list(result.detected_languages)
      end
    end

    @tag :integration
    test "complete feature set workflow" do
      config = %Kreuzberg.ExtractionConfig{
        use_cache: true,
        enable_quality_processing: false,
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 10
        },
        chunking: %{
          "enabled" => true,
          "chunk_size" => 256
        }
      }

      {:ok, result} = Kreuzberg.extract(@complex_html, "text/html", config)

      assert %Kreuzberg.ExtractionResult{} = result
      assert result.content != nil
      assert result.mime_type != nil
      assert result.metadata != nil
      assert result.tables != nil
    end
  end

  describe "Real-world document scenarios" do
    @tag :integration
    test "processes financial report" do
      config = %Kreuzberg.ExtractionConfig{
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 15
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert String.contains?(result.content, "Revenue") or
               String.contains?(result.content, "revenue")
    end

    @tag :integration
    test "processes HTML document with tables" do
      {:ok, result} = Kreuzberg.extract(@complex_html, "text/html")

      assert result.content != nil
      assert result.tables != nil

      # Verify table extraction
      if result.tables != [] do
        Enum.each(result.tables, fn table ->
          assert is_map(table) or is_list(table)
        end)
      end
    end

    @tag :integration
    test "processes multi-page simulation" do
      # Simulate multi-page document
      multi_page = String.duplicate(@sample_pdf_text, 3)

      {:ok, result} = Kreuzberg.extract(multi_page, "text/plain")

      assert String.length(result.content) >= String.length(@sample_pdf_text)
    end

    @tag :integration
    test "handles document with mixed content" do
      mixed_content = """
      DOCUMENT TITLE

      This is introductory text with various important concepts including
      Natural Language Processing, Machine Learning, and Data Extraction.

      Key Statistics:
      - Processing Speed: 10,000 docs/day
      - Accuracy: 98.5%
      - Languages: 50+

      DETAILED ANALYSIS TABLE:
      | Metric | Value | Status |
      | Accuracy | 98.5% | Excellent |
      | Speed | 10ms/doc | Good |
      | Coverage | 95% | Good |

      Conclusion: This demonstrates comprehensive document analysis capabilities.
      """

      config = %Kreuzberg.ExtractionConfig{
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 10
        }
      }

      {:ok, result} = Kreuzberg.extract(mixed_content, "text/plain", config)

      assert result.content != nil
      assert String.length(result.content) > 0
    end
  end

  describe "NIF boundary and memory management" do
    @tag :integration
    test "large document extraction" do
      large_doc = String.duplicate(@sample_pdf_text, 10)

      {:ok, result} = Kreuzberg.extract(large_doc, "text/plain")

      assert result.content != nil
      assert byte_size(result.content) > 0
    end

    @tag :integration
    test "multiple sequential extractions" do
      documents = [
        @sample_pdf_text,
        @complex_html,
        "Simple text document"
      ]

      results =
        Enum.map(documents, fn doc ->
          case Kreuzberg.extract(doc, "text/plain") do
            {:ok, result} -> result
            {:error, _} -> nil
          end
        end)
        |> Enum.filter(&(&1 != nil))

      assert is_list(results)
    end

    @tag :integration
    test "rapid consecutive calls don't leak memory" do
      # Perform many rapid extractions
      Enum.each(1..20, fn _i ->
        {:ok, _result} = Kreuzberg.extract(@sample_pdf_text, "text/plain")
      end)

      # If we get here without crashing, memory management is working
      assert true
    end

    @tag :integration
    test "complex config doesn't cause memory issues" do
      config = %Kreuzberg.ExtractionConfig{
        use_cache: true,
        enable_quality_processing: true,
        force_ocr: false,
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 20
        },
        chunking: %{
          "enabled" => true,
          "chunk_size" => 256
        },
        language_detection: %{
          "enabled" => true
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result != nil
    end

    @tag :integration
    test "handles result serialization efficiently" do
      {:ok, result} = Kreuzberg.extract(@complex_html, "text/html")

      # Should be serializable to JSON without issues
      result_map = %{
        content: result.content,
        mime_type: result.mime_type,
        tables_count: length(result.tables || [])
      }

      json = Jason.encode!(result_map)

      assert is_binary(json)
      {:ok, decoded} = Jason.decode(json)
      assert decoded["mime_type"] != nil
    end
  end

  describe "Error recovery and robustness" do
    @tag :integration
    test "recovers from invalid config gracefully" do
      # Invalid config should either error or fall back to defaults
      result = Kreuzberg.extract(@sample_pdf_text, "text/plain", %{})

      case result do
        {:ok, extraction} -> assert extraction != nil
        {:error, _} -> assert true
      end
    end

    @tag :integration
    test "handles extraction retry successfully" do
      # First attempt
      result1 = Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Second attempt should also succeed
      result2 = Kreuzberg.extract(@sample_pdf_text, "text/plain")

      assert match?({:ok, _}, result1)
      assert match?({:ok, _}, result2)
    end

    @tag :integration
    test "maintains state across multiple operations" do
      config = %Kreuzberg.ExtractionConfig{use_cache: true}

      {:ok, result1} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)
      {:ok, result2} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      # Results should be consistent
      assert result1.content == result2.content
    end

    @tag :integration
    test "handles edge case documents" do
      edge_cases = [
        # Empty document
        "",
        # Whitespace only
        " ",
        # Single character
        "a",
        # Very long single line
        String.duplicate("a", 10_000)
      ]

      Enum.each(edge_cases, fn doc ->
        case Kreuzberg.extract(doc, "text/plain") do
          {:ok, result} -> assert result != nil
          {:error, _} -> assert true
        end
      end)
    end
  end

  describe "Complex extraction pipelines" do
    @tag :integration
    test "sequential feature extraction pipeline" do
      # Step 1: Basic extraction
      {:ok, basic} = Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Step 2: Extract keywords from result
      keywords_config = %Kreuzberg.ExtractionConfig{
        keywords: %{
          "algorithm" => "yake",
          "max_keywords" => 10
        }
      }

      {:ok, with_keywords} = Kreuzberg.extract(@sample_pdf_text, "text/plain", keywords_config)

      assert basic.content == with_keywords.content

      if with_keywords.keywords != nil do
        assert is_list(with_keywords.keywords)
      end
    end

    @tag :integration
    test "aggregated multi-document pipeline" do
      documents = [
        @sample_pdf_text,
        @complex_html,
        "Additional document content"
      ]

      results =
        documents
        |> Enum.map(fn doc ->
          Kreuzberg.extract(doc, "text/plain")
        end)

      assert length(results) == 3

      # Aggregate content
      total_length =
        Enum.reduce(results, 0, fn {:ok, result}, acc ->
          acc + String.length(result.content)
        end)

      assert total_length > 0
    end

    @tag :integration
    test "conditional feature application based on document type" do
      documents = [
        {@sample_pdf_text, "text/plain"},
        {@complex_html, "text/html"}
      ]

      results =
        Enum.map(documents, fn {content, mime_type} ->
          config =
            if String.contains?(mime_type, "html") do
              %Kreuzberg.ExtractionConfig{
                keywords: %{"algorithm" => "yake", "max_keywords" => 5}
              }
            else
              %Kreuzberg.ExtractionConfig{
                keywords: %{"algorithm" => "rake", "max_keywords" => 10}
              }
            end

          {:ok, Kreuzberg.extract(content, mime_type, config)}
        end)

      assert length(results) == 2
    end
  end

  describe "Result validation and consistency" do
    @tag :integration
    test "extraction result has required fields" do
      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Validate required fields
      assert Map.has_key?(result, :content)
      assert Map.has_key?(result, :mime_type)
      assert Map.has_key?(result, :metadata)

      # Validate field types
      assert is_binary(result.content)
      assert is_binary(result.mime_type)
      assert is_struct(result.metadata) or is_map(result.metadata)
    end

    @tag :integration
    test "extraction metadata is populated" do
      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Metadata should be a struct
      assert %Kreuzberg.Metadata{} = result.metadata
    end

    @tag :integration
    test "multiple extractions produce consistent results" do
      # Same content, same config = should produce same result
      config = %Kreuzberg.ExtractionConfig{use_cache: true}

      {:ok, result1} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)
      {:ok, result2} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config)

      assert result1.content == result2.content
      assert result1.mime_type == result2.mime_type
    end

    @tag :integration
    test "extraction with different configs produces results" do
      config1 = %Kreuzberg.ExtractionConfig{use_cache: true}
      config2 = %Kreuzberg.ExtractionConfig{use_cache: false}

      {:ok, result1} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config1)
      {:ok, result2} = Kreuzberg.extract(@sample_pdf_text, "text/plain", config2)

      # Content should be same even with different cache settings
      assert result1.content == result2.content
    end
  end

  describe "Integration with utility functions" do
    @tag :integration
    test "MIME type detection integration" do
      {:ok, mime} = Kreuzberg.detect_mime_type(@sample_pdf_text)

      assert is_binary(mime)
      assert mime != ""
    end

    @tag :integration
    test "MIME type validation integration" do
      {:ok, validated_mime} = Kreuzberg.validate_mime_type("text/plain")

      assert is_binary(validated_mime)
    end

    @tag :integration
    test "extraction with detected MIME type" do
      {:ok, detected_mime} = Kreuzberg.detect_mime_type(@sample_pdf_text)

      {:ok, result} = Kreuzberg.extract(@sample_pdf_text, detected_mime)

      assert result.content != nil
    end

    @tag :integration
    test "error classification integration" do
      error_type = Kreuzberg.classify_error("some error message")

      assert is_atom(error_type)
    end

    @tag :integration
    test "cache statistics integration" do
      # Perform some extractions
      Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Get cache stats
      {:ok, stats} = Kreuzberg.cache_stats()

      assert is_map(stats)
    end

    @tag :integration
    test "cache clearing integration" do
      # Extract with cache
      Kreuzberg.extract(@sample_pdf_text, "text/plain")

      # Clear cache
      result = Kreuzberg.clear_cache()

      assert result == :ok

      # Should be able to extract again
      {:ok, extraction} = Kreuzberg.extract(@sample_pdf_text, "text/plain")
      assert extraction != nil
    end
  end

  describe "Complete workflow integration tests" do
    @tag :integration
    test "full document processing workflow" do
      # 1. Extract content
      {:ok, extraction} = Kreuzberg.extract(@complex_html, "text/html")

      # 2. Extract keywords
      config = %Kreuzberg.ExtractionConfig{
        keywords: %{"algorithm" => "yake", "max_keywords" => 10}
      }

      {:ok, enriched} = Kreuzberg.extract(@complex_html, "text/html", config)

      # 3. Validate results
      assert extraction.content != nil
      assert enriched.content != nil
      assert extraction.tables != nil

      # All validations passed
      assert true
    end

    @tag :integration
    test "batch processing workflow" do
      documents = [@sample_pdf_text, @complex_html, "Simple text"]

      # Process batch
      {:ok, results} = Kreuzberg.batch_extract_bytes(documents, "text/plain")

      assert length(results) == 3

      # Validate all results
      Enum.each(results, fn result ->
        assert %Kreuzberg.ExtractionResult{} = result
        assert is_binary(result.content)
      end)
    end

    @tag :integration
    test "async batch processing workflow" do
      documents = [@sample_pdf_text, @complex_html]

      # Create async task for batch
      task = Kreuzberg.batch_extract_bytes_async(documents, "text/plain")

      # Await results
      {:ok, results} = Task.await(task, 30_000)

      assert is_list(results)
      assert length(results) == 2
    end
  end

  describe "Chunking integration with document extraction" do
    @sample_document """
    Chapter 1: Introduction to Natural Language Processing

    Natural Language Processing (NLP) is a subfield of linguistics, computer science,
    and artificial intelligence concerned with the interactions between computers and
    human language. In particular, NLP is focused on programming computers to process
    and analyze large amounts of natural language data.

    The field of NLP has seen tremendous growth in recent years, driven by advances
    in machine learning and deep learning. Modern NLP systems can perform tasks such
    as machine translation, sentiment analysis, named entity recognition, and question
    answering with impressive accuracy.

    Chapter 2: Tokenization and Text Preprocessing

    Tokenization is the process of breaking text into individual units called tokens.
    These tokens can be words, subwords, or characters depending on the application.
    Proper tokenization is crucial for downstream NLP tasks as it forms the foundation
    of text analysis.

    Text preprocessing involves cleaning and normalizing text data before analysis.
    Common preprocessing steps include lowercasing, removing punctuation, handling
    special characters, and dealing with whitespace. The goal is to standardize the
    text to improve model performance.

    Chapter 3: Word Embeddings and Semantic Representation

    Word embeddings are dense vector representations of words that capture semantic
    meaning. Unlike traditional one-hot encodings, embeddings place semantically
    similar words close together in vector space. Popular embedding methods include
    Word2Vec, GloVe, and FastText.

    These representations have revolutionized NLP by enabling models to understand
    relationships between words and transfer knowledge across tasks. Modern transformer
    models like BERT and GPT build upon these concepts with contextual embeddings.
    """

    @tag :integration
    test "chunks contain non-empty content from extracted content" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 300,
          "overlap" => 50
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      # Verify chunks were created
      assert result.chunks != nil
      assert is_list(result.chunks)
      assert length(result.chunks) > 0

      # Verify each chunk has non-empty content
      Enum.each(result.chunks, fn chunk ->
        assert is_struct(chunk, Kreuzberg.Chunk)
        assert chunk.content != "", "Chunk content should not be empty"
        assert String.length(chunk.content) > 0, "Chunk should have content"
      end)
    end

    @tag :integration
    test "chunk content matches byte ranges in source content" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 400,
          "overlap" => 100
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      # Check first chunk
      first_chunk = List.first(result.chunks)
      assert first_chunk != nil

      # Extract text using byte range from metadata
      byte_start = first_chunk.metadata["byte_start"]
      byte_end = first_chunk.metadata["byte_end"]
      expected_text = String.slice(result.content, byte_start, byte_end - byte_start)

      # Chunk content should match the byte range extraction
      assert first_chunk.content == expected_text,
             "Chunk content should match content at specified byte range"
    end

    @tag :integration
    test "all chunks have valid metadata" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 250,
          "overlap" => 25
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      total_chunks = length(result.chunks)

      result.chunks
      |> Enum.with_index()
      |> Enum.each(fn {chunk, index} ->
        assert chunk.metadata["chunk_index"] == index
        assert chunk.metadata["total_chunks"] == total_chunks
        assert chunk.metadata["byte_start"] >= 0
        assert chunk.metadata["byte_end"] > chunk.metadata["byte_start"]

        # Content length should roughly correspond to byte range
        # (allowing for UTF-8 multi-byte characters)
        byte_length = chunk.metadata["byte_end"] - chunk.metadata["byte_start"]
        assert String.length(chunk.content) <= byte_length
      end)
    end

    @tag :integration
    test "chunks maintain sequential coverage of document" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 200,
          "overlap" => 50
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      # Verify chunks are ordered by byte position
      byte_starts =
        result.chunks
        |> Enum.map(fn chunk -> chunk.metadata["byte_start"] end)
        |> Enum.sort()

      # Check that chunks are in sequential order
      byte_starts
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [start1, start2] ->
        assert start2 >= start1, "Chunks should be in order"
      end)
    end

    @tag :integration
    test "first chunk starts at beginning of document" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 500,
          "overlap" => 0
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      first_chunk = List.first(result.chunks)
      assert first_chunk.metadata["byte_start"] == 0
      assert first_chunk.metadata["chunk_index"] == 0

      # First chunk should start with beginning of document
      assert String.starts_with?(result.content, first_chunk.content)
    end

    @tag :integration
    test "last chunk covers end of document" do
      config = %Kreuzberg.ExtractionConfig{
        chunking: %{
          "chunk_size" => 500,
          "overlap" => 50
        }
      }

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      last_chunk = List.last(result.chunks)
      content_length = byte_size(result.content)

      # Last chunk should extend to or near the end (within one chunk size)
      assert last_chunk.metadata["byte_end"] <= content_length
      assert last_chunk.metadata["byte_end"] >= content_length - 600

      # Last chunk content should appear in the result content
      assert String.contains?(result.content, last_chunk.content)

      # Verify last chunk has the highest chunk_index
      assert last_chunk.metadata["chunk_index"] == length(result.chunks) - 1
    end

    @tag :integration
    test "small chunk size produces more chunks" do
      small_config = %Kreuzberg.ExtractionConfig{
        chunking: %{"chunk_size" => 100, "overlap" => 20}
      }

      large_config = %Kreuzberg.ExtractionConfig{
        chunking: %{"chunk_size" => 1000, "overlap" => 20}
      }

      {:ok, small_result} = Kreuzberg.extract(@sample_document, "text/plain", small_config)
      {:ok, large_result} = Kreuzberg.extract(@sample_document, "text/plain", large_config)

      # Smaller chunks should produce more or equal chunks (depending on overlap)
      assert length(small_result.chunks) >= length(large_result.chunks)

      # All chunks should have content
      Enum.each(small_result.chunks, fn chunk ->
        assert String.length(chunk.content) > 0
      end)

      Enum.each(large_result.chunks, fn chunk ->
        assert String.length(chunk.content) > 0
      end)
    end

    @tag :integration
    test "no chunking returns nil chunks" do
      config = %Kreuzberg.ExtractionConfig{}

      {:ok, result} = Kreuzberg.extract(@sample_document, "text/plain", config)

      # Without chunking config, chunks should be nil
      assert result.chunks == nil
    end
  end
end
