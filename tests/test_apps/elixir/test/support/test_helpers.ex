defmodule KreuzbergTestApp.TestHelpers do
  @moduledoc """
  Helper functions for Kreuzberg test suite.
  """

  import ExUnit.Assertions

  @doc """
  Get the path to a test document.
  """
  def test_doc_path(filename) do
    Path.join([__DIR__, "..", "..", "test_documents", filename])
  end

  @doc """
  Check if a test document exists.
  """
  def test_doc_exists?(filename) do
    File.exists?(test_doc_path(filename))
  end

  @doc """
  Read test document binary.
  """
  def read_test_doc(filename) do
    File.read!(test_doc_path(filename))
  end

  @doc """
  Assert that extraction succeeded and returned content.
  """
  def assert_extraction_success(result) do
    assert {:ok, extraction_result} = result
    assert is_binary(extraction_result.content)
    assert byte_size(extraction_result.content) > 0
    extraction_result
  end

  @doc """
  Assert that result contains expected text.
  """
  def assert_contains(content, expected) when is_binary(content) and is_binary(expected) do
    assert String.contains?(content, expected),
           "Expected content to contain '#{expected}', but it did not"
  end
end
