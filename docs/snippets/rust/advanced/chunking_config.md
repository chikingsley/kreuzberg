```rust title="Rust"
use kreuzberg::{ExtractionConfig, ChunkingConfig};

let config = ExtractionConfig {
    chunking: Some(ChunkingConfig {
        max_characters: 1000,
        overlap: 200,
        embedding: None,
    }),
    ..Default::default()
};
```
