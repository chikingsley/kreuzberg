# Auto-generated tests for structured fixtures.

# To regenerate: cargo run -p kreuzberg-e2e-generator -- generate --lang elixir

defmodule E2E.StructuredTest do
  use ExUnit.Case, async: false

  describe "structured fixtures" do
    test "structured_json_basic" do
      case E2E.Helpers.run_fixture(
        "structured_json_basic",
        "json/sample_document.json",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/json"])
          |> E2E.Helpers.assert_min_content_length(20)
          |> E2E.Helpers.assert_content_contains_any(["Sample Document", "Test Author"])

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "structured_json_simple" do
      case E2E.Helpers.run_fixture(
        "structured_json_simple",
        "data_formats/simple.json",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/json"])
          |> E2E.Helpers.assert_min_content_length(10)
          |> E2E.Helpers.assert_content_contains_any(["{", "name"])

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end

    test "structured_yaml_simple" do
      case E2E.Helpers.run_fixture(
        "structured_yaml_simple",
        "data_formats/simple.yaml",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["application/x-yaml"])
          |> E2E.Helpers.assert_min_content_length(10)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end
  end
end
