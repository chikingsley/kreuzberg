//! ZIP archive extraction.
//!
//! Provides functions for extracting metadata and text content from ZIP archives.

use super::{ArchiveEntry, ArchiveMetadata, TEXT_EXTENSIONS};
use crate::error::{KreuzbergError, Result};
use std::collections::HashMap;
use std::io::{Cursor, Read};
use zip::ZipArchive;

/// Extract metadata from a ZIP archive.
///
/// # Arguments
///
/// * `bytes` - The ZIP archive bytes
///
/// # Returns
///
/// Returns `ArchiveMetadata` containing:
/// - Format: "ZIP"
/// - File list with paths, sizes, and directory flags
/// - Total file count
/// - Total uncompressed size
///
/// # Errors
///
/// Returns an error if the ZIP archive cannot be read or parsed.
pub fn extract_zip_metadata(bytes: &[u8]) -> Result<ArchiveMetadata> {
    let cursor = Cursor::new(bytes);
    let mut archive =
        ZipArchive::new(cursor).map_err(|e| KreuzbergError::parsing(format!("Failed to read ZIP archive: {}", e)))?;

    let mut file_list = Vec::with_capacity(archive.len());
    let mut total_size = 0u64;

    for i in 0..archive.len() {
        let file = archive
            .by_index(i)
            .map_err(|e| KreuzbergError::parsing(format!("Failed to read ZIP entry: {}", e)))?;

        let path = file.name().to_string();
        let size = file.size();
        let is_dir = file.is_dir();

        if !is_dir {
            total_size += size;
        }

        file_list.push(ArchiveEntry { path, size, is_dir });
    }

    Ok(ArchiveMetadata {
        format: "ZIP".to_string(),
        file_list,
        file_count: archive.len(),
        total_size,
    })
}

/// Extract text content from files within a ZIP archive.
///
/// Only extracts files with common text extensions: .txt, .md, .json, .xml, .html, .csv, .log, .yaml, .toml
///
/// # Arguments
///
/// * `bytes` - The ZIP archive bytes
///
/// # Returns
///
/// Returns a `HashMap` mapping file paths to their text content.
/// Binary files and files with non-text extensions are excluded.
///
/// # Errors
///
/// Returns an error if the ZIP archive cannot be read or parsed.
pub fn extract_zip_text_content(bytes: &[u8]) -> Result<HashMap<String, String>> {
    let cursor = Cursor::new(bytes);
    let mut archive =
        ZipArchive::new(cursor).map_err(|e| KreuzbergError::parsing(format!("Failed to read ZIP archive: {}", e)))?;

    let estimated_text_files = archive.len().saturating_mul(3).saturating_div(10).max(2);
    let mut contents = HashMap::with_capacity(estimated_text_files);

    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| KreuzbergError::parsing(format!("Failed to read ZIP entry: {}", e)))?;

        let path = file.name().to_string();

        if !file.is_dir() && TEXT_EXTENSIONS.iter().any(|ext| path.to_lowercase().ends_with(ext)) {
            let estimated_size = (file.size() as usize).min(10 * 1024 * 1024);
            let mut content = String::with_capacity(estimated_size);
            if file.read_to_string(&mut content).is_ok() {
                contents.insert(path, content);
            }
        }
    }

    Ok(contents)
}
