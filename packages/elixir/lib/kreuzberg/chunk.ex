defmodule Kreuzberg.Chunk do
  @moduledoc """
  Structure representing a text chunk with embedding for semantic search.

  Contains a portion of extracted text along with its vector embedding
  and optional metadata for use in RAG (Retrieval-Augmented Generation)
  and semantic search applications.

  ## Fields

    * `:content` - The text content of this chunk
    * `:embedding` - Vector embedding (list of floats) for semantic search
    * `:metadata` - Optional metadata about the chunk (page number, position, etc.)
    * `:token_count` - Number of tokens in the chunk (if available)
    * `:start_position` - Character position where chunk starts in original text
    * `:confidence` - Confidence score for the embedding (0.0-1.0)

  ## Examples

      iex> chunk = %Kreuzberg.Chunk{
      ...>   content: "This is a chunk of extracted text",
      ...>   embedding: [0.1, 0.2, 0.3, 0.4],
      ...>   metadata: %{"page" => 1, "section" => "Introduction"}
      ...> }
      iex> chunk.content
      "This is a chunk of extracted text"
  """

  @type embedding :: list(float())

  @type t :: %__MODULE__{
          content: String.t(),
          embedding: embedding() | nil,
          metadata: map() | nil,
          token_count: integer() | nil,
          start_position: integer() | nil,
          confidence: float() | nil
        }

  defstruct [
    :content,
    :embedding,
    :metadata,
    :token_count,
    :start_position,
    :confidence
  ]

  @doc """
  Creates a new Chunk struct with required content field.

  ## Parameters

    * `content` - The text content of the chunk
    * `opts` - Optional keyword list with:
      * `:embedding` - Vector embedding list
      * `:metadata` - Metadata map
      * `:token_count` - Token count
      * `:start_position` - Starting character position
      * `:confidence` - Confidence score

  ## Returns

  A `Chunk` struct with the provided content and options.

  ## Examples

      iex> Kreuzberg.Chunk.new("chunk text")
      %Kreuzberg.Chunk{content: "chunk text"}

      iex> Kreuzberg.Chunk.new(
      ...>   "chunk text",
      ...>   embedding: [0.1, 0.2],
      ...>   metadata: %{"page" => 1}
      ...> )
      %Kreuzberg.Chunk{
        content: "chunk text",
        embedding: [0.1, 0.2],
        metadata: %{"page" => 1}
      }
  """
  @spec new(String.t(), keyword()) :: t()
  def new(content, opts \\ []) when is_binary(content) do
    %__MODULE__{
      content: content,
      embedding: Keyword.get(opts, :embedding),
      metadata: Keyword.get(opts, :metadata),
      token_count: Keyword.get(opts, :token_count),
      start_position: Keyword.get(opts, :start_position),
      confidence: Keyword.get(opts, :confidence)
    }
  end

  @doc """
  Creates a Chunk struct from a map.

  Converts a plain map (typically from NIF/Rust) into a proper struct.

  The Rust backend serializes chunks with a "content" field, which aligns
  with all other language packages. For backward compatibility during migration,
  maps with "text" keys are also supported (but will be removed in a future version).

  ## Parameters

    * `data` - A map containing chunk fields. Accepts either "content" (from Rust
      and all other packages) or "text" (for backward compatibility) as the text field key.

  ## Returns

  A `Chunk` struct with matching fields populated.

  ## Examples

      # From Rust/NIF (with "content" field) - standard format
      iex> rust_chunk = %{
      ...>   "content" => "chunk content from Rust",
      ...>   "embedding" => [0.1, 0.2, 0.3]
      ...> }
      iex> Kreuzberg.Chunk.from_map(rust_chunk)
      %Kreuzberg.Chunk{
        content: "chunk content from Rust",
        embedding: [0.1, 0.2, 0.3]
      }

      # Legacy format (with "text" field) - for backward compatibility
      iex> legacy_chunk = %{
      ...>   "text" => "legacy format chunk",
      ...>   "embedding" => [0.4, 0.5, 0.6]
      ...> }
      iex> Kreuzberg.Chunk.from_map(legacy_chunk)
      %Kreuzberg.Chunk{
        content: "legacy format chunk",
        embedding: [0.4, 0.5, 0.6]
      }
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      content: data["content"] || data["text"] || "",
      embedding: data["embedding"],
      metadata: data["metadata"],
      token_count: data["token_count"],
      start_position: data["start_position"],
      confidence: data["confidence"]
    }
  end

  @doc """
  Converts a Chunk struct to a map.

  Useful for serialization and passing to external systems.

  ## Parameters

    * `chunk` - A `Chunk` struct

  ## Returns

  A map with string keys representing all fields. Uses "content" key to align
  with all other language packages.

  ## Examples

      iex> chunk = %Kreuzberg.Chunk{content: "content", embedding: [0.1, 0.2]}
      iex> Kreuzberg.Chunk.to_map(chunk)
      %{
        "content" => "content",
        "embedding" => [0.1, 0.2],
        ...
      }
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = chunk) do
    %{
      "content" => chunk.content,
      "embedding" => chunk.embedding,
      "metadata" => chunk.metadata,
      "token_count" => chunk.token_count,
      "start_position" => chunk.start_position,
      "confidence" => chunk.confidence
    }
  end
end
