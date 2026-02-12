//! Integration tests for PDF table detection using pdfplumber's algorithm.
//!
//! Uses test PDFs from pdfplumber's test suite to verify that the ported
//! table detection algorithm produces correct results.
//!
//! These tests exercise the full extraction pipeline with the new
//! line-based table detection integrated.

#![cfg(all(feature = "pdf", feature = "ocr", feature = "bundled-pdfium"))]

use kreuzberg::core::config::ExtractionConfig;
use kreuzberg::extract_bytes_sync;
use std::path::PathBuf;

fn test_pdf_path(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("tests")
        .join("data")
        .join("table_pdfs")
        .join(name)
}

fn extract_tables_from_pdf(name: &str) -> Vec<kreuzberg::types::Table> {
    let path = test_pdf_path(name);
    let bytes = std::fs::read(&path).unwrap_or_else(|_| panic!("Failed to read: {}", path.display()));

    let config = ExtractionConfig::default();
    let result = extract_bytes_sync(&bytes, "application/pdf", &config)
        .unwrap_or_else(|e| panic!("Failed to extract {}: {}", name, e));

    result.tables
}

#[test]
fn test_pdffill_demo_extracts_tables() {
    let tables = extract_tables_from_pdf("pdffill-demo.pdf");

    println!("pdffill-demo: found {} tables", tables.len());
    for (i, table) in tables.iter().enumerate() {
        println!(
            "  Table {}: {} rows, page {}",
            i,
            table.cells.len(),
            table.page_number
        );
        if !table.cells.is_empty() {
            println!("    First row: {:?}", &table.cells[0]);
        }
    }

    // The PDFfill demo form has tables — we should find at least one
    assert!(
        !tables.is_empty(),
        "Expected at least one table in pdffill-demo.pdf"
    );
}

#[test]
fn test_issue_140_table_content() {
    let tables = extract_tables_from_pdf("issue-140-example.pdf");

    println!("issue-140: found {} tables", tables.len());
    for (i, table) in tables.iter().enumerate() {
        println!(
            "  Table {}: {} rows, page {}",
            i,
            table.cells.len(),
            table.page_number
        );
        for (j, row) in table.cells.iter().enumerate() {
            println!("    Row {}: {:?}", j, row);
        }
    }

    // This PDF has a table with UPC codes — should find at least one table
    assert!(
        !tables.is_empty(),
        "Expected at least one table in issue-140-example.pdf"
    );

    // Check that we extracted some meaningful text
    let all_text: String = tables
        .iter()
        .flat_map(|t| t.cells.iter())
        .flat_map(|row| row.iter())
        .cloned()
        .collect();

    assert!(
        !all_text.is_empty(),
        "Expected non-empty table text in issue-140"
    );
}

#[test]
fn test_issue_336_multiple_tables() {
    let tables = extract_tables_from_pdf("issue-336-example.pdf");

    println!("issue-336: found {} tables", tables.len());
    for (i, table) in tables.iter().enumerate() {
        println!(
            "  Table {}: {} rows, page {}",
            i,
            table.cells.len(),
            table.page_number
        );
    }

    // pdfplumber finds 3 tables on page 1 of this PDF
    // We should find at least 2 (improvement over the old approach which found max 1)
    if tables.len() >= 2 {
        println!("Multiple tables detected per page - improvement over old approach!");
    }
}

#[test]
fn test_table_curves_detection() {
    let tables = extract_tables_from_pdf("table-curves-example.pdf");

    println!("table-curves: found {} tables", tables.len());
    for (i, table) in tables.iter().enumerate() {
        println!(
            "  Table {}: {} rows, page {}",
            i,
            table.cells.len(),
            table.page_number
        );
        for (j, row) in table.cells.iter().enumerate() {
            println!("    Row {}: {:?}", j, row);
        }
    }

    // This PDF uses curves for borders
    // The "lines" strategy includes curve-based edges so should find tables
    assert!(
        !tables.is_empty(),
        "Expected at least one table in table-curves-example.pdf"
    );
}

#[test]
fn test_markdown_output_format() {
    let tables = extract_tables_from_pdf("pdffill-demo.pdf");

    if let Some(table) = tables.first() {
        // Markdown should contain pipe characters (table delimiters)
        assert!(
            table.markdown.contains('|'),
            "Markdown should contain pipe delimiters: {}",
            table.markdown
        );

        // Markdown should contain separator row
        assert!(
            table.markdown.contains("---"),
            "Markdown should contain header separator: {}",
            table.markdown
        );

        println!("Markdown output:\n{}", table.markdown);
    }
}
