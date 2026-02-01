```ruby title="Ruby"
require 'kreuzberg'

config = Kreuzberg::Config::Extraction.new(
  chunking: Kreuzberg::Config::Chunking.new(
    max_characters: 1500,
    overlap: 200,
    embedding: Kreuzberg::Config::Embedding.new(
      model: Kreuzberg::EmbeddingModelType.new(
        type: 'preset',
        name: 'text-embedding-all-minilm-l6-v2'
      )
    )
  )
)
```
