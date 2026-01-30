# Auto-generated tests for email fixtures.

# To regenerate: cargo run -p kreuzberg-e2e-generator -- generate --lang elixir

defmodule E2E.EmailTest do
  use ExUnit.Case, async: false

  describe "email fixtures" do
    test "email_sample_eml" do
      case E2E.Helpers.run_fixture(
        "email_sample_eml",
        "email/sample_email.eml",
        nil,
        requirements: [],
        notes: nil,
        skip_if_missing: true
      ) do
        {:ok, result} ->
          result
          |> E2E.Helpers.assert_expected_mime(["message/rfc822"])
          |> E2E.Helpers.assert_min_content_length(20)

        {:skipped, reason} ->
          IO.puts("SKIPPED: #{reason}")

        {:error, reason} ->
          flunk("Extraction failed: #{inspect(reason)}")
      end
    end
  end
end
