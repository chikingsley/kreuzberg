defmodule KreuzbergTestApp.SmokeTest do
  use ExUnit.Case, async: true
  import KreuzbergTestApp.TestHelpers

  @moduledoc """
  Smoke tests to verify basic Kreuzberg functionality.
  """

  describe "basic extraction" do
    test "can extract from PDF" do
      if test_doc_exists?("tiny.pdf") do
        result = Kreuzberg.extract_file(test_doc_path("tiny.pdf"), "application/pdf")
        extraction = assert_extraction_success(result)
        assert extraction.mime_type == "application/pdf"
      end
    end

    test "can extract from DOCX" do
      if test_doc_exists?("lorem_ipsum.docx") do
        result =
          Kreuzberg.extract_file(
            test_doc_path("lorem_ipsum.docx"),
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          )

        extraction = assert_extraction_success(result)

        assert extraction.mime_type ==
                 "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

        assert_contains(extraction.content, "Lorem ipsum")
      end
    end

    test "can extract from plain text" do
      binary = "Hello, World! This is a test document."
      result = Kreuzberg.extract(binary, "text/plain")
      extraction = assert_extraction_success(result)
      assert_contains(extraction.content, "Hello, World!")
    end
  end

  describe "extraction with configuration" do
    test "can use extraction config" do
      if test_doc_exists?("tiny.pdf") do
        config = %Kreuzberg.ExtractionConfig{
          use_cache: false
        }

        result = Kreuzberg.extract_file(test_doc_path("tiny.pdf"), "application/pdf", config)
        assert_extraction_success(result)
      end
    end
  end

  describe "batch extraction" do
    test "can batch extract files" do
      if test_doc_exists?("tiny.pdf") do
        paths = [test_doc_path("tiny.pdf")]
        results = Kreuzberg.batch_extract_files(paths, "application/pdf")

        assert {:ok, [result]} = results
        assert is_binary(result.content)
      end
    end
  end

  describe "error handling" do
    test "returns error for invalid file" do
      result = Kreuzberg.extract_file("/nonexistent/file.pdf", "application/pdf")
      assert {:error, _reason} = result
    end

    test "returns error for invalid binary" do
      result = Kreuzberg.extract(<<0, 1, 2, 3>>, "application/pdf")
      assert {:error, _reason} = result
    end
  end

  describe "utility functions" do
    test "can detect MIME type" do
      binary = "Hello, World!"
      {:ok, mime_type} = Kreuzberg.detect_mime_type(binary)
      assert is_binary(mime_type)
    end

    test "can validate MIME type" do
      assert {:ok, "application/pdf"} = Kreuzberg.validate_mime_type("application/pdf")
      assert {:ok, "text/plain"} = Kreuzberg.validate_mime_type("text/plain")
    end
  end
end
