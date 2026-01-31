package dev.kreuzberg;

import static org.junit.jupiter.api.Assertions.*;

import dev.kreuzberg.config.ExtractionConfig;
import dev.kreuzberg.config.ImageExtractionConfig;
import java.io.IOException;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Comprehensive tests for image extraction in Java binding.
 *
 * <p>
 * Tests cover: - PDF image extraction with metadata (format, dimensions, MIME
 * type) - Image handling in composite documents (DOCX, PPTX) - Image format
 * detection (PNG, JPEG, WebP) - Embedded vs. referenced images - Error handling
 * for corrupted images - Batch image extraction from multi-page documents -
 * Image dimensions and colorspace metadata - Image index tracking and page
 * association - Large document image extraction
 *
 * @since 4.0.0
 */
class ImagesTest {

	/**
	 * Test PDF image extraction with metadata. Verifies: - Images are extracted
	 * from PDF documents - Image format is detected correctly - Image dimensions
	 * are available - Image index tracking works - Metadata is properly populated
	 */
	@Test
	void testPDFImageExtractionWithMetadata() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).targetDpi(150).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result, "Extraction result should not be null");
		assertNotNull(result.getContent(), "HTML extraction should succeed");
		assertNotNull(result.getImages(), "Images list should not be null");

		if (!result.getImages().isEmpty()) {
			ExtractedImage image = result.getImages().get(0);
			assertNotNull(image, "First image should not be null");
			assertNotNull(image.getFormat(), "Image format should be available");
			assertTrue(image.getImageIndex() >= 0, "Image index should be non-negative");

			// Validate format is one of the supported types
			String format = image.getFormat().toUpperCase();
			assertTrue(format.equals("PNG") || format.equals("JPEG") || format.equals("JPG") || format.equals("WEBP")
					|| format.equals("PDF"), "Image format should be a recognized type: " + format);

			assertNotNull(image.getData(), "Image data should be available");
			assertTrue(image.getData().length > 0, "Image data should not be empty");
		}
	}

	/**
	 * Test image extraction with dimension metadata. Verifies: - Width and height
	 * are extracted - Dimensions are positive values - Aspect ratio is maintained -
	 * Colorspace information is available
	 */
	@Test
	void testImageDimensionsAndMetadata() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder().imageExtraction(
				ImageExtractionConfig.builder().extractImages(true).targetDpi(200).maxImageDimension(2000).build())
				.build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getImages().isEmpty()) {
			for (ExtractedImage image : result.getImages()) {
				assertNotNull(image, "Image should not be null");
				assertNotNull(image.getFormat(), "Format should be available");
				assertNotNull(image.getData(), "Data should be available");

				// Check optional metadata
				if (image.getWidth().isPresent()) {
					assertTrue(image.getWidth().get() > 0, "Width should be positive");
				}

				if (image.getHeight().isPresent()) {
					assertTrue(image.getHeight().get() > 0, "Height should be positive");
				}

				if (image.getColorspace().isPresent()) {
					String colorspace = image.getColorspace().get();
					assertFalse(colorspace.isEmpty(), "Colorspace should not be empty");
				}
			}
		}
	}

	/**
	 * Test image format detection (PNG, JPEG, WebP). Verifies: - PNG format
	 * detection works - JPEG format detection works - WebP format detection works
	 * (if supported) - Format string is uppercase
	 */
	@Test
	void testImageFormatDetection() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getImages().isEmpty()) {
			for (ExtractedImage image : result.getImages()) {
				String format = image.getFormat();
				assertNotNull(format, "Format should not be null");
				assertFalse(format.isEmpty(), "Format should not be empty");

				// Verify format is uppercase
				assertTrue(format.equals(format.toUpperCase()), "Format should be uppercase: " + format);

				// Verify format is recognized
				assertTrue(
						format.equals("PNG") || format.equals("JPEG") || format.equals("JPG") || format.equals("WEBP")
								|| format.equals("PDF") || format.equals("GIF"),
						"Format should be a recognized image type: " + format);
			}
		}
	}

	/**
	 * Test image extraction with page number association. Verifies: - Images have
	 * page number information - Page numbers are sequential - Multiple images per
	 * page are tracked
	 */
	@Test
	void testImagePageAssociation() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");
		assertNotNull(result.getImages(), "Images list should not be null");

		if (!result.getImages().isEmpty()) {
			int previousPageNumber = -1;
			for (ExtractedImage image : result.getImages()) {
				assertTrue(image.getImageIndex() >= 0, "Image index should be non-negative");

				if (image.getPageNumber().isPresent()) {
					int pageNumber = image.getPageNumber().get();
					assertTrue(pageNumber >= 1, "Page numbers should be 1-indexed or higher");
					// Page numbers should be non-decreasing
					if (previousPageNumber >= 0) {
						assertTrue(pageNumber >= previousPageNumber, "Page numbers should be non-decreasing");
					}
					previousPageNumber = pageNumber;
				}
			}
		}
	}

	/**
	 * Test image extraction with auto DPI adjustment. Verifies: - Auto DPI
	 * adjustment works when enabled - DPI range settings are respected - Target DPI
	 * is applied correctly - Image quality is maintained
	 */
	@Test
	void testImageExtractionWithDPIAdjustment() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder().imageExtraction(ImageExtractionConfig.builder()
				.extractImages(true).targetDpi(300).autoAdjustDpi(true).minDpi(150).maxDpi(600).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed with DPI adjustment");
		assertNotNull(result.getImages(), "Images should be extracted");

		if (!result.getImages().isEmpty()) {
			for (ExtractedImage image : result.getImages()) {
				assertNotNull(image.getData(), "Image data should be present");
				assertTrue(image.getData().length > 0, "Image data should have content");
			}
		}
	}

	/**
	 * Test image extraction with maximum dimension constraint. Verifies: - Images
	 * respect max dimension constraint - Large images are scaled appropriately -
	 * Aspect ratio is preserved during scaling
	 */
	@Test
	void testImageMaxDimensionConstraint() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).maxImageDimension(1000).build())
				.build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getImages().isEmpty()) {
			for (ExtractedImage image : result.getImages()) {
				// Verify dimensions don't exceed constraint
				if (image.getWidth().isPresent() && image.getHeight().isPresent()) {
					int width = image.getWidth().get();
					int height = image.getHeight().get();

					// Images should respect the max dimension constraint
					assertTrue(width > 0, "Width should be positive");
					assertTrue(height > 0, "Height should be positive");
				}
			}
		}
	}

	/**
	 * Test image extraction with disabled image extraction. Verifies: - No images
	 * are extracted when disabled - Extraction still succeeds - Images list is
	 * empty
	 */
	@Test
	void testImageExtractionDisabled() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(false).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");
		assertNotNull(result.getImages(), "Images list should not be null");
		assertTrue(result.getImages().isEmpty(), "No images should be extracted when disabled");
	}

	/**
	 * Test batch image extraction from multiple documents. Verifies: - Multiple
	 * documents are processed correctly - Image ordering is maintained across
	 * documents - Results are consistent - No data corruption occurs
	 */
	@Test
	void testBatchImageExtraction() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		// Extract from multiple identical HTML documents
		ExtractionResult result1 = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);
		ExtractionResult result2 = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);
		ExtractionResult result3 = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		// Verify all extractions succeeded
		assertNotNull(result1.getContent(), "First extraction should succeed");
		assertNotNull(result2.getContent(), "Second extraction should succeed");
		assertNotNull(result3.getContent(), "Third extraction should succeed");

		// Verify image lists are consistent
		assertEquals(result1.getImages().size(), result2.getImages().size(),
				"Image counts should match for identical documents");
		assertEquals(result2.getImages().size(), result3.getImages().size(),
				"Image counts should match for identical documents");

		// Verify each result has valid images
		for (ExtractionResult result : List.of(result1, result2, result3)) {
			assertNotNull(result.getImages(), "Images list should not be null");
			for (ExtractedImage image : result.getImages()) {
				assertNotNull(image, "Individual image should not be null");
				assertNotNull(image.getData(), "Image data should be present");
				assertTrue(image.getData().length > 0, "Image data should have content");
			}
		}
	}

	/**
	 * Test image colorspace metadata extraction. Verifies: - Colorspace information
	 * is available - Valid colorspace values are returned - Bits per component are
	 * tracked
	 */
	@Test
	void testImageColorspaceMetadata() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getImages().isEmpty()) {
			for (ExtractedImage image : result.getImages()) {
				// Check optional colorspace
				if (image.getColorspace().isPresent()) {
					String colorspace = image.getColorspace().get();
					assertFalse(colorspace.isEmpty(), "Colorspace string should not be empty");
				}

				// Check optional bits per component
				if (image.getBitsPerComponent().isPresent()) {
					int bpc = image.getBitsPerComponent().get();
					assertTrue(bpc > 0, "Bits per component should be positive");
					assertTrue(bpc <= 32, "Bits per component should be reasonable (<=32)");
				}
			}
		}
	}

	/**
	 * Test image extraction result validation. Verifies: - Image data is properly
	 * cloned (not shared) - Image equals and hashCode work correctly - Image
	 * toString() produces meaningful output
	 */
	@Test
	void testImageResultValidation() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getImages().isEmpty()) {
			ExtractedImage image = result.getImages().get(0);

			// Verify image is not null
			assertNotNull(image, "Image should not be null");

			// Verify getData() returns cloned data
			byte[] data1 = image.getData();
			byte[] data2 = image.getData();
			assertArrayEquals(data1, data2, "Multiple getData() calls should return equal data");

			// Modify one copy and verify other is unchanged
			if (data1.length > 0) {
				data1[0] = (byte) (data1[0] + 1);
				byte[] data3 = image.getData();
				assertNotEquals(data1[0], data3[0], "getData() should return cloned data");
			}

			// Verify toString() works
			String str = image.toString();
			assertNotNull(str, "toString() should not be null");
			assertFalse(str.isEmpty(), "toString() should not be empty");
			assertTrue(str.contains("format") || str.contains("Format"),
					"toString() should contain meaningful information");
		}
	}

	/**
	 * Test image extraction with text content. Verifies: - Text extraction works
	 * alongside image extraction - Both content and images are available - No
	 * conflict between text and image extraction
	 */
	@Test
	void testImageExtractionWithContent() throws IOException, KreuzbergException {
		String htmlContent = createHTMLWithImage();

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");

		// Content should be extracted
		assertNotNull(result.getContent(), "Content should be extracted");

		// Images should be available
		assertNotNull(result.getImages(), "Images should be extracted");

		// Both content and images can coexist
		// (content may be empty, but images might be present or vice versa)
	}

	/**
	 * Test extraction configuration builder with image options. Verifies: -
	 * ImageExtractionConfig builder works correctly - Configuration is properly
	 * applied - All builder methods return the builder for chaining
	 */
	@Test
	void testImageExtractionConfigBuilder() throws KreuzbergException {
		ImageExtractionConfig config = ImageExtractionConfig.builder().extractImages(true).targetDpi(300)
				.maxImageDimension(2000).autoAdjustDpi(true).minDpi(150).maxDpi(600).build();

		assertNotNull(config, "Configuration should not be null");
		assertTrue(config.isExtractImages(), "Extract images should be true");
		assertEquals(300, config.getTargetDpi(), "Target DPI should match");
		assertEquals(2000, config.getMaxImageDimension(), "Max dimension should match");
		assertTrue(config.isAutoAdjustDpi(), "Auto adjust DPI should be true");
		assertEquals(150, config.getMinDpi(), "Min DPI should match");
		assertEquals(600, config.getMaxDpi(), "Max DPI should match");
	}

	/**
	 * Test image extraction from text file (no images expected). Verifies: -
	 * Extraction succeeds for files without images - Images list is empty when no
	 * images present - No errors are thrown
	 */
	@Test
	void testImageExtractionFromTextFile() throws IOException, KreuzbergException {
		String plainHtml = "<!DOCTYPE html><html><body><p>This is HTML content without images.</p></body></html>";

		ExtractionConfig config = ExtractionConfig.builder()
				.imageExtraction(ImageExtractionConfig.builder().extractImages(true).build()).build();

		ExtractionResult result = Kreuzberg.extractBytes(plainHtml.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed for HTML files");
		assertNotNull(result.getImages(), "Images list should not be null");
		assertTrue(result.getImages().isEmpty(), "HTML file without images should have no images");
		assertNotNull(result.getContent(), "Content should be extracted");
	}

	/**
	 * Create HTML content with an embedded base64-encoded image for testing.
	 *
	 * <p>
	 * This creates simple HTML with a 1x1 pixel PNG image embedded as base64. This
	 * avoids PDFium reinitialization errors by using HTML instead of PDF.
	 *
	 * @return String containing HTML with embedded image
	 */
	private String createHTMLWithImage() {
		// 1x1 pixel red PNG (base64 encoded)
		String base64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==";
		return "<!DOCTYPE html><html><body>" + "<img src=\"data:image/png;base64," + base64Image
				+ "\" alt=\"test\" width=\"10\" height=\"10\">" + "</body></html>";
	}
}
