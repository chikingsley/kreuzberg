//! # docx-lite
//!
//! A lightweight, fast DOCX text extraction library with minimal dependencies.
//!
//! This is a vendored fork of [docx-lite](https://github.com/v-lawyer/docx-lite)
//! with bug fixes applied.

pub mod error;
pub mod extractor;
pub mod parser;
pub mod types;

pub use error::{DocxError, Result};
pub use extractor::{
    extract_text, extract_text_from_bytes, extract_text_from_reader, parse_document, parse_document_from_path,
};
pub use types::{
    Document, ExtractOptions, HeaderFooter, HeaderFooterType, ListItem, ListType, Note, NoteType, Paragraph, Run,
    Table, TableCell, TableRow,
};
