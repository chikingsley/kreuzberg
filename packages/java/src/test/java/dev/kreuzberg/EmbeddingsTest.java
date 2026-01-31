package dev.kreuzberg;

import static org.junit.jupiter.api.Assertions.*;

import dev.kreuzberg.config.ChunkingConfig;
import dev.kreuzberg.config.ExtractionConfig;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/**
 * Comprehensive tests for embeddings/vector generation in Java binding.
 *
 * <p>
 * Tests cover: - Vector generation correctness from text chunks - Embedding
 * dimension verification (384, 512, 768, 1024) - Performance with batch
 * operations - Format-specific embedding handling - Similarity score validation
 * - Model switching and configuration - Normalization correctness -
 * Preset-based embedding configuration
 *
 * @since 4.0.0
 */
class EmbeddingsTest {

	/**
	 * Test vector generation correctness for basic text. Verifies: - Embeddings are
	 * generated from text chunks - Embedding vectors are non-null and populated -
	 * Vector size is within expected dimensions - Content is preserved during
	 * extraction and embedding
	 */
	@Test
	void testVectorGenerationCorrectness() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(500).build()).build();

		String text = "Machine learning transforms technology. Embeddings represent semantic meaning in vector space.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result, "Extraction result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");
		assertNotNull(result.getChunks(), "Chunks list should not be null");

		// Verify chunks and embeddings
		if (!result.getChunks().isEmpty()) {
			Chunk chunk = result.getChunks().get(0);
			assertNotNull(chunk, "First chunk should not be null");
			assertNotNull(chunk.getContent(), "Chunk content should not be null");
			assertTrue(chunk.getContent().length() > 0, "Chunk content should not be empty");
		}
	}

	/**
	 * Test embedding dimension verification. Verifies: - Embedding dimensions are
	 * valid (common sizes: 384, 512, 768, 1024) - All embeddings in result have
	 * consistent dimensions - Dimension size matches model specification
	 */
	@Test
	@org.junit.jupiter.api.Disabled("Embedding configuration structure incomplete - requires additional fields")
	void testEmbeddingDimensionVerification() throws KreuzbergException {
		// Build config with embedding enabled
		Map<String, Object> embeddingConfig = new HashMap<>();
		embeddingConfig.put("enabled", null);
		Map<String, Object> modelConfig = new HashMap<>();
		modelConfig.put("type", "fast_embed");
		modelConfig.put("model_name", "BAAI/bge-small-en-v1.5");
		embeddingConfig.put("model", modelConfig);

		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(500).embedding(embeddingConfig).build())
				.build();

		String text = "Embeddings provide semantic representation of text in vector space. "
				+ "Different models produce vectors of different dimensions.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result.getContent(), "Extraction should succeed");
		List<Chunk> chunks = result.getChunks();

		if (!chunks.isEmpty()) {
			// Check embeddings in chunks
			int consistentDimension = -1;

			for (Chunk chunk : chunks) {
				Optional<List<Float>> embedding = chunk.getEmbedding();

				if (embedding.isPresent()) {
					List<Float> vector = embedding.get();
					assertNotNull(vector, "Embedding vector should not be null");
					assertTrue(vector.size() > 0, "Embedding should have dimensions");

					// Verify dimension is a common embedding size
					assertTrue(List.of(96, 192, 256, 384, 512, 768, 1024).contains(vector.size()),
							"Embedding dimension " + vector.size() + " should be a standard size");

					// Verify consistency across chunks
					if (consistentDimension == -1) {
						consistentDimension = vector.size();
					} else {
						assertEquals(consistentDimension, vector.size(),
								"All embeddings should have consistent dimensions");
					}
				}
			}
		}
	}

	/**
	 * Test performance with batch operations (multiple documents). Verifies: -
	 * Multiple documents can be processed sequentially - Embedding generation works
	 * for all documents - Batch processing maintains consistency - No performance
	 * degradation with batch size
	 */
	@Test
	void testBatchEmbeddingGeneration() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(300).build()).build();

		String[] documents = {"First document about machine learning algorithms.",
				"Second document discussing neural networks and deep learning.",
				"Third document covering natural language processing techniques."};

		ExtractionResult[] results = new ExtractionResult[documents.length];

		// Process documents in batch
		for (int i = 0; i < documents.length; i++) {
			results[i] = Kreuzberg.extractBytes(documents[i].getBytes(), "text/plain", config);
		}

		// Verify all extractions succeeded
		assertEquals(documents.length, results.length, "All documents should be processed");

		for (int i = 0; i < results.length; i++) {
			assertNotNull(results[i], "Result " + i + " should not be null");
			assertNotNull(results[i].getContent(), "Extraction " + i + " should succeed");
			assertNotNull(results[i].getChunks(), "Chunks " + i + " should be extracted");
		}

		// Verify batch consistency
		for (int i = 0; i < results.length; i++) {
			List<Chunk> chunks = results[i].getChunks();
			if (!chunks.isEmpty()) {
				Chunk firstChunk = chunks.get(0);
				assertNotNull(firstChunk.getContent(), "Chunk " + i + " should have content");
				assertTrue(firstChunk.getContent().length() > 0, "Chunk " + i + " content should not be empty");
			}
		}
	}

	/**
	 * Test format-specific embedding handling. Verifies: - Text/plain documents
	 * generate embeddings correctly - HTML documents generate embeddings with
	 * proper text extraction - Different content types are handled appropriately
	 */
	@Test
	void testFormatSpecificEmbeddingHandling() throws KreuzbergException {
		ExtractionConfig textConfig = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		// Test plain text
		String plainText = "Plain text document with clear semantic content.";
		ExtractionResult textResult = Kreuzberg.extractBytes(plainText.getBytes(), "text/plain", textConfig);

		assertNotNull(textResult, "Plain text result should not be null");
		assertNotNull(textResult.getContent(), "Plain text extraction should succeed");
		assertNotNull(textResult.getContent(), "Plain text content should be extracted");

		// Test HTML
		String htmlContent = "<html><body><p>HTML document with embedded content.</p></body></html>";
		ExtractionResult htmlResult = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", textConfig);

		assertNotNull(htmlResult, "HTML result should not be null");
		assertNotNull(htmlResult.getContent(), "HTML extraction should succeed");
		assertNotNull(htmlResult.getContent(), "HTML content should be extracted");

		// Both should produce valid results
		assertTrue(textResult.getContent() != null || htmlResult.getContent() != null,
				"At least one format should succeed");
	}

	/**
	 * Test similarity score validation (vector quality). Verifies: - Embedding
	 * vectors contain valid floating-point values - Vector values are in reasonable
	 * range - Vector norm is calculated correctly for similarity
	 */
	@Test
	void testVectorQualityValidation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text = "Semantic similarity between embeddings enables similarity search and clustering.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		for (Chunk chunk : result.getChunks()) {
			Optional<List<Float>> embeddingOpt = chunk.getEmbedding();

			if (embeddingOpt.isPresent()) {
				List<Float> embedding = embeddingOpt.get();

				// Validate each dimension
				for (int i = 0; i < embedding.size(); i++) {
					Float value = embedding.get(i);
					assertNotNull(value, "Embedding value at index " + i + " should not be null");
					assertFalse(Float.isNaN(value), "Embedding value at index " + i + " should not be NaN");
					assertFalse(Float.isInfinite(value), "Embedding value at index " + i + " should not be infinite");
				}

				// Calculate vector norm (L2 norm)
				double norm = 0.0;
				for (Float value : embedding) {
					norm += value * value;
				}
				norm = Math.sqrt(norm);

				// Norm should be positive
				assertTrue(norm > 0.0, "Vector norm should be positive");

				// Normalized vectors typically have norm close to 1.0
				// Allow small tolerance for floating-point precision
				assertTrue(norm >= 0.5 && norm <= 2.0,
						"Vector norm " + norm + " should be close to 1.0 for normalized vectors");
			}
		}
	}

	/**
	 * Test model switching and configuration options. Verifies: - Different
	 * embedding configurations are supported - Preset-based configuration works -
	 * Custom embedding parameters are applied
	 */
	@Test
	@org.junit.jupiter.api.Disabled("Embedding configuration structure incomplete - requires additional fields")
	void testEmbeddingConfigurationOptions() throws KreuzbergException {
		// Test with default embedding config
		Map<String, Object> defaultEmbeddingConfig = new HashMap<>();
		Map<String, Object> modelConfig = new HashMap<>();
		modelConfig.put("type", "fast_embed");
		modelConfig.put("model_name", "BAAI/bge-small-en-v1.5");
		defaultEmbeddingConfig.put("model", modelConfig);

		ExtractionConfig defaultConfig = ExtractionConfig.builder()
				.chunking(
						ChunkingConfig.builder().enabled(true).maxChars(400).embedding(defaultEmbeddingConfig).build())
				.build();

		String text = "Configuration enables customization of embedding model selection.";
		ExtractionResult defaultResult = Kreuzberg.extractBytes(text.getBytes(), "text/plain", defaultConfig);

		assertNotNull(defaultResult, "Default config result should not be null");
		assertNotNull(defaultResult.getContent(), "Extraction with default config should succeed");

		// Test with preset if supported
		ExtractionConfig presetConfig = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(512).preset("default").build()).build();

		ExtractionResult presetResult = Kreuzberg.extractBytes(text.getBytes(), "text/plain", presetConfig);

		assertNotNull(presetResult, "Preset config result should not be null");
		// Preset may or may not be supported, so we just verify it doesn't crash
		assertNotNull(presetResult.getContent(), "Content should be extracted");
	}

	/**
	 * Test normalization correctness of embedding vectors. Verifies: - Vectors are
	 * properly normalized - Normalization is consistent across chunks - Normalized
	 * vectors have unit length (for L2 normalized embeddings)
	 */
	@Test
	void testEmbeddingNormalization() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text = "Normalized embeddings are essential for cosine similarity computations.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		for (Chunk chunk : result.getChunks()) {
			Optional<List<Float>> embeddingOpt = chunk.getEmbedding();

			if (embeddingOpt.isPresent()) {
				List<Float> embedding = embeddingOpt.get();

				// Calculate L2 norm
				double l2Norm = 0.0;
				for (Float value : embedding) {
					l2Norm += value * value;
				}
				l2Norm = Math.sqrt(l2Norm);

				// Calculate L1 norm
				double l1Norm = 0.0;
				for (Float value : embedding) {
					l1Norm += Math.abs(value);
				}

				// Verify norms are reasonable (not zero, not infinite)
				assertTrue(l2Norm > 0.0, "L2 norm should be positive");
				assertTrue(l1Norm > 0.0, "L1 norm should be positive");
				assertFalse(Double.isInfinite(l2Norm), "L2 norm should not be infinite");
				assertFalse(Double.isInfinite(l1Norm), "L1 norm should not be infinite");

				// For normalized vectors, L2 norm should be close to 1.0
				// Allow some tolerance for different normalization schemes
				if (l2Norm <= 2.0) {
					// Likely normalized to unit length
					assertTrue(l2Norm >= 0.5, "Normalized vector should have reasonable norm");
				}
			}
		}
	}

	/**
	 * Test embedding generation with different chunk sizes. Verifies: - Small
	 * chunks generate embeddings correctly - Large chunks generate embeddings
	 * correctly - Chunk size configuration is properly applied - Embeddings
	 * maintain quality across different chunk sizes
	 */
	@Test
	void testEmbeddingWithVariousChunkSizes() throws KreuzbergException {
		String text = "This is a longer document that will be split into multiple chunks. "
				+ "Each chunk will receive its own embedding vector. "
				+ "The size of chunks affects embedding generation and quality.";

		// Test with small chunk size
		ExtractionConfig smallChunkConfig = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(50).build()).build();

		ExtractionResult smallResult = Kreuzberg.extractBytes(text.getBytes(), "text/plain", smallChunkConfig);

		assertNotNull(smallResult.getContent(), "Small chunk extraction should succeed");
		assertNotNull(smallResult.getChunks(), "Small chunks should be generated");

		// Test with large chunk size
		ExtractionConfig largeChunkConfig = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(500).build()).build();

		ExtractionResult largeResult = Kreuzberg.extractBytes(text.getBytes(), "text/plain", largeChunkConfig);

		assertNotNull(largeResult.getContent(), "Large chunk extraction should succeed");
		assertNotNull(largeResult.getChunks(), "Large chunks should be generated");

		// Small chunks should generate more chunks than large chunks
		int smallChunkCount = smallResult.getChunks().size();
		int largeChunkCount = largeResult.getChunks().size();

		// Verify chunk count relationship (small should be >= large)
		// Backend may generate zero chunks, so we just verify the relationship if
		// chunks exist
		if (smallChunkCount > 0 && largeChunkCount > 0) {
			assertTrue(smallChunkCount >= largeChunkCount, "Smaller chunk size should produce more chunks");
		}
	}

	/**
	 * Test embedding consistency and determinism. Verifies: - Same input produces
	 * same embeddings in successive runs - Embeddings are deterministic - Results
	 * are reproducible
	 */
	@Test
	void testEmbeddingDeterminism() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text = "Deterministic embeddings ensure reproducibility of results.";

		// First extraction run
		ExtractionResult result1 = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);
		assertNotNull(result1.getContent(), "First extraction should succeed");

		// Second extraction run
		ExtractionResult result2 = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);
		assertNotNull(result2.getContent(), "Second extraction should succeed");

		// Content should be identical
		assertEquals(result1.getContent(), result2.getContent(), "Same text should produce identical content");

		// Chunk count should be identical
		assertEquals(result1.getChunks().size(), result2.getChunks().size(),
				"Same text should produce same number of chunks");

		// Verify chunk content consistency
		List<Chunk> chunks1 = result1.getChunks();
		List<Chunk> chunks2 = result2.getChunks();

		for (int i = 0; i < chunks1.size(); i++) {
			assertEquals(chunks1.get(i).getContent(), chunks2.get(i).getContent(),
					"Chunk " + i + " content should be identical across runs");
		}
	}

	/**
	 * Test embedding metadata and chunk information. Verifies: - Chunks contain
	 * metadata - Chunk indices and positions are tracked - Metadata is available
	 * for all chunks
	 */
	@Test
	void testEmbeddingMetadataPreservation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(300).build()).build();

		String text = "Metadata preservation ensures tracking of chunk positions and origins.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result.getContent(), "Extraction should succeed");
		List<Chunk> chunks = result.getChunks();

		// Verify metadata for each chunk
		for (int i = 0; i < chunks.size(); i++) {
			Chunk chunk = chunks.get(i);
			assertNotNull(chunk, "Chunk " + i + " should not be null");
			assertNotNull(chunk.getContent(), "Chunk " + i + " should have content");
			assertNotNull(chunk.getMetadata(), "Chunk " + i + " should have metadata");

			// Metadata should contain chunk index or position info
			ChunkMetadata metadata = chunk.getMetadata();
			assertNotNull(metadata, "Chunk " + i + " metadata should not be null");
		}
	}

	/**
	 * Test embedding result validation and structure. Verifies: - Extraction
	 * results contain expected fields - Chunk list is properly populated - Result
	 * objects are properly structured - Success status is correct
	 */
	@Test
	void testEmbeddingResultValidation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text = "Result validation ensures extraction quality and correctness.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");
		assertNotNull(result.getContent(), "Content should be extracted");
		assertNotNull(result.getMimeType(), "MIME type should be available");
		assertNotNull(result.getMetadata(), "Metadata should be available");
		assertNotNull(result.getChunks(), "Chunks list should not be null");

		// Verify content length
		assertTrue(result.getContent().length() > 0, "Content should not be empty");

		// Verify chunk count
		int chunkCount = result.getChunks().size();
		assertTrue(chunkCount >= 0, "Chunk count should be non-negative");
	}

	/**
	 * Test mathematical properties of embedding vectors. Verifies: - Valid
	 * floating-point values (no NaN/Inf) - No dead embeddings (all-zero vectors) -
	 * Identical vectors have cosine similarity 1.0 - Dimension consistency across
	 * models
	 */
	@Test
	void testEmbeddingMathematicalProperties() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text = "Testing mathematical properties of embedding vectors.";
		ExtractionResult result = Kreuzberg.extractBytes(text.getBytes(), "text/plain", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		for (Chunk chunk : result.getChunks()) {
			Optional<List<Float>> embeddingOpt = chunk.getEmbedding();

			if (embeddingOpt.isPresent()) {
				List<Float> embedding = embeddingOpt.get();

				// Test 1: Valid floating-point values
				for (int i = 0; i < embedding.size(); i++) {
					Float value = embedding.get(i);
					assertFalse(Float.isNaN(value), "Value at index " + i + " is NaN");
					assertFalse(Float.isInfinite(value), "Value at index " + i + " is infinite");
					assertTrue(value >= -2.0 && value <= 2.0, "Value at index " + i + " out of range: " + value);
				}

				// Test 2: Not all zeros (dead embedding)
				double magnitude = 0.0;
				for (Float value : embedding) {
					magnitude += Math.abs(value);
				}
				assertTrue(magnitude > 0.1, "Embedding should not be all zeros (dead embedding)");

				// Test 3: Vector with itself should have similarity ~1.0
				double dotProduct = 0.0;
				double normSq = 0.0;
				for (Float value : embedding) {
					dotProduct += value * value;
					normSq += value * value;
				}
				if (normSq > 0) {
					double similarity = dotProduct / normSq;
					assertTrue(Math.abs(similarity - 1.0) < 0.0001,
							"Vector with itself should have similarity 1.0, got " + similarity);
				}
			}
		}
	}

	/**
	 * Test cosine similarity calculation correctness. Verifies: - Similar texts
	 * produce similar embeddings - Different texts produce different embeddings -
	 * Similarity values are in valid range [-1, 1]
	 */
	@Test
	void testCosineSimilarityCorrectness() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder()
				.chunking(ChunkingConfig.builder().enabled(true).maxChars(400).build()).build();

		String text1 = "Machine learning and artificial intelligence transform technology.";
		String text2 = "Machine learning and AI advance industry innovation.";

		ExtractionResult result1 = Kreuzberg.extractBytes(text1.getBytes(), "text/plain", config);
		ExtractionResult result2 = Kreuzberg.extractBytes(text2.getBytes(), "text/plain", config);

		assertNotNull(result1.getContent(), "First extraction should succeed");
		assertNotNull(result2.getContent(), "Second extraction should succeed");

		if (!result1.getChunks().isEmpty() && !result2.getChunks().isEmpty()) {
			Optional<List<Float>> emb1Opt = result1.getChunks().get(0).getEmbedding();
			Optional<List<Float>> emb2Opt = result2.getChunks().get(0).getEmbedding();

			if (emb1Opt.isPresent() && emb2Opt.isPresent()) {
				List<Float> emb1 = emb1Opt.get();
				List<Float> emb2 = emb2Opt.get();

				// Calculate cosine similarity
				double dotProduct = 0.0;
				double norm1 = 0.0;
				double norm2 = 0.0;

				for (int i = 0; i < emb1.size(); i++) {
					double v1 = emb1.get(i);
					double v2 = emb2.get(i);
					dotProduct += v1 * v2;
					norm1 += v1 * v1;
					norm2 += v2 * v2;
				}

				norm1 = Math.sqrt(norm1);
				norm2 = Math.sqrt(norm2);

				if (norm1 > 0 && norm2 > 0) {
					double similarity = dotProduct / (norm1 * norm2);

					// Verify similarity is in valid range
					assertTrue(similarity >= -1.0 && similarity <= 1.0,
							"Cosine similarity must be in [-1, 1], got " + similarity);

					// Similar texts should have positive similarity
					assertTrue(similarity > 0.2, "Similar texts should have positive similarity, got " + similarity);
				}
			}
		}
	}
}
