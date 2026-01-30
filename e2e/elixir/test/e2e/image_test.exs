# Auto-generated tests for image fixtures.

# To regenerate: cargo run -p kreuzberg-e2e-generator -- generate --lang elixir

defmodule E2E.ImageTest do
  use ExUnit.Case, async: false

  describe "image fixtures" do
    test "image_metadata_only" do
      case E2E.Helpers.run_fixture(
        "image_metadata_only",
        "images/example.jpg",
        %{ocr: nil},
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["image/jpeg"])
          |> E2E.Helpers.assert_max_content_length(100)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end
  end
end
