```go title="Go"
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

type ChunkRequest struct {
	Text        string        `json:"text"`
	ChunkerType string        `json:"chunker_type,omitempty"`
	Config      *ChunkConfig  `json:"config,omitempty"`
}

type ChunkConfig struct {
	MaxCharacters int  `json:"max_characters,omitempty"`
	Overlap       int  `json:"overlap,omitempty"`
	Trim          bool `json:"trim,omitempty"`
}

type ChunkResponse struct {
	Chunks         []ChunkItem `json:"chunks"`
	ChunkCount     int         `json:"chunk_count"`
	InputSizeBytes int         `json:"input_size_bytes"`
	ChunkerType    string      `json:"chunker_type"`
}

type ChunkItem struct {
	Content    string `json:"content"`
	ByteStart  int    `json:"byte_start"`
	ByteEnd    int    `json:"byte_end"`
	ChunkIndex int    `json:"chunk_index"`
	TotalChunks int   `json:"total_chunks"`
}

func main() {
	req := ChunkRequest{
		Text:        "Your long text content here...",
		ChunkerType: "text",
		Config: &ChunkConfig{
			MaxCharacters: 1000,
			Overlap:       50,
			Trim:          true,
		},
	}

	body, err := json.Marshal(req)
	if err != nil {
		log.Fatalf("marshal request: %v", err)
	}

	resp, err := http.Post(
		"http://localhost:8000/chunk",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		log.Fatalf("http post: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("read response: %v", err)
	}

	var result ChunkResponse
	if err := json.Unmarshal(respBody, &result); err != nil {
		log.Fatalf("unmarshal response: %v", err)
	}

	fmt.Printf("Created %d chunks\n", result.ChunkCount)
	for _, chunk := range result.Chunks {
		fmt.Printf("Chunk %d: %s...\n", chunk.ChunkIndex, chunk.Content[:min(50, len(chunk.Content))])
	}
}
```
