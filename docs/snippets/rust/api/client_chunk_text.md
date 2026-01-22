```rust title="Rust"
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
struct ChunkRequest {
    text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    chunker_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    config: Option<ChunkConfig>,
}

#[derive(Serialize)]
struct ChunkConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    max_characters: Option<usize>,
    #[serde(skip_serializing_if = "Option::is_none")]
    overlap: Option<usize>,
    #[serde(skip_serializing_if = "Option::is_none")]
    trim: Option<bool>,
}

#[derive(Deserialize, Debug)]
struct ChunkResponse {
    chunks: Vec<ChunkItem>,
    chunk_count: usize,
    input_size_bytes: usize,
    chunker_type: String,
}

#[derive(Deserialize, Debug)]
struct ChunkItem {
    content: String,
    byte_start: usize,
    byte_end: usize,
    chunk_index: usize,
    total_chunks: usize,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();

    let request = ChunkRequest {
        text: "Your long text content here...".to_string(),
        chunker_type: Some("text".to_string()),
        config: Some(ChunkConfig {
            max_characters: Some(1000),
            overlap: Some(50),
            trim: Some(true),
        }),
    };

    let response = client
        .post("http://localhost:8000/chunk")
        .json(&request)
        .send()
        .await?;

    let result: ChunkResponse = response.json().await?;

    println!("Created {} chunks", result.chunk_count);
    for chunk in &result.chunks {
        let preview = &chunk.content[..chunk.content.len().min(50)];
        println!("Chunk {}: {}...", chunk.chunk_index, preview);
    }

    Ok(())
}
```
