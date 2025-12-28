//! PDF text hierarchy extraction using pdfium character positions.
//!
//! This module provides functions for extracting character information from PDFs,
//! preserving font size and position data for text hierarchy analysis.
//!
//! Note: Requires the "pdf" feature to be enabled.

use super::error::{PdfError, Result};
use pdfium_render::prelude::*;

/// A bounding box for text or elements.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct BoundingBox {
    /// Left x-coordinate
    pub left: f32,
    /// Top y-coordinate
    pub top: f32,
    /// Right x-coordinate
    pub right: f32,
    /// Bottom y-coordinate
    pub bottom: f32,
}

impl BoundingBox {
    /// Calculate the Intersection over Union (IOU) between this bounding box and another.
    ///
    /// IOU = intersection_area / union_area
    ///
    /// # Arguments
    ///
    /// * `other` - The other bounding box to compare with
    ///
    /// # Returns
    ///
    /// The IOU value between 0.0 and 1.0
    pub fn iou(&self, other: &BoundingBox) -> f32 {
        let intersection_area = self.calculate_intersection_area(other);
        let self_area = self.calculate_area();
        let other_area = other.calculate_area();
        let union_area = self_area + other_area - intersection_area;

        if union_area <= 0.0 {
            0.0
        } else {
            intersection_area / union_area
        }
    }

    /// Calculate the weighted distance between the centers of two bounding boxes.
    ///
    /// The distance is weighted with X-axis having weight 5.0 and Y-axis having weight 1.0.
    /// This reflects the greater importance of horizontal distance in text layout.
    ///
    /// # Arguments
    ///
    /// * `other` - The other bounding box to compare with
    ///
    /// # Returns
    ///
    /// The weighted distance value
    pub fn weighted_distance(&self, other: &BoundingBox) -> f32 {
        let self_center_x = (self.left + self.right) / 2.0;
        let self_center_y = (self.top + self.bottom) / 2.0;
        let other_center_x = (other.left + other.right) / 2.0;
        let other_center_y = (other.top + other.bottom) / 2.0;

        let dx = (self_center_x - other_center_x).abs();
        let dy = (self_center_y - other_center_y).abs();

        // X weight is 5.0, Y weight is 1.0
        dx * 5.0 + dy * 1.0
    }

    /// Calculate the intersection ratio relative to this bounding box's area.
    ///
    /// intersection_ratio = intersection_area / self_area
    ///
    /// # Arguments
    ///
    /// * `other` - The other bounding box to compare with
    ///
    /// # Returns
    ///
    /// The intersection ratio between 0.0 and 1.0
    pub fn intersection_ratio(&self, other: &BoundingBox) -> f32 {
        let intersection_area = self.calculate_intersection_area(other);
        let self_area = self.calculate_area();

        if self_area <= 0.0 {
            0.0
        } else {
            intersection_area / self_area
        }
    }

    /// Calculate the area of this bounding box.
    fn calculate_area(&self) -> f32 {
        let width = (self.right - self.left).max(0.0);
        let height = (self.bottom - self.top).max(0.0);
        width * height
    }

    /// Calculate the intersection area between this bounding box and another.
    fn calculate_intersection_area(&self, other: &BoundingBox) -> f32 {
        let left = self.left.max(other.left);
        let top = self.top.max(other.top);
        let right = self.right.min(other.right);
        let bottom = self.bottom.min(other.bottom);

        let width = (right - left).max(0.0);
        let height = (bottom - top).max(0.0);
        width * height
    }
}

/// Character information extracted from PDF with font metrics.
#[derive(Debug, Clone)]
pub struct CharData {
    /// The character text content
    pub text: String,
    /// X position in PDF units
    pub x: f32,
    /// Y position in PDF units
    pub y: f32,
    /// Font size in points
    pub font_size: f32,
    /// Character width in PDF units
    pub width: f32,
    /// Character height in PDF units
    pub height: f32,
}

/// A block of text with spatial and semantic information.
#[derive(Debug, Clone)]
pub struct TextBlock {
    /// The text content
    pub text: String,
    /// The bounding box of the block
    pub bbox: BoundingBox,
    /// The font size of the text in this block
    pub font_size: f32,
}

/// Extract characters with fonts from a PDF page.
///
/// Iterates through all characters on a page, extracting text, position,
/// and font size information. Characters are returned in page order.
///
/// # Arguments
///
/// * `page` - PDF page to extract characters from
///
/// # Returns
///
/// Vector of CharData objects containing text and positioning information.
///
/// # Example
///
/// ```rust,no_run
/// # #[cfg(feature = "pdf")]
/// # {
/// use kreuzberg::pdf::hierarchy::extract_chars_with_fonts;
/// use pdfium_render::prelude::*;
///
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// let pdfium = Pdfium::default();
/// let document = pdfium.load_pdf_from_file("example.pdf", None)?;
/// let page = document.pages().get(0)?;
/// let chars = extract_chars_with_fonts(&page)?;
/// # Ok(())
/// # }
/// # }
/// ```
pub fn extract_chars_with_fonts(page: &PdfPage) -> Result<Vec<CharData>> {
    let page_text = page
        .text()
        .map_err(|e| PdfError::TextExtractionFailed(format!("Failed to get page text: {}", e)))?;

    let chars = page_text.chars();

    let mut char_data_list = Vec::new();

    for pdf_char in chars.iter() {
        // Get character text
        let Some(ch) = pdf_char.unicode_char() else {
            continue;
        };

        // Get character bounds
        let bounds = pdf_char
            .loose_bounds()
            .map_err(|e| PdfError::TextExtractionFailed(format!("Failed to get char bounds: {}", e)))?;

        let width = bounds.width().value;
        let height = bounds.height().value;

        // Use character height as a proxy for font size; default to 12pt if height is invalid
        let font_size = if height > 0.0 { height } else { 12.0 };

        let char_data = CharData {
            text: ch.to_string(),
            x: bounds.left().value,
            y: bounds.bottom().value,
            font_size,
            width,
            height,
        };

        char_data_list.push(char_data);
    }

    Ok(char_data_list)
}

/// Merge characters into text blocks using a greedy clustering algorithm.
///
/// Groups characters based on spatial proximity using weighted distance and
/// intersection ratio metrics. Characters are merged greedily based on their
/// proximity and overlap.
///
/// # Arguments
///
/// * `chars` - Vector of CharData to merge into blocks
///
/// # Returns
///
/// Vector of TextBlock objects containing merged characters
///
/// # Algorithm
///
/// The function uses a greedy approach:
/// 1. Create bounding boxes for each character
/// 2. Use weighted_distance (5.0 * dx + 1.0 * dy) with maximum threshold of ~2.5x font size
/// 3. Use intersection_ratio to detect overlapping or very close characters
/// 4. Merge characters into blocks based on proximity thresholds
/// 5. Return sorted blocks by position (top to bottom, left to right)
pub fn merge_chars_into_blocks(chars: Vec<CharData>) -> Vec<TextBlock> {
    if chars.is_empty() {
        return Vec::new();
    }

    // Create bounding boxes for each character
    let mut char_boxes: Vec<(CharData, BoundingBox)> = chars
        .into_iter()
        .map(|char_data| {
            let bbox = BoundingBox {
                left: char_data.x,
                top: char_data.y - char_data.height,
                right: char_data.x + char_data.width,
                bottom: char_data.y,
            };
            (char_data, bbox)
        })
        .collect();

    // Sort by position (top to bottom, then left to right)
    char_boxes.sort_by(|a, b| {
        let y_diff = a.1.top.partial_cmp(&b.1.top).unwrap();
        if y_diff != std::cmp::Ordering::Equal {
            y_diff
        } else {
            a.1.left.partial_cmp(&b.1.left).unwrap()
        }
    });

    // Greedy merging using union-find-like approach
    let mut blocks: Vec<Vec<CharData>> = Vec::new();
    let mut used = vec![false; char_boxes.len()];

    for i in 0..char_boxes.len() {
        if used[i] {
            continue;
        }

        let mut current_block = vec![char_boxes[i].0.clone()];
        let mut block_bbox = char_boxes[i].1;
        used[i] = true;

        // Try to merge with nearby characters
        let mut changed = true;
        while changed {
            changed = false;

            for j in (i + 1)..char_boxes.len() {
                if used[j] {
                    continue;
                }

                let next_char = &char_boxes[j];
                let next_bbox = char_boxes[j].1;

                // Calculate merge thresholds based on font size
                let avg_font_size = (block_bbox.bottom - block_bbox.top).max(next_bbox.bottom - next_bbox.top);
                let intersection_threshold = 0.05; // Some overlap or proximity

                let _weighted_dist = block_bbox.weighted_distance(&next_bbox);
                let intersection_ratio = block_bbox.intersection_ratio(&next_bbox);

                // Check individual component distances
                let self_center_x = (block_bbox.left + block_bbox.right) / 2.0;
                let self_center_y = (block_bbox.top + block_bbox.bottom) / 2.0;
                let other_center_x = (next_bbox.left + next_bbox.right) / 2.0;
                let other_center_y = (next_bbox.top + next_bbox.bottom) / 2.0;
                let dx = (self_center_x - other_center_x).abs();
                let dy = (self_center_y - other_center_y).abs();

                // Separate thresholds for X and Y to handle different scenarios
                // Horizontal merging: allow up to 2-3 character widths apart (typical letter spacing)
                // Width per character ≈ 0.6 * font_size, spacing between chars ≈ 0.3 * font_size
                let x_threshold = avg_font_size * 2.0; // Allow spacing equivalent to ~3 character widths
                // Vertical merging: allow characters on same line (Y threshold is font height)
                let y_threshold = avg_font_size * 1.5; // Allow some vertical tolerance within line

                // Merge if close enough in both dimensions or overlapping
                let merge_by_distance = (dx < x_threshold) && (dy < y_threshold);
                if merge_by_distance || intersection_ratio > intersection_threshold {
                    current_block.push(next_char.0.clone());
                    // Expand bounding box
                    block_bbox.left = block_bbox.left.min(next_bbox.left);
                    block_bbox.top = block_bbox.top.min(next_bbox.top);
                    block_bbox.right = block_bbox.right.max(next_bbox.right);
                    block_bbox.bottom = block_bbox.bottom.max(next_bbox.bottom);
                    used[j] = true;
                    changed = true;
                }
            }
        }

        blocks.push(current_block);
    }

    // Convert blocks to TextBlock objects
    blocks
        .into_iter()
        .map(|block| {
            let text = block.iter().map(|c| c.text.clone()).collect::<String>();

            // Calculate bounding box for the block
            let min_x = block.iter().map(|c| c.x).fold(f32::INFINITY, f32::min);
            let min_y = block.iter().map(|c| c.y - c.height).fold(f32::INFINITY, f32::min);
            let max_x = block.iter().map(|c| c.x + c.width).fold(f32::NEG_INFINITY, f32::max);
            let max_y = block.iter().map(|c| c.y).fold(f32::NEG_INFINITY, f32::max);

            let avg_font_size = block.iter().map(|c| c.font_size).sum::<f32>() / block.len() as f32;

            TextBlock {
                text,
                bbox: BoundingBox {
                    left: min_x,
                    top: min_y,
                    right: max_x,
                    bottom: max_y,
                },
                font_size: avg_font_size,
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_char_data_creation() {
        let char_data = CharData {
            text: "A".to_string(),
            x: 100.0,
            y: 50.0,
            font_size: 12.0,
            width: 10.0,
            height: 12.0,
        };

        assert_eq!(char_data.text, "A");
        assert_eq!(char_data.x, 100.0);
        assert_eq!(char_data.y, 50.0);
        assert_eq!(char_data.font_size, 12.0);
        assert_eq!(char_data.width, 10.0);
        assert_eq!(char_data.height, 12.0);
    }

    #[test]
    fn test_char_data_clone() {
        let char_data = CharData {
            text: "B".to_string(),
            x: 200.0,
            y: 100.0,
            font_size: 14.0,
            width: 8.0,
            height: 14.0,
        };

        let cloned = char_data.clone();
        assert_eq!(cloned.text, char_data.text);
        assert_eq!(cloned.font_size, char_data.font_size);
    }
}
