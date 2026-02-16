//! PDF-specific configuration.
//!
//! Defines PDF extraction options including metadata handling, image extraction,
//! password management, and hierarchy extraction for document structure analysis.

use serde::{Deserialize, Serialize};

/// PDF-specific configuration.
#[cfg(feature = "pdf")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfConfig {
    /// Extract images from PDF
    #[serde(default)]
    pub extract_images: bool,

    /// List of passwords to try when opening encrypted PDFs
    #[serde(default)]
    pub passwords: Option<Vec<String>>,

    /// Extract PDF metadata
    #[serde(default = "default_true")]
    pub extract_metadata: bool,

    /// Hierarchy extraction configuration (None = hierarchy extraction disabled)
    #[serde(default)]
    pub hierarchy: Option<HierarchyConfig>,

    /// Table detection configuration (None = use defaults).
    #[serde(default)]
    pub table_detection: Option<PdfTableDetectionConfig>,
}

/// Table detection strategy exposed in configuration.
#[cfg(feature = "pdf")]
#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum PdfTableStrategy {
    #[default]
    Lines,
    LinesStrict,
    Text,
    Explicit,
}

/// PDF table detection configuration.
///
/// This mirrors `TableSettings` and allows strategy/tolerance tuning through
/// `ExtractionConfig` without code changes.
#[cfg(feature = "pdf")]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdfTableDetectionConfig {
    /// Enable table extraction for PDFs.
    #[serde(default = "default_true")]
    pub enabled: bool,
    /// Strategy for vertical edge detection.
    #[serde(default)]
    pub vertical_strategy: PdfTableStrategy,
    /// Strategy for horizontal edge detection.
    #[serde(default)]
    pub horizontal_strategy: PdfTableStrategy,
    /// Explicit vertical line positions (x coordinates).
    #[serde(default)]
    pub explicit_vertical_lines: Vec<f64>,
    /// Explicit horizontal line positions (y coordinates).
    #[serde(default)]
    pub explicit_horizontal_lines: Vec<f64>,
    /// Explicit boxes `(x0, top, x1, bottom)` for manual table structure hints.
    #[serde(default)]
    pub explicit_boxes: Vec<(f64, f64, f64, f64)>,
    /// Snap tolerance for aligning nearby edges.
    #[serde(default = "default_table_snap_tolerance")]
    pub snap_tolerance: f64,
    /// Snap tolerance for x-axis only. Overrides `snap_tolerance` for x.
    #[serde(default)]
    pub snap_x_tolerance: Option<f64>,
    /// Snap tolerance for y-axis only. Overrides `snap_tolerance` for y.
    #[serde(default)]
    pub snap_y_tolerance: Option<f64>,
    /// Join tolerance for merging collinear edge segments.
    #[serde(default = "default_table_join_tolerance")]
    pub join_tolerance: f64,
    /// Join tolerance for x-axis only. Overrides `join_tolerance` for x.
    #[serde(default)]
    pub join_x_tolerance: Option<f64>,
    /// Join tolerance for y-axis only. Overrides `join_tolerance` for y.
    #[serde(default)]
    pub join_y_tolerance: Option<f64>,
    /// Minimum edge length after merging.
    #[serde(default = "default_table_edge_min_length")]
    pub edge_min_length: f64,
    /// Minimum edge length before merging.
    #[serde(default = "default_table_edge_min_length_prefilter")]
    pub edge_min_length_prefilter: f64,
    /// Minimum words for vertical text-strategy edge detection.
    #[serde(default = "default_table_min_words_vertical")]
    pub min_words_vertical: usize,
    /// Minimum words for horizontal text-strategy edge detection.
    #[serde(default = "default_table_min_words_horizontal")]
    pub min_words_horizontal: usize,
    /// Tolerance for intersection detection.
    #[serde(default = "default_table_intersection_tolerance")]
    pub intersection_tolerance: f64,
    /// Intersection tolerance for x-axis only. Overrides `intersection_tolerance` for x.
    #[serde(default)]
    pub intersection_x_tolerance: Option<f64>,
    /// Intersection tolerance for y-axis only. Overrides `intersection_tolerance` for y.
    #[serde(default)]
    pub intersection_y_tolerance: Option<f64>,
    /// Optional clip region `(x0, top, x1, bottom)` restricting detection to a sub-area.
    #[serde(default)]
    pub clip: Option<(f64, f64, f64, f64)>,
    /// Base text grouping tolerance for character assembly in cells.
    #[serde(default)]
    pub text_tolerance: Option<f64>,
    /// Horizontal text tolerance. Overrides `text_tolerance` for x-axis spacing.
    #[serde(default)]
    pub text_x_tolerance: Option<f64>,
    /// Vertical text tolerance. Overrides `text_tolerance` for line break detection.
    #[serde(default)]
    pub text_y_tolerance: Option<f64>,
    /// Fallback spatial clustering column threshold.
    #[serde(default = "default_fallback_column_threshold")]
    pub fallback_column_threshold: u32,
    /// Fallback spatial clustering row threshold ratio.
    #[serde(default = "default_fallback_row_threshold_ratio")]
    pub fallback_row_threshold_ratio: f64,
}

#[cfg(feature = "pdf")]
impl Default for PdfTableDetectionConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            vertical_strategy: PdfTableStrategy::Lines,
            horizontal_strategy: PdfTableStrategy::Lines,
            explicit_vertical_lines: Vec::new(),
            explicit_horizontal_lines: Vec::new(),
            explicit_boxes: Vec::new(),
            snap_tolerance: default_table_snap_tolerance(),
            snap_x_tolerance: None,
            snap_y_tolerance: None,
            join_tolerance: default_table_join_tolerance(),
            join_x_tolerance: None,
            join_y_tolerance: None,
            edge_min_length: default_table_edge_min_length(),
            edge_min_length_prefilter: default_table_edge_min_length_prefilter(),
            min_words_vertical: default_table_min_words_vertical(),
            min_words_horizontal: default_table_min_words_horizontal(),
            intersection_tolerance: default_table_intersection_tolerance(),
            intersection_x_tolerance: None,
            intersection_y_tolerance: None,
            clip: None,
            text_tolerance: None,
            text_x_tolerance: None,
            text_y_tolerance: None,
            fallback_column_threshold: default_fallback_column_threshold(),
            fallback_row_threshold_ratio: default_fallback_row_threshold_ratio(),
        }
    }
}

#[cfg(feature = "pdf")]
impl PdfTableDetectionConfig {
    /// Convert config to runtime table-finder settings.
    pub fn to_table_settings(&self) -> crate::pdf::TableSettings {
        crate::pdf::TableSettings {
            vertical_strategy: map_table_strategy(self.vertical_strategy),
            horizontal_strategy: map_table_strategy(self.horizontal_strategy),
            explicit_vertical_lines: self.explicit_vertical_lines.clone(),
            explicit_horizontal_lines: self.explicit_horizontal_lines.clone(),
            explicit_boxes: self.explicit_boxes.clone(),
            snap_tolerance: self.snap_tolerance,
            snap_x_tolerance: self.snap_x_tolerance,
            snap_y_tolerance: self.snap_y_tolerance,
            join_tolerance: self.join_tolerance,
            join_x_tolerance: self.join_x_tolerance,
            join_y_tolerance: self.join_y_tolerance,
            edge_min_length: self.edge_min_length,
            edge_min_length_prefilter: self.edge_min_length_prefilter,
            min_words_vertical: self.min_words_vertical,
            min_words_horizontal: self.min_words_horizontal,
            intersection_tolerance: self.intersection_tolerance,
            intersection_x_tolerance: self.intersection_x_tolerance,
            intersection_y_tolerance: self.intersection_y_tolerance,
            clip: self.clip,
            text_tolerance: self.text_tolerance,
            text_x_tolerance: self.text_x_tolerance,
            text_y_tolerance: self.text_y_tolerance,
        }
    }
}

#[cfg(feature = "pdf")]
fn map_table_strategy(strategy: PdfTableStrategy) -> crate::pdf::TableStrategy {
    match strategy {
        PdfTableStrategy::Lines => crate::pdf::TableStrategy::Lines,
        PdfTableStrategy::LinesStrict => crate::pdf::TableStrategy::LinesStrict,
        PdfTableStrategy::Text => crate::pdf::TableStrategy::Text,
        PdfTableStrategy::Explicit => crate::pdf::TableStrategy::Explicit,
    }
}

/// Hierarchy extraction configuration for PDF text structure analysis.
///
/// Enables extraction of document hierarchy levels (H1-H6) based on font size
/// clustering and semantic analysis. When enabled, hierarchical blocks are
/// included in page content.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HierarchyConfig {
    /// Enable hierarchy extraction
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Number of font size clusters to use for hierarchy levels (1-7)
    ///
    /// Default: 6, which provides H1-H6 heading levels with body text.
    /// Larger values create more fine-grained hierarchy levels.
    #[serde(default = "default_k_clusters")]
    pub k_clusters: usize,

    /// Include bounding box information in hierarchy blocks
    #[serde(default = "default_true")]
    pub include_bbox: bool,

    /// OCR coverage threshold for smart OCR triggering (0.0-1.0)
    ///
    /// Determines when OCR should be triggered based on text block coverage.
    /// OCR is triggered when text blocks cover less than this fraction of the page.
    /// Default: 0.5 (trigger OCR if less than 50% of page has text)
    #[serde(default = "default_ocr_coverage_threshold")]
    pub ocr_coverage_threshold: Option<f32>,
}

impl Default for HierarchyConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            k_clusters: 6,
            include_bbox: true,
            ocr_coverage_threshold: None,
        }
    }
}

fn default_true() -> bool {
    true
}

fn default_k_clusters() -> usize {
    6
}

fn default_ocr_coverage_threshold() -> Option<f32> {
    None
}

fn default_table_snap_tolerance() -> f64 {
    3.0
}

fn default_table_join_tolerance() -> f64 {
    3.0
}

fn default_table_edge_min_length() -> f64 {
    3.0
}

fn default_table_edge_min_length_prefilter() -> f64 {
    1.0
}

fn default_table_min_words_vertical() -> usize {
    3
}

fn default_table_min_words_horizontal() -> usize {
    1
}

fn default_table_intersection_tolerance() -> f64 {
    3.0
}

fn default_fallback_column_threshold() -> u32 {
    50
}

fn default_fallback_row_threshold_ratio() -> f64 {
    0.5
}

#[cfg(test)]
mod tests {
    #[test]
    #[cfg(feature = "pdf")]
    fn test_hierarchy_config_default() {
        use super::*;
        let config = HierarchyConfig::default();
        assert!(config.enabled);
        assert_eq!(config.k_clusters, 6);
        assert!(config.include_bbox);
        assert!(config.ocr_coverage_threshold.is_none());
    }

    #[test]
    #[cfg(feature = "pdf")]
    fn test_hierarchy_config_disabled() {
        use super::*;
        let config = HierarchyConfig {
            enabled: false,
            k_clusters: 3,
            include_bbox: false,
            ocr_coverage_threshold: Some(0.7),
        };
        assert!(!config.enabled);
        assert_eq!(config.k_clusters, 3);
        assert!(!config.include_bbox);
        assert_eq!(config.ocr_coverage_threshold, Some(0.7));
    }

    #[test]
    #[cfg(feature = "pdf")]
    fn test_table_detection_config_default() {
        use super::*;
        let config = PdfTableDetectionConfig::default();
        assert!(config.enabled);
        assert_eq!(config.vertical_strategy, PdfTableStrategy::Lines);
        assert_eq!(config.horizontal_strategy, PdfTableStrategy::Lines);
        assert_eq!(config.snap_tolerance, 3.0);
        assert_eq!(config.join_tolerance, 3.0);
        assert_eq!(config.fallback_column_threshold, 50);
        assert_eq!(config.fallback_row_threshold_ratio, 0.5);
    }
}
