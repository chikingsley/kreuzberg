```ruby title="Ruby"
require 'kreuzberg'

config = Kreuzberg::Config::Extraction.new(
  chunking: Kreuzberg::Config::Chunking.new(
    max_characters: 1000,
    embedding: Kreuzberg::Config::Embedding.new(
      model: Kreuzberg::EmbeddingModelType.new(
        type: 'preset',
        name: 'all-mpnet-base-v2'
      ),
      batch_size: 16,
      normalize: true,
      show_download_progress: true
    )
  )
)
```
