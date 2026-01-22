```java title="Java"
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

public class ChunkTextExample {
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        ObjectMapper mapper = new ObjectMapper();

        // Basic chunking request
        String requestBody = """
            {
                "text": "Your long text content here...",
                "chunker_type": "text",
                "config": {
                    "max_characters": 1000,
                    "overlap": 50,
                    "trim": true
                }
            }
            """;

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:8000/chunk"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        HttpResponse<String> response = client.send(
            request, HttpResponse.BodyHandlers.ofString()
        );

        JsonNode result = mapper.readTree(response.body());
        int chunkCount = result.get("chunk_count").asInt();
        System.out.printf("Created %d chunks%n", chunkCount);

        for (JsonNode chunk : result.get("chunks")) {
            int index = chunk.get("chunk_index").asInt();
            String content = chunk.get("content").asText();
            String preview = content.substring(0, Math.min(50, content.length()));
            System.out.printf("Chunk %d: %s...%n", index, preview);
        }
    }
}
```
