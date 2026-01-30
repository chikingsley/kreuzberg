# Auto-generated tests for ocr fixtures.

# To regenerate: cargo run -p kreuzberg-e2e-generator -- generate --lang elixir

defmodule E2E.OcrTest do
  use ExUnit.Case, async: false

  describe "ocr fixtures" do
    test "ocr_image_hello_world" do
      case E2E.Helpers.run_fixture(
        "ocr_image_hello_world",
        "images/test_hello_world.png",
        %{force_ocr: true, ocr: %{backend: "tesseract", language: "eng"}},
        requirements: ["tesseract", "tesseract"],
        notes: "Requires Tesseract OCR for image text extraction.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["image/png"])
          |> E2E.Helpers.assert_min_content_length(5)
          |> E2E.Helpers.assert_content_contains_any(["hello", "world"])

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "ocr_image_no_text" do
      case E2E.Helpers.run_fixture(
        "ocr_image_no_text",
        "images/flower_no_text.jpg",
        %{force_ocr: true, ocr: %{backend: "tesseract", language: "eng"}},
        requirements: ["tesseract", "tesseract"],
        notes: "Skip when Tesseract is unavailable.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["image/jpeg"])
          |> E2E.Helpers.assert_max_content_length(200)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "ocr_pdf_image_only_german" do
      case E2E.Helpers.run_fixture(
        "ocr_pdf_image_only_german",
        "pdfs/image_only_german_pdf.pdf",
        %{force_ocr: true, ocr: %{backend: "tesseract", language: "eng"}},
        requirements: ["tesseract", "tesseract"],
        notes: "Skip if OCR backend unavailable.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/pdf"])
          |> E2E.Helpers.assert_min_content_length(20)
          |> E2E.Helpers.assert_metadata_expectation("format_type", %{eq: "pdf"})

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "ocr_pdf_rotated_90" do
      case E2E.Helpers.run_fixture(
        "ocr_pdf_rotated_90",
        "pdfs/ocr_test_rotated_90.pdf",
        %{force_ocr: true, ocr: %{backend: "tesseract", language: "eng"}},
        requirements: ["tesseract", "tesseract"],
        notes: "Skip automatically when OCR backend is missing.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/pdf"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "ocr_pdf_tesseract" do
      case E2E.Helpers.run_fixture(
        "ocr_pdf_tesseract",
        "pdfs/ocr_test.pdf",
        %{force_ocr: true, ocr: %{backend: "tesseract", language: "eng"}},
        requirements: ["tesseract", "tesseract"],
        notes: "Skip automatically if OCR backend is unavailable.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/pdf"])
          |> E2E.Helpers.assert_min_content_length(20)
          |> E2E.Helpers.assert_content_contains_any(["Docling", "Markdown", "JSON"])

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end
  end
end
