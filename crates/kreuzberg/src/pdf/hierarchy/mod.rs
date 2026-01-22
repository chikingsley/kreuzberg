//! PDF text hierarchy extraction using pdfium character positions.
//!
//! This module provides functions for extracting character information from PDFs,
//! preserving font size and position data for text hierarchy analysis.
//!
//! Note: Requires the "pdf" feature to be enabled.

mod bounding_box;
mod clustering;
mod extraction;

// Re-export all public types and functions for backward compatibility
pub use bounding_box::BoundingBox;
pub use clustering::{FontSizeCluster, cluster_font_sizes};
pub use extraction::{
    CharData, HierarchyBlock, HierarchyLevel, KMeansResult, TextBlock, assign_hierarchy_levels,
    assign_hierarchy_levels_from_clusters, extract_chars_with_fonts, merge_chars_into_blocks, should_trigger_ocr,
};
