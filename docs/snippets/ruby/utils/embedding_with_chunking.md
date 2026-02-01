```ruby title="Ruby"
require 'kreuzberg'

config = Kreuzberg::Config::Extraction.new(
  chunking: Kreuzberg::Config::Chunking.new(
    max_characters: 1024,
    overlap: 100,
    embedding: Kreuzberg::Config::Embedding.new(
      model: Kreuzberg::EmbeddingModelType.new(
        type: 'preset',
        name: 'balanced'
      ),
      normalize: true,
      batch_size: 32,
      show_download_progress: false
    )
  )
)
```
