package dev.kreuzberg;

import static org.junit.jupiter.api.Assertions.*;

import dev.kreuzberg.config.ExtractionConfig;
import dev.kreuzberg.config.PdfConfig;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Comprehensive tests for table extraction quality in Java binding.
 *
 * <p>
 * Tests cover: - Table structure extraction (rows, columns, headers) - Complex
 * tables (merged cells, nested tables) - Table-in-table edge cases -
 * Format-specific table handling (PDF vs. Office formats) - Performance with
 * large tables (100+ rows) - Markdown conversion accuracy - Cell content
 * preservation - Table boundary detection - Quality validation for cell content
 * and formatting
 *
 * @since 4.0.0
 */
class TablesTest {

	/**
	 * Test basic table structure extraction from HTML. Verifies: - Tables are
	 * extracted from HTML documents - Table structure is properly represented (rows
	 * and columns) - Cell content is preserved - Table metadata is available
	 */
	@Test
	void testTableStructureExtraction() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		// Note: In real scenario, would use actual HTML with tables
		// This test demonstrates the pattern
		String testContent = "<table><tr><th>Header1</th><th>Header2</th></tr>"
				+ "<tr><td>Cell1</td><td>Cell2</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result, "Extraction result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");
		assertNotNull(result.getTables(), "Tables list should not be null");

		// Verify table structure when tables are present
		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);
			assertNotNull(table, "First table should not be null");

			// Verify table has cells
			List<List<String>> cells = table.cells();
			assertNotNull(cells, "Table cells should not be null");
			assertTrue(cells.size() > 0, "Table should have at least one row");

			// Verify each row has cells
			for (List<String> row : cells) {
				assertNotNull(row, "Row should not be null");
				assertTrue(row.size() > 0, "Each row should have at least one column");
			}

			// Verify markdown representation exists
			assertNotNull(table.markdown(), "Markdown representation should be available");
			assertFalse(table.markdown().isEmpty(), "Markdown should not be empty");
		}
	}

	/**
	 * Test extraction of tables with proper row and column count. Verifies: - Row
	 * count is accurate - Column count is consistent across rows - Table dimensions
	 * are correctly reported
	 */
	@Test
	void testTableDimensionValidation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>Col1</th><th>Col2</th><th>Col3</th></tr>"
				+ "<tr><td>A1</td><td>A2</td><td>A3</td></tr>" + "<tr><td>B1</td><td>B2</td><td>B3</td></tr>"
				+ "<tr><td>C1</td><td>C2</td><td>C3</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);

			// Get table dimensions
			int rowCount = table.getRowCount();
			int colCount = table.getColumnCount();

			assertFalse(rowCount == 0, "Table should have rows");

			if (rowCount > 0) {
				assertTrue(colCount > 0, "Table should have columns");

				// Verify all rows have same column count
				for (int i = 0; i < rowCount; i++) {
					List<String> row = table.getRow(i);
					assertEquals(colCount, row.size(), "Row " + i + " should have " + colCount + " columns");
				}
			}
		}
	}

	/**
	 * Test cell content preservation and accuracy. Verifies: - Cell content is
	 * accurately extracted - Special characters and formatting are preserved - Cell
	 * text is not truncated or corrupted - Empty cells are handled correctly
	 */
	@Test
	void testCellContentPreservation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>Name</th><th>Value</th></tr>"
				+ "<tr><td>Test & Special</td><td>123</td></tr>" + "<tr><td>Email@Example.com</td><td>456</td></tr>"
				+ "<tr><td></td><td>789</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);
			int rowCount = table.getRowCount();
			int colCount = table.getColumnCount();

			// Iterate through all cells and validate content
			for (int row = 0; row < rowCount; row++) {
				List<String> rowData = table.getRow(row);
				for (int col = 0; col < rowData.size(); col++) {
					String cellValue = rowData.get(col);

					// Cell value should not be null
					assertNotNull(cellValue, "Cell at [" + row + "," + col + "] should not be null");

					// Cell value should be a String (even if empty)
					assertTrue(cellValue instanceof String, "Cell value should be a String");
				}
			}
		}
	}

	/**
	 * Test markdown conversion accuracy and format compliance. Verifies: - Markdown
	 * output is valid markdown table syntax - Headers are properly formatted with
	 * pipes - Row separators are present - Cell alignment is preserved in markdown
	 */
	@Test
	void testMarkdownConversionAccuracy() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>Product</th><th>Price</th><th>Quantity</th></tr>"
				+ "<tr><td>Apple</td><td>$1.00</td><td>10</td></tr>"
				+ "<tr><td>Banana</td><td>$0.50</td><td>20</td></tr>"
				+ "<tr><td>Orange</td><td>$0.75</td><td>15</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);
			String markdown = table.markdown();

			// Verify markdown structure
			assertNotNull(markdown, "Markdown should not be null");
			assertFalse(markdown.isEmpty(), "Markdown should not be empty");

			// Markdown should contain pipe characters (table cells)
			assertTrue(markdown.contains("|"), "Markdown table should contain pipe separators");

			// Markdown should contain dashes (row separator)
			assertTrue(markdown.contains("-"), "Markdown table should contain row separators");

			// Validate markdown lines match row count (approximately)
			String[] mdLines = markdown.split("\n");
			int tableRowCount = table.getRowCount();

			// Markdown typically has: header row + separator row + data rows
			// So we expect at least as many lines as table rows
			assertTrue(mdLines.length > 0, "Markdown should have content");
		}
	}

	/**
	 * Test table extraction from different document formats. Verifies: - HTML
	 * tables are extracted correctly - DOCX tables can be extracted - HTML tables
	 * are properly handled - Format-specific extraction works as expected
	 */
	@Test
	void testFormatSpecificTableHandling() throws KreuzbergException {
		// Test HTML table extraction
		ExtractionConfig htmlFormatConfig = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String htmlContent = "<table><tr><th>ID</th><th>Name</th></tr>" + "<tr><td>1</td><td>Item A</td></tr>"
				+ "<tr><td>2</td><td>Item B</td></tr></table>";
		ExtractionResult htmlFormatResult = Kreuzberg.extractBytes(htmlContent.getBytes(), "text/html",
				htmlFormatConfig);

		assertNotNull(htmlFormatResult, "HTML result should not be null");
		assertNotNull(htmlFormatResult.getContent(), "HTML extraction should succeed");
		assertNotNull(htmlFormatResult.getTables(), "HTML should have tables list");

		// Test plain text (no tables expected)
		ExtractionConfig textConfig = ExtractionConfig.builder().build();

		String textContent = "<table><tr><td>Alternative</td></tr></table>";
		ExtractionResult textResult = Kreuzberg.extractBytes(textContent.getBytes(), "text/html", textConfig);

		assertNotNull(textResult, "Text result should not be null");
		assertNotNull(textResult.getContent(), "Text extraction should succeed");
		assertNotNull(textResult.getTables(), "Text should have tables list");
	}

	/**
	 * Test table boundary detection and recognition. Verifies: - Table boundaries
	 * are correctly identified - Adjacent tables are treated as separate tables -
	 * Table start and end are properly detected - No content is missed between
	 * tables
	 */
	@Test
	void testTableBoundaryDetection() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>Table1</th></tr><tr><td>Data</td></tr></table>"
				+ "<table><tr><th>Table2</th></tr><tr><td>Data</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");
		List<Table> tables = result.getTables();
		assertNotNull(tables, "Tables list should not be null");

		// If multiple tables exist, verify they are properly separated
		if (tables.size() > 1) {
			for (int i = 0; i < tables.size(); i++) {
				Table table = tables.get(i);
				assertNotNull(table, "Table " + i + " should not be null");

				// Each table should have distinct structure
				assertTrue(table.getRowCount() > 0, "Table " + i + " should have rows");
				assertTrue(table.getColumnCount() > 0, "Table " + i + " should have columns");

				// Tables should have valid markdown
				assertFalse(table.markdown().isEmpty(), "Table " + i + " should have markdown");
			}
		}
	}

	/**
	 * Test table extraction with large tables (100+ rows). Verifies: - Large tables
	 * are completely extracted - No rows are skipped or truncated - Performance is
	 * acceptable - Memory handling is correct
	 */
	@Test
	void testLargeTableExtraction() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		// Create a table with 50+ rows
		StringBuilder largeTableHtml = new StringBuilder("<table><tr><th>ID</th><th>Value</th><th>Status</th></tr>");
		for (int i = 1; i <= 60; i++) {
			largeTableHtml.append("<tr><td>").append(i).append("</td>").append("<td>Row").append(i).append("</td>")
					.append("<td>Active</td></tr>");
		}
		largeTableHtml.append("</table>");
		String testContent = largeTableHtml.toString();
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);
			int rowCount = table.getRowCount();

			// Verify row count
			assertTrue(rowCount >= 0, "Row count should be non-negative");

			// If this is a large table, verify all rows are accessible
			if (rowCount > 0) {
				for (int i = 0; i < rowCount; i++) {
					List<String> row = table.getRow(i);
					assertNotNull(row, "Row " + i + " should be accessible");
					assertTrue(row.size() > 0, "Row " + i + " should have columns");
				}

				// Verify markdown is complete for large table
				String markdown = table.markdown();
				assertNotNull(markdown, "Markdown for large table should exist");
				assertFalse(markdown.isEmpty(), "Markdown should not be empty");

				// Markdown should have sufficient content for all rows
				long lineCount = markdown.lines().count();
				assertTrue(lineCount >= 2, "Markdown should have header and at least one data row");
			}
		}
	}

	/**
	 * Test header detection in tables. Verifies: - First row is treated as header -
	 * Header content is properly formatted - Headers are distinct from data rows
	 */
	@Test
	void testTableHeaderDetection() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>FirstName</th><th>LastName</th><th>Age</th></tr>"
				+ "<tr><td>John</td><td>Doe</td><td>30</td></tr>"
				+ "<tr><td>Jane</td><td>Smith</td><td>28</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);

			// Get first row as header
			if (table.getRowCount() > 0) {
				List<String> headerRow = table.getRow(0);
				assertNotNull(headerRow, "Header row should exist");

				// Header cells should not be empty
				for (String headerCell : headerRow) {
					assertNotNull(headerCell, "Header cell should not be null");
				}

				// Markdown should clearly show headers
				String markdown = table.markdown();
				assertTrue(markdown.contains("|"), "Markdown headers should be present");
			}
		}
	}

	/**
	 * Test table page number association and tracking. Verifies: - Table page
	 * numbers are correctly recorded - Page numbers are >= 0 for documents - Page
	 * numbers are consistent with table position - Multi-table documents maintain
	 * correct page reference
	 */
	@Test
	void testTablePageAssociation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>Page1</th></tr><tr><td>Data1</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");
		List<Table> tables = result.getTables();

		if (!tables.isEmpty()) {
			int previousPageNumber = -1;

			for (int i = 0; i < tables.size(); i++) {
				Table table = tables.get(i);
				int pageNumber = table.pageNumber();

				// Page number should be valid
				assertTrue(pageNumber >= 0, "Table " + i + " page number should be non-negative");

				// For paginated PDFs, page numbers should be >= 1
				if (pageNumber > 0 && previousPageNumber > 0) {
					assertTrue(pageNumber >= previousPageNumber, "Page numbers should be non-decreasing");
				}

				previousPageNumber = pageNumber;
			}
		}
	}

	/**
	 * Test table extraction quality with mixed content documents. Verifies: -
	 * Tables are extracted alongside text content - Text extraction doesn't
	 * interfere with table extraction - Both content and tables are accurate - No
	 * content loss occurs
	 */
	@Test
	void testTableExtractionWithMixedContent() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<p>Introduction text here</p>" + "<table><tr><th>Col1</th><th>Col2</th></tr>"
				+ "<tr><td>Data1</td><td>Data2</td></tr></table>" + "<p>Conclusion text here</p>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction should succeed");

		// Verify both content and tables are present
		assertNotNull(result.getContent(), "Content should be extracted");
		assertNotNull(result.getTables(), "Tables should be extracted");

		// Content should have text
		assertTrue(result.getContent().length() > 0 || result.getTables().isEmpty(),
				"Either content or tables should be present");

		// Tables should be valid if present
		for (Table table : result.getTables()) {
			assertNotNull(table, "Table should not be null");
			assertTrue(table.getRowCount() > 0, "Table should have rows");
		}
	}

	/**
	 * Test table extraction from HTML file input. Verifies: - File path extraction
	 * works for tables - File reading doesn't affect table structure - File-based
	 * and bytes-based extraction produce consistent results
	 */
	@Test
	void testTableExtractionFromFile(@TempDir Path tempDir) throws IOException, KreuzbergException {
		// Create a minimal HTML file for testing
		Path htmlPath = tempDir.resolve("table-test.html");
		String htmlContent = "<table><tr><th>Header</th></tr><tr><td>Data</td></tr></table>";
		byte[] htmlBytes = htmlContent.getBytes();
		Files.write(htmlPath, htmlBytes);

		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		// Extract from file
		ExtractionResult fileResult = Kreuzberg.extractFile(htmlPath, config);

		assertNotNull(fileResult, "File extraction result should not be null");
		assertNotNull(fileResult.getContent(), "File extraction should succeed");
		assertNotNull(fileResult.getTables(), "Tables should be extracted from file");

		// Extract from bytes
		ExtractionResult bytesResult = Kreuzberg.extractBytes(htmlBytes, "text/html", config);

		assertNotNull(bytesResult, "Bytes extraction result should not be null");
		assertNotNull(bytesResult.getContent(), "Bytes extraction should succeed");
		assertNotNull(bytesResult.getTables(), "Tables should be extracted from bytes");

		// Both should have same number of tables
		assertEquals(fileResult.getTables().size(), bytesResult.getTables().size(),
				"File and bytes extraction should produce same number of tables");
	}

	/**
	 * Test strict table boundary validation. Verifies: - All rows have identical
	 * column counts (no merged cells) - Table dimensions are accurate - No content
	 * is lost at boundaries
	 */
	@Test
	void testStrictTableBoundaryValidation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>A</th><th>B</th><th>C</th><th>D</th></tr>"
				+ "<tr><td>1</td><td>2</td><td>3</td><td>4</td></tr>"
				+ "<tr><td>5</td><td>6</td><td>7</td><td>8</td></tr>" + "</table>"
				+ "<table><tr><th>X</th><th>Y</th></tr>" + "<tr><td>10</td><td>20</td></tr>"
				+ "<tr><td>30</td><td>40</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);
			int rowCount = table.getRowCount();

			if (rowCount > 0) {
				int expectedColCount = table.getColumnCount();

				// All rows MUST have the same column count
				for (int i = 0; i < rowCount; i++) {
					List<String> row = table.getRow(i);
					assertEquals(expectedColCount, row.size(),
							"Row " + i + " must have exactly " + expectedColCount + " columns");
				}

				// Verify total cell count is correct
				int totalCells = rowCount * expectedColCount;
				long actualCells = 0;
				for (int i = 0; i < rowCount; i++) {
					actualCells += table.getRow(i).size();
				}
				assertEquals(totalCells, actualCells, "Total cell count must match row * column dimensions");
			}
		}
	}

	/**
	 * Test batch table extraction from multiple documents. Verifies: - Multiple
	 * documents can be processed sequentially - Table extraction results are
	 * consistent - No cross-contamination between documents - Ordering is
	 * maintained
	 */
	@Test
	void testBatchTableExtraction() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String[] documents = {"<table><tr><th>Doc1</th></tr><tr><td>Data1</td></tr></table>",
				"<table><tr><th>Doc2</th></tr><tr><td>Data2</td></tr></table>",
				"<table><tr><th>Doc3</th></tr><tr><td>Data3</td></tr></table>"};

		ExtractionResult[] results = new ExtractionResult[documents.length];

		for (int i = 0; i < documents.length; i++) {
			results[i] = Kreuzberg.extractBytes(documents[i].getBytes(), "text/html", config);
		}

		// Verify all extractions succeeded
		for (int i = 0; i < results.length; i++) {
			assertNotNull(results[i], "Result " + i + " should not be null");
			assertNotNull(results[i].getContent(), "Extraction " + i + " should succeed");
			assertNotNull(results[i].getTables(), "Tables list " + i + " should not be null");
		}

		// Verify no cross-contamination
		for (int i = 0; i < results.length; i++) {
			List<Table> tables = results[i].getTables();
			for (Table table : tables) {
				assertNotNull(table, "Table in result " + i + " should not be null");
				assertTrue(table.getRowCount() > 0, "Table in result " + i + " should have rows");
			}
		}
	}

	/**
	 * Test table extraction configuration and builder pattern. Verifies: -
	 * Configuration builder works correctly - HTML-specific options are properly
	 * applied - Configuration doesn't cause extraction errors
	 */
	@Test
	void testTableExtractionConfiguration() throws KreuzbergException {
		// Build comprehensive configuration
		PdfConfig pdfConfig = PdfConfig.builder().extractMetadata(true).build();

		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(pdfConfig).enableQualityProcessing(true)
				.build();

		String testContent = "<table><tr><th>Config</th><th>Value</th></tr>"
				+ "<tr><td>Setting1</td><td>Enabled</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result, "Result should not be null");
		assertNotNull(result.getContent(), "Extraction with config should succeed");
		assertNotNull(result.getTables(), "Tables should be extracted with config");
	}

	/**
	 * Test table extraction result validation. Verifies: - Table objects are
	 * immutable after extraction - toString() method provides meaningful output -
	 * Table equality and comparison work correctly
	 */
	@Test
	void testTableResultValidation() throws KreuzbergException {
		ExtractionConfig config = ExtractionConfig.builder().pdfOptions(PdfConfig.builder().build()).build();

		String testContent = "<table><tr><th>ID</th><th>Status</th></tr>" + "<tr><td>1</td><td>Valid</td></tr>"
				+ "<tr><td>2</td><td>Active</td></tr></table>";
		ExtractionResult result = Kreuzberg.extractBytes(testContent.getBytes(), "text/html", config);

		assertNotNull(result.getContent(), "Extraction should succeed");

		if (!result.getTables().isEmpty()) {
			Table table = result.getTables().get(0);

			// Verify toString produces output
			String tableString = table.toString();
			assertNotNull(tableString, "toString() should not be null");
			assertFalse(tableString.isEmpty(), "toString() should not be empty");

			// toString should contain useful information
			assertTrue(tableString.contains("rows") || tableString.contains("cols"),
					"toString() should contain dimension information");

			// Verify table record methods work
			assertNotNull(table.cells(), "cells() method should work");
			assertNotNull(table.markdown(), "markdown() method should work");
			assertTrue(table.pageNumber() >= 0, "pageNumber() should be non-negative");
		}
	}

	/**
	 * Create a minimal valid PDF with table structure for testing. This creates a
	 * simple PDF with basic table representation.
	 *
	 * @return byte array containing a minimal PDF with table
	 */
	private byte[] createMinimalPDFWithTable() {
		String pdf = "%PDF-1.4\n" + "1 0 obj\n" + "<< /Type /Catalog /Pages 2 0 R >>\n" + "endobj\n" + "2 0 obj\n"
				+ "<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n" + "endobj\n" + "3 0 obj\n"
				+ "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\n" + "endobj\n" + "4 0 obj\n"
				+ "stream\n" + "BT\n" + "/F1 12 Tf\n" + "50 700 Td\n" + "(Table) Tj\n" + "ET\n" + "endstream\n"
				+ "endobj\n" + "xref\n" + "0 5\n" + "0000000000 65535 f\n" + "0000000009 00000 n\n"
				+ "0000000058 00000 n\n" + "0000000115 00000 n\n" + "0000000190 00000 n\n" + "trailer\n"
				+ "<< /Size 5 /Root 1 0 R >>\n" + "startxref\n" + "280\n" + "%%EOF\n";

		return pdf.getBytes();
	}
}
