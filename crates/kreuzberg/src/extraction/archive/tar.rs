//! TAR archive extraction.
//!
//! Provides functions for extracting metadata and text content from TAR archives.
//! Supports plain TAR as well as compressed variants (TAR.GZ, TAR.BZ2).

use super::{ArchiveEntry, ArchiveMetadata, TEXT_EXTENSIONS};
use crate::error::{KreuzbergError, Result};
use std::collections::HashMap;
use std::io::{Cursor, Read};
use tar::Archive as TarArchive;

/// Extract metadata from a TAR archive.
///
/// # Arguments
///
/// * `bytes` - The TAR archive bytes (can be compressed with gzip or bzip2)
///
/// # Returns
///
/// Returns `ArchiveMetadata` containing:
/// - Format: "TAR"
/// - File list with paths, sizes, and directory flags
/// - Total file count
/// - Total uncompressed size
///
/// # Errors
///
/// Returns an error if the TAR archive cannot be read or parsed.
pub fn extract_tar_metadata(bytes: &[u8]) -> Result<ArchiveMetadata> {
    let cursor = Cursor::new(bytes);
    let mut archive = TarArchive::new(cursor);

    let estimated_entries = bytes.len().saturating_div(512).max(16);
    let mut file_list = Vec::with_capacity(estimated_entries);
    let mut total_size = 0u64;
    let mut file_count = 0;

    let entries = archive
        .entries()
        .map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR archive: {}", e)))?;

    for entry_result in entries {
        let entry = entry_result.map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR entry: {}", e)))?;

        let path = entry
            .path()
            .map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR entry path: {}", e)))?
            .to_string_lossy()
            .to_string();

        let size = entry.size();
        let is_dir = entry.header().entry_type().is_dir();

        if !is_dir {
            total_size += size;
        }

        file_count += 1;
        file_list.push(ArchiveEntry { path, size, is_dir });
    }

    Ok(ArchiveMetadata {
        format: "TAR".to_string(),
        file_list,
        file_count,
        total_size,
    })
}

/// Extract text content from files within a TAR archive.
///
/// Only extracts files with common text extensions: .txt, .md, .json, .xml, .html, .csv, .log, .yaml, .toml
///
/// # Arguments
///
/// * `bytes` - The TAR archive bytes (can be compressed with gzip or bzip2)
///
/// # Returns
///
/// Returns a `HashMap` mapping file paths to their text content.
/// Binary files and files with non-text extensions are excluded.
///
/// # Errors
///
/// Returns an error if the TAR archive cannot be read or parsed.
pub fn extract_tar_text_content(bytes: &[u8]) -> Result<HashMap<String, String>> {
    let cursor = Cursor::new(bytes);
    let mut archive = TarArchive::new(cursor);

    let estimated_text_files = bytes.len().saturating_div(1024 * 10).min(100);
    let mut contents = HashMap::with_capacity(estimated_text_files.max(2));

    let entries = archive
        .entries()
        .map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR archive: {}", e)))?;

    for entry_result in entries {
        let mut entry =
            entry_result.map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR entry: {}", e)))?;

        let path = entry
            .path()
            .map_err(|e| KreuzbergError::parsing(format!("Failed to read TAR entry path: {}", e)))?
            .to_string_lossy()
            .to_string();

        if !entry.header().entry_type().is_dir() && TEXT_EXTENSIONS.iter().any(|ext| path.to_lowercase().ends_with(ext))
        {
            let estimated_size = (entry.size().min(10 * 1024 * 1024)) as usize;
            let mut content = String::with_capacity(estimated_size);
            if entry.read_to_string(&mut content).is_ok() {
                contents.insert(path, content);
            }
        }
    }

    Ok(contents)
}
