# Auto-generated tests for office fixtures.

# To regenerate: cargo run -p kreuzberg-e2e-generator -- generate --lang elixir

defmodule E2E.OfficeTest do
  use ExUnit.Case, async: false

  describe "office fixtures" do
    test "office_doc_legacy" do
      case E2E.Helpers.run_fixture(
        "office_doc_legacy",
        "legacy_office/unit_test_lists.doc",
        nil,
        requirements: ["libreoffice", "libreoffice"],
        notes: "LibreOffice must be installed for conversion.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/msword"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_basic" do
      case E2E.Helpers.run_fixture(
        "office_docx_basic",
        "office/document.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_equations" do
      case E2E.Helpers.run_fixture(
        "office_docx_equations",
        "documents/equations.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_fake" do
      case E2E.Helpers.run_fixture(
        "office_docx_fake",
        "documents/fake.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_formatting" do
      case E2E.Helpers.run_fixture(
        "office_docx_formatting",
        "documents/unit_test_formatting.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_headers" do
      case E2E.Helpers.run_fixture(
        "office_docx_headers",
        "documents/unit_test_headers.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_lists" do
      case E2E.Helpers.run_fixture(
        "office_docx_lists",
        "documents/unit_test_lists.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_docx_tables" do
      case E2E.Helpers.run_fixture(
        "office_docx_tables",
        "documents/docx_tables.docx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
          |> E2E.Helpers.assert_min_content_length(50)
          |> E2E.Helpers.assert_content_contains_all(["Simple uniform table", "Nested Table", "merged cells", "Header Col"])
          |> E2E.Helpers.assert_table_count(1, nil)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_ppsx_slideshow" do
      case E2E.Helpers.run_fixture(
        "office_ppsx_slideshow",
        "presentations/sample.ppsx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.presentationml.slideshow"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_ppt_legacy" do
      case E2E.Helpers.run_fixture(
        "office_ppt_legacy",
        "legacy_office/simple.ppt",
        nil,
        requirements: ["libreoffice", "libreoffice"],
        notes: "Skip if LibreOffice conversion is unavailable.",
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.ms-powerpoint"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_pptx_basic" do
      case E2E.Helpers.run_fixture(
        "office_pptx_basic",
        "presentations/simple.pptx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.presentationml.presentation"])
          |> E2E.Helpers.assert_min_content_length(50)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_pptx_images" do
      case E2E.Helpers.run_fixture(
        "office_pptx_images",
        "presentations/powerpoint_with_image.pptx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.presentationml.presentation"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_pptx_pitch_deck" do
      case E2E.Helpers.run_fixture(
        "office_pptx_pitch_deck",
        "presentations/pitch_deck_presentation.pptx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.presentationml.presentation"])
          |> E2E.Helpers.assert_min_content_length(100)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_xls_legacy" do
      case E2E.Helpers.run_fixture(
        "office_xls_legacy",
        "spreadsheets/test_excel.xls",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.ms-excel"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_xlsx_basic" do
      case E2E.Helpers.run_fixture(
        "office_xlsx_basic",
        "spreadsheets/stanley_cups.xlsx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"])
          |> E2E.Helpers.assert_min_content_length(100)
          |> E2E.Helpers.assert_content_contains_all(["Team", "Location", "Stanley Cups"])
          |> E2E.Helpers.assert_table_count(1, nil)
          |> E2E.Helpers.assert_metadata_expectation("sheet_count", %{gte: 2})
          |> E2E.Helpers.assert_metadata_expectation("sheet_names", %{contains: ["Stanley Cups"]})

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_xlsx_multi_sheet" do
      case E2E.Helpers.run_fixture(
        "office_xlsx_multi_sheet",
        "spreadsheets/excel_multi_sheet.xlsx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"])
          |> E2E.Helpers.assert_min_content_length(20)
          |> E2E.Helpers.assert_metadata_expectation("sheet_count", %{gte: 2})

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "office_xlsx_office_example" do
      case E2E.Helpers.run_fixture(
        "office_xlsx_office_example",
        "office/excel.xlsx",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end
  end
end
