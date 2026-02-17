//! PDF document splitting utilities.
//!
//! Split PDF documents by page ranges, individual pages, or fixed-size chunks.
//! Uses `lopdf` for pure in-memory manipulation — no rendering or external processes required.
//!
//! # Example
//!
//! ```rust,no_run
//! use kreuzberg::pdf::split::{split_pdf, PageRange};
//!
//! # fn example() -> kreuzberg::pdf::error::Result<()> {
//! let pdf_bytes = std::fs::read("document.pdf")?;
//!
//! // Extract pages 1-3 and page 5 as separate PDFs
//! let ranges = vec![PageRange::new(1, 3), PageRange::single(5)];
//! let parts = split_pdf(&pdf_bytes, &ranges)?;
//!
//! for (i, part) in parts.iter().enumerate() {
//!     std::fs::write(format!("part_{}.pdf", i + 1), part)?;
//! }
//! # Ok(())
//! # }
//! ```

use super::error::{PdfError, Result};
use lopdf::Document;

/// A range of pages to extract (1-indexed, inclusive on both ends).
#[derive(Debug, Clone, Copy)]
pub struct PageRange {
    /// Start page (1-indexed).
    pub start: u32,
    /// End page (1-indexed, inclusive).
    pub end: u32,
}

impl PageRange {
    /// Create a range spanning `start` to `end` (1-indexed, inclusive).
    pub fn new(start: u32, end: u32) -> Self {
        Self { start, end }
    }

    /// Create a range for a single page (1-indexed).
    pub fn single(page: u32) -> Self {
        Self { start: page, end: page }
    }
}

/// Split a PDF into parts based on page ranges.
///
/// Each [`PageRange`] produces one output PDF containing those pages.
/// Pages are 1-indexed and ranges are inclusive on both ends.
///
/// Returns a `Vec<Vec<u8>>` where each entry is a complete PDF file.
pub fn split_pdf(pdf_bytes: &[u8], ranges: &[PageRange]) -> Result<Vec<Vec<u8>>> {
    split_pdf_with_password(pdf_bytes, ranges, None)
}

/// Split a PDF into parts based on page ranges, with optional password.
pub fn split_pdf_with_password(pdf_bytes: &[u8], ranges: &[PageRange], password: Option<&str>) -> Result<Vec<Vec<u8>>> {
    if ranges.is_empty() {
        return Ok(Vec::new());
    }

    let mut doc = load_document(pdf_bytes, password)?;
    let page_count = doc.get_pages().len() as u32;

    let mut results = Vec::with_capacity(ranges.len());
    for range in ranges {
        validate_range(range, page_count)?;

        let pages_to_keep: Vec<u32> = (range.start..=range.end).collect();
        let part = extract_pages(&mut doc, &pages_to_keep)?;
        results.push(part);
    }

    Ok(results)
}

/// Split a PDF into individual single-page PDFs.
///
/// Returns one PDF per page in the original document.
pub fn split_pdf_into_pages(pdf_bytes: &[u8]) -> Result<Vec<Vec<u8>>> {
    split_pdf_into_pages_with_password(pdf_bytes, None)
}

/// Split a PDF into individual single-page PDFs, with optional password.
pub fn split_pdf_into_pages_with_password(pdf_bytes: &[u8], password: Option<&str>) -> Result<Vec<Vec<u8>>> {
    let mut doc = load_document(pdf_bytes, password)?;
    let page_count = doc.get_pages().len() as u32;

    let mut results = Vec::with_capacity(page_count as usize);
    for page_num in 1..=page_count {
        let part = extract_pages(&mut doc, &[page_num])?;
        results.push(part);
    }

    Ok(results)
}

/// Split a PDF into chunks of `chunk_size` pages each.
///
/// The last chunk may have fewer pages if the total isn't evenly divisible.
pub fn split_pdf_into_chunks(pdf_bytes: &[u8], chunk_size: u32) -> Result<Vec<Vec<u8>>> {
    split_pdf_into_chunks_with_password(pdf_bytes, chunk_size, None)
}

/// Split a PDF into chunks of `chunk_size` pages each, with optional password.
pub fn split_pdf_into_chunks_with_password(
    pdf_bytes: &[u8],
    chunk_size: u32,
    password: Option<&str>,
) -> Result<Vec<Vec<u8>>> {
    if chunk_size == 0 {
        return Err(PdfError::InvalidPdf("Chunk size must be at least 1".to_string()));
    }

    let mut doc = load_document(pdf_bytes, password)?;
    let page_count = doc.get_pages().len() as u32;

    let mut results = Vec::new();
    let mut start = 1u32;
    while start <= page_count {
        let end = (start + chunk_size - 1).min(page_count);
        let pages_to_keep: Vec<u32> = (start..=end).collect();
        let part = extract_pages(&mut doc, &pages_to_keep)?;
        results.push(part);
        start = end + 1;
    }

    Ok(results)
}

/// Get the page count of a PDF without fully processing it.
pub fn page_count(pdf_bytes: &[u8]) -> Result<u32> {
    page_count_with_password(pdf_bytes, None)
}

/// Get the page count of a PDF, with optional password.
pub fn page_count_with_password(pdf_bytes: &[u8], password: Option<&str>) -> Result<u32> {
    let doc = load_document(pdf_bytes, password)?;
    Ok(doc.get_pages().len() as u32)
}

// ── Internal helpers ─────────────────────────────────────────────────

fn load_document(pdf_bytes: &[u8], password: Option<&str>) -> Result<Document> {
    let mut doc =
        Document::load_mem(pdf_bytes).map_err(|e| PdfError::InvalidPdf(format!("Failed to load PDF: {}", e)))?;

    if doc.is_encrypted() {
        if let Some(pwd) = password {
            doc.decrypt(pwd).map_err(|_| PdfError::InvalidPassword)?;
        } else {
            return Err(PdfError::PasswordRequired);
        }
    }

    Ok(doc)
}

fn validate_range(range: &PageRange, page_count: u32) -> Result<()> {
    if range.start == 0 {
        return Err(PdfError::PageNotFound(0));
    }
    if range.start > page_count {
        return Err(PdfError::PageNotFound(range.start as usize));
    }
    if range.end > page_count {
        return Err(PdfError::PageNotFound(range.end as usize));
    }
    if range.start > range.end {
        return Err(PdfError::InvalidPdf(format!(
            "Invalid page range: start ({}) > end ({})",
            range.start, range.end
        )));
    }
    Ok(())
}

fn extract_pages(source: &mut Document, pages_to_keep: &[u32]) -> Result<Vec<u8>> {
    // Clone the document so the source stays intact for subsequent splits.
    let mut doc = source.clone();

    // Collect all page numbers, then remove those not in our keep list.
    let all_pages: Vec<u32> = doc.get_pages().keys().copied().collect();
    let pages_to_remove: Vec<u32> = all_pages.into_iter().filter(|p| !pages_to_keep.contains(p)).collect();

    doc.delete_pages(&pages_to_remove);
    doc.prune_objects();

    let mut output = Vec::new();
    doc.save_to(&mut output)
        .map_err(|e| PdfError::IOError(format!("Failed to write split PDF: {}", e)))?;
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a minimal multi-page PDF using lopdf.
    fn make_test_pdf(num_pages: u32) -> Vec<u8> {
        use lopdf::dictionary;
        use lopdf::{Object, Stream};

        let mut doc = Document::with_version("1.4");

        let pages_id = doc.new_object_id();
        let font_id = doc.add_object(dictionary! {
            "Type" => "Font",
            "Subtype" => "Type1",
            "BaseFont" => "Helvetica",
        });

        let resources_id = doc.add_object(dictionary! {
            "Font" => dictionary! {
                "F1" => font_id,
            },
        });

        let mut page_ids = Vec::new();
        for i in 1..=num_pages {
            let content_str = format!("BT /F1 12 Tf 100 700 Td (Page {}) Tj ET", i);
            let content = Stream::new(dictionary! {}, content_str.into_bytes());
            let content_id = doc.add_object(content);

            let page_id = doc.add_object(dictionary! {
                "Type" => "Page",
                "Parent" => pages_id,
                "MediaBox" => vec![0.into(), 0.into(), 612.into(), 792.into()],
                "Contents" => content_id,
                "Resources" => resources_id,
            });
            page_ids.push(page_id);
        }

        let kids: Vec<Object> = page_ids.iter().map(|&id| id.into()).collect();
        doc.objects.insert(
            pages_id,
            Object::Dictionary(dictionary! {
                "Type" => "Pages",
                "Kids" => kids,
                "Count" => num_pages,
            }),
        );

        let catalog_id = doc.add_object(dictionary! {
            "Type" => "Catalog",
            "Pages" => pages_id,
        });
        doc.trailer.set("Root", catalog_id);

        let mut buf = Vec::new();
        doc.save_to(&mut buf).expect("failed to save test PDF");
        buf
    }

    #[test]
    fn test_page_count() {
        let pdf = make_test_pdf(5);
        assert_eq!(page_count(&pdf).unwrap(), 5);
    }

    #[test]
    fn test_split_single_range() {
        let pdf = make_test_pdf(5);
        let ranges = vec![PageRange::new(2, 4)];
        let parts = split_pdf(&pdf, &ranges).unwrap();

        assert_eq!(parts.len(), 1);
        assert_eq!(page_count(&parts[0]).unwrap(), 3);
    }

    #[test]
    fn test_split_multiple_ranges() {
        let pdf = make_test_pdf(10);
        let ranges = vec![PageRange::new(1, 3), PageRange::new(7, 10)];
        let parts = split_pdf(&pdf, &ranges).unwrap();

        assert_eq!(parts.len(), 2);
        assert_eq!(page_count(&parts[0]).unwrap(), 3);
        assert_eq!(page_count(&parts[1]).unwrap(), 4);
    }

    #[test]
    fn test_split_single_page() {
        let pdf = make_test_pdf(5);
        let ranges = vec![PageRange::single(3)];
        let parts = split_pdf(&pdf, &ranges).unwrap();

        assert_eq!(parts.len(), 1);
        assert_eq!(page_count(&parts[0]).unwrap(), 1);
    }

    #[test]
    fn test_split_into_pages() {
        let pdf = make_test_pdf(4);
        let parts = split_pdf_into_pages(&pdf).unwrap();

        assert_eq!(parts.len(), 4);
        for part in &parts {
            assert_eq!(page_count(part).unwrap(), 1);
        }
    }

    #[test]
    fn test_split_into_chunks_even() {
        let pdf = make_test_pdf(6);
        let parts = split_pdf_into_chunks(&pdf, 2).unwrap();

        assert_eq!(parts.len(), 3);
        for part in &parts {
            assert_eq!(page_count(part).unwrap(), 2);
        }
    }

    #[test]
    fn test_split_into_chunks_uneven() {
        let pdf = make_test_pdf(7);
        let parts = split_pdf_into_chunks(&pdf, 3).unwrap();

        assert_eq!(parts.len(), 3);
        assert_eq!(page_count(&parts[0]).unwrap(), 3);
        assert_eq!(page_count(&parts[1]).unwrap(), 3);
        assert_eq!(page_count(&parts[2]).unwrap(), 1);
    }

    #[test]
    fn test_split_into_chunks_size_one() {
        let pdf = make_test_pdf(3);
        let parts = split_pdf_into_chunks(&pdf, 1).unwrap();

        assert_eq!(parts.len(), 3);
        for part in &parts {
            assert_eq!(page_count(part).unwrap(), 1);
        }
    }

    #[test]
    fn test_split_into_chunks_larger_than_doc() {
        let pdf = make_test_pdf(3);
        let parts = split_pdf_into_chunks(&pdf, 100).unwrap();

        assert_eq!(parts.len(), 1);
        assert_eq!(page_count(&parts[0]).unwrap(), 3);
    }

    #[test]
    fn test_split_chunk_size_zero() {
        let pdf = make_test_pdf(3);
        let result = split_pdf_into_chunks(&pdf, 0);
        assert!(result.is_err());
    }

    #[test]
    fn test_split_empty_ranges() {
        let pdf = make_test_pdf(3);
        let parts = split_pdf(&pdf, &[]).unwrap();
        assert!(parts.is_empty());
    }

    #[test]
    fn test_split_page_out_of_range() {
        let pdf = make_test_pdf(5);
        let ranges = vec![PageRange::new(3, 8)];
        let result = split_pdf(&pdf, &ranges);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), PdfError::PageNotFound(8)));
    }

    #[test]
    fn test_split_page_zero() {
        let pdf = make_test_pdf(3);
        let ranges = vec![PageRange::new(0, 2)];
        let result = split_pdf(&pdf, &ranges);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), PdfError::PageNotFound(0)));
    }

    #[test]
    fn test_split_reversed_range() {
        let pdf = make_test_pdf(5);
        let ranges = vec![PageRange::new(4, 2)];
        let result = split_pdf(&pdf, &ranges);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), PdfError::InvalidPdf(_)));
    }

    #[test]
    fn test_split_all_pages_as_range() {
        let pdf = make_test_pdf(5);
        let ranges = vec![PageRange::new(1, 5)];
        let parts = split_pdf(&pdf, &ranges).unwrap();

        assert_eq!(parts.len(), 1);
        assert_eq!(page_count(&parts[0]).unwrap(), 5);
    }

    #[test]
    fn test_split_invalid_pdf() {
        let result = split_pdf(b"not a pdf", &[PageRange::single(1)]);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), PdfError::InvalidPdf(_)));
    }

    #[test]
    fn test_split_empty_bytes() {
        let result = split_pdf(b"", &[PageRange::single(1)]);
        assert!(result.is_err());
    }

    #[test]
    fn test_page_count_invalid_pdf() {
        let result = page_count(b"not a pdf");
        assert!(result.is_err());
    }

    #[test]
    fn test_split_single_page_doc() {
        let pdf = make_test_pdf(1);
        let parts = split_pdf_into_pages(&pdf).unwrap();
        assert_eq!(parts.len(), 1);
        assert_eq!(page_count(&parts[0]).unwrap(), 1);
    }

    #[test]
    fn test_output_is_valid_pdf() {
        let pdf = make_test_pdf(5);
        let parts = split_pdf(&pdf, &[PageRange::new(2, 3)]).unwrap();

        // Verify the output can be loaded back as a valid PDF
        let reloaded = Document::load_mem(&parts[0]);
        assert!(reloaded.is_ok());
    }
}
