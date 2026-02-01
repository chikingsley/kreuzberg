```ruby title="Ruby"
require 'kreuzberg'

config = Kreuzberg::Config::Extraction.new(
  chunking: Kreuzberg::Config::Chunking.new(
    max_characters: 1000,
    overlap: 200
  )
)
```
