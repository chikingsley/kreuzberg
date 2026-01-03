//! PDF text hierarchy extraction using pdfium character positions.
//!
//! This module provides functions for extracting character information from PDFs,
//! preserving font size and position data for text hierarchy analysis.
//!
//! Note: Requires the "pdf" feature to be enabled.

use super::error::{PdfError, Result};
use crate::core::config::ExtractionConfig;
use pdfium_render::prelude::*;

// Magic number constants
const DEFAULT_FONT_SIZE: f32 = 12.0;
const WEIGHTED_DISTANCE_X_WEIGHT: f32 = 5.0;
const WEIGHTED_DISTANCE_Y_WEIGHT: f32 = 1.0;
const KMEANS_MAX_ITERATIONS: usize = 100;
const KMEANS_CONVERGENCE_THRESHOLD: f32 = 0.01;
const MERGE_INTERSECTION_THRESHOLD: f32 = 0.05;
const MERGE_X_THRESHOLD_MULTIPLIER: f32 = 2.0;
const MERGE_Y_THRESHOLD_MULTIPLIER: f32 = 1.5;

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
        let (self_center_x, self_center_y) = self.center();
        let (other_center_x, other_center_y) = other.center();

        let dx = (self_center_x - other_center_x).abs();
        let dy = (self_center_y - other_center_y).abs();

        dx * WEIGHTED_DISTANCE_X_WEIGHT + dy * WEIGHTED_DISTANCE_Y_WEIGHT
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

    /// Check if this bounding box contains another bounding box.
    pub fn contains(&self, other: &BoundingBox) -> bool {
        other.left >= self.left && other.right <= self.right && other.top >= self.top && other.bottom <= self.bottom
    }

    /// Calculate the center coordinates of this bounding box.
    pub fn center(&self) -> (f32, f32) {
        ((self.left + self.right) / 2.0, (self.top + self.bottom) / 2.0)
    }

    /// Merge this bounding box with another, creating a box that contains both.
    pub fn merge(&self, other: &BoundingBox) -> BoundingBox {
        BoundingBox {
            left: self.left.min(other.left),
            top: self.top.min(other.top),
            right: self.right.max(other.right),
            bottom: self.bottom.max(other.bottom),
        }
    }

    /// Calculate a relaxed IOU with an expansion factor.
    pub fn relaxed_iou(&self, other: &BoundingBox, relaxation: f32) -> f32 {
        let self_width = self.right - self.left;
        let self_height = self.bottom - self.top;
        let self_expansion = relaxation * self_width.min(self_height).max(0.0);

        let other_width = other.right - other.left;
        let other_height = other.bottom - other.top;
        let other_expansion = relaxation * other_width.min(other_height).max(0.0);

        let expanded_self = BoundingBox {
            left: (self.left - self_expansion).max(0.0),
            top: (self.top - self_expansion).max(0.0),
            right: self.right + self_expansion,
            bottom: self.bottom + self_expansion,
        };

        let expanded_other = BoundingBox {
            left: (other.left - other_expansion).max(0.0),
            top: (other.top - other_expansion).max(0.0),
            right: other.right + other_expansion,
            bottom: other.bottom + other_expansion,
        };

        expanded_self.iou(&expanded_other)
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
#[derive(Debug, Clone, PartialEq)]
pub struct TextBlock {
    /// The text content
    pub text: String,
    /// The bounding box of the block
    pub bbox: BoundingBox,
    /// The font size of the text in this block
    pub font_size: f32,
}

/// A cluster of text blocks with the same font size characteristics.
#[derive(Debug, Clone)]
pub struct FontSizeCluster {
    /// The centroid (mean) font size of this cluster
    pub centroid: f32,
    /// The text blocks that belong to this cluster
    pub members: Vec<TextBlock>,
}

/// Result of KMeans clustering on font sizes.
///
/// Contains cluster labels for each block, where cluster index indicates
/// the hierarchy level: 0=H1, 1=H2, ..., 5=H6, 6+=Body.
#[derive(Debug, Clone)]
pub struct KMeansResult {
    /// Cluster label for each block (0-indexed)
    pub labels: Vec<u32>,
}

/// Hierarchy level assignment result.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HierarchyLevel {
    /// H1 - Top-level heading
    H1 = 1,
    /// H2 - Secondary heading
    H2 = 2,
    /// H3 - Tertiary heading
    H3 = 3,
    /// H4 - Quaternary heading
    H4 = 4,
    /// H5 - Quinary heading
    H5 = 5,
    /// H6 - Senary heading
    H6 = 6,
    /// Body text
    Body = 0,
}

/// A TextBlock with hierarchy level assignment.
#[derive(Debug, Clone)]
pub struct HierarchyBlock {
    /// The text content
    pub text: String,
    /// The bounding box of the block
    pub bbox: BoundingBox,
    /// The font size of the text in this block
    pub font_size: f32,
    /// The hierarchy level of this block (H1-H6 or Body)
    pub hierarchy_level: HierarchyLevel,
}

impl HierarchyLevel {
    /// Convert a numeric level to HierarchyLevel.
    pub fn from_level(level: usize) -> Self {
        match level {
            1 => HierarchyLevel::H1,
            2 => HierarchyLevel::H2,
            3 => HierarchyLevel::H3,
            4 => HierarchyLevel::H4,
            5 => HierarchyLevel::H5,
            6 => HierarchyLevel::H6,
            _ => HierarchyLevel::Body,
        }
    }
}

/// Assign hierarchy levels to text blocks based on KMeans clustering results.
///
/// Maps cluster indices to HTML heading levels (H1-H6) and body text:
/// - Cluster 0 → H1 (top-level heading)
/// - Cluster 1 → H2 (secondary heading)
/// - Cluster 2 → H3 (tertiary heading)
/// - Cluster 3 → H4 (quaternary heading)
/// - Cluster 4 → H5 (quinary heading)
/// - Cluster 5 → H6 (senary heading)
/// - Cluster 6+ → Body (body text)
///
/// # Arguments
///
/// * `blocks` - Slice of TextBlock objects to assign hierarchy levels to
/// * `kmeans_result` - KMeansResult containing cluster labels for each block
///
/// # Returns
///
/// Vector of tuples containing (original block info, hierarchy level)
///
/// # Example
///
/// ```rust,no_run
/// # #[cfg(feature = "pdf")]
/// # {
/// use kreuzberg::pdf::hierarchy::{TextBlock, BoundingBox, HierarchyLevel, assign_hierarchy_levels, KMeansResult};
///
/// let blocks = vec![
///     TextBlock {
///         text: "Title".to_string(),
///         bbox: BoundingBox { left: 0.0, top: 0.0, right: 100.0, bottom: 24.0 },
///         font_size: 24.0,
///     },
///     TextBlock {
///         text: "Body".to_string(),
///         bbox: BoundingBox { left: 0.0, top: 30.0, right: 100.0, bottom: 42.0 },
///         font_size: 12.0,
///     },
/// ];
///
/// let kmeans_result = KMeansResult {
///     labels: vec![0, 6],
/// };
///
/// let results = assign_hierarchy_levels(&blocks, &kmeans_result);
/// assert_eq!(results[0].hierarchy_level, HierarchyLevel::H1);
/// assert_eq!(results[1].hierarchy_level, HierarchyLevel::Body);
/// # }
/// ```
pub fn assign_hierarchy_levels(blocks: &[TextBlock], kmeans_result: &KMeansResult) -> Vec<HierarchyBlock> {
    if blocks.is_empty() || kmeans_result.labels.is_empty() {
        return Vec::new();
    }

    blocks
        .iter()
        .zip(kmeans_result.labels.iter())
        .map(|(block, &cluster_id)| {
            let hierarchy_level = match cluster_id {
                0 => HierarchyLevel::H1,
                1 => HierarchyLevel::H2,
                2 => HierarchyLevel::H3,
                3 => HierarchyLevel::H4,
                4 => HierarchyLevel::H5,
                5 => HierarchyLevel::H6,
                _ => HierarchyLevel::Body,
            };

            HierarchyBlock {
                text: block.text.clone(),
                bbox: block.bbox,
                font_size: block.font_size,
                hierarchy_level,
            }
        })
        .collect()
}

/// Assign hierarchy levels to text blocks based on font size clusters.
///
/// Maps font size clusters to heading levels (H1-H6) and body text.
/// Larger font sizes are assigned higher hierarchy levels.
///
/// # Arguments
///
/// * `blocks` - Vector of TextBlock objects to assign levels to
/// * `clusters` - Vector of FontSizeCluster objects from clustering
///
/// # Returns
///
/// Vector of tuples containing (TextBlock, HierarchyLevel).
/// If blocks is empty or clusters is empty, returns empty vector.
/// All blocks get Body level if only one cluster exists.
pub fn assign_hierarchy_levels_from_clusters(
    blocks: &[TextBlock],
    clusters: &[FontSizeCluster],
) -> Vec<(TextBlock, HierarchyLevel)> {
    // Edge cases: empty inputs
    if blocks.is_empty() || clusters.is_empty() {
        return Vec::new();
    }

    // If only one cluster, all text is body
    if clusters.len() == 1 {
        return blocks.iter().map(|b| (b.clone(), HierarchyLevel::Body)).collect();
    }

    // Map clusters (sorted by centroid) to hierarchy levels
    // We assign up to 6 heading levels, rest are body
    let max_heading_levels = 6;
    let num_headings = (clusters.len() - 1).min(max_heading_levels);

    // Create a mapping from centroid to hierarchy level
    let mut result = Vec::new();

    for block in blocks {
        // Find which cluster this block belongs to
        let mut assigned_level = HierarchyLevel::Body;

        for (idx, cluster) in clusters.iter().enumerate() {
            // Check if block's font size is close to this cluster's centroid
            let font_size = block.font_size;
            if (font_size - cluster.centroid).abs() < 1.0 || cluster.members.contains(block) {
                // Map cluster index to hierarchy level (largest centroid = H1)
                if idx < num_headings {
                    assigned_level = HierarchyLevel::from_level(idx + 1);
                } else {
                    assigned_level = HierarchyLevel::Body;
                }
                break;
            }
        }

        result.push((block.clone(), assigned_level));
    }

    result
}

/// Cluster text blocks by font size using k-means algorithm.
///
/// Uses k-means clustering to group text blocks by their font size, which helps
/// identify document hierarchy levels (H1, H2, Body, etc.). The algorithm:
/// 1. Extracts font sizes from text blocks
/// 2. Applies k-means clustering to group similar font sizes
/// 3. Sorts clusters by centroid size in descending order (largest = H1)
/// 4. Returns clusters with their member blocks
///
/// # Arguments
///
/// * `blocks` - Slice of TextBlock objects to cluster
/// * `k` - Number of clusters to create
///
/// # Returns
///
/// Result with vector of FontSizeCluster ordered by size (descending),
/// or an error if clustering fails
///
/// # Example
///
/// ```rust,no_run
/// # #[cfg(feature = "pdf")]
/// # {
/// use kreuzberg::pdf::hierarchy::{TextBlock, BoundingBox, cluster_font_sizes};
///
/// let blocks = vec![
///     TextBlock {
///         text: "Title".to_string(),
///         bbox: BoundingBox { left: 0.0, top: 0.0, right: 100.0, bottom: 24.0 },
///         font_size: 24.0,
///     },
///     TextBlock {
///         text: "Body".to_string(),
///         bbox: BoundingBox { left: 0.0, top: 30.0, right: 100.0, bottom: 42.0 },
///         font_size: 12.0,
///     },
/// ];
///
/// let clusters = cluster_font_sizes(&blocks, 2).unwrap();
/// assert_eq!(clusters.len(), 2);
/// assert_eq!(clusters[0].centroid, 24.0); // Largest is first
/// # }
/// ```
/// Helper function to assign blocks to their nearest centroid.
///
/// Iterates through blocks and finds the closest centroid for each block,
/// grouping them into clusters. Used in k-means clustering iterations.
///
/// # Arguments
///
/// * `blocks` - Slice of TextBlock objects to assign
/// * `centroids` - Slice of centroid values (one per cluster)
///
/// # Returns
///
/// A vector of clusters, where each cluster contains the TextBlock objects
/// assigned to that centroid
fn assign_blocks_to_centroids(blocks: &[TextBlock], centroids: &[f32]) -> Vec<Vec<TextBlock>> {
    let mut clusters: Vec<Vec<TextBlock>> = vec![Vec::new(); centroids.len()];

    for block in blocks {
        let mut min_distance = f32::INFINITY;
        let mut best_cluster = 0;

        for (i, &centroid) in centroids.iter().enumerate() {
            let distance = (block.font_size - centroid).abs();
            if distance < min_distance {
                min_distance = distance;
                best_cluster = i;
            }
        }

        clusters[best_cluster].push(block.clone());
    }

    clusters
}

pub fn cluster_font_sizes(blocks: &[TextBlock], k: usize) -> Result<Vec<FontSizeCluster>> {
    if blocks.is_empty() {
        return Ok(Vec::new());
    }

    if k == 0 {
        return Err(PdfError::TextExtractionFailed("K must be greater than 0".to_string()));
    }

    let actual_k = k.min(blocks.len());

    // Extract unique font sizes for initialization
    let mut font_sizes: Vec<f32> = blocks.iter().map(|b| b.font_size).collect();
    font_sizes.sort_by(|a, b| b.partial_cmp(a).expect("Failed to compare font sizes during sorting")); // Sort descending
    font_sizes.dedup(); // Remove duplicates to get unique font sizes

    // Initialize centroids using actual font sizes from the data
    // This is more robust than dividing the range uniformly
    let mut centroids: Vec<f32> = Vec::new();

    if font_sizes.len() >= actual_k {
        // If we have at least k unique font sizes, pick them evenly spaced
        let step = font_sizes.len() / actual_k;
        for i in 0..actual_k {
            let idx = i * step;
            centroids.push(font_sizes[idx.min(font_sizes.len() - 1)]);
        }
    } else {
        // If we have fewer unique sizes than k, use all of them and fill with interpolated values
        centroids = font_sizes.clone();

        // Add interpolated centroids between existing ones to reach desired k
        let min_font = font_sizes[font_sizes.len() - 1];
        let max_font = font_sizes[0];
        let range = max_font - min_font;

        while centroids.len() < actual_k {
            let t = centroids.len() as f32 / (actual_k - 1) as f32;
            let interpolated = max_font - t * range;
            centroids.push(interpolated);
        }

        centroids.sort_by(|a, b| b.partial_cmp(a).expect("Failed to compare centroids during sorting"));
        // Keep sorted descending
    }

    // Run k-means clustering for a fixed number of iterations
    for _ in 0..KMEANS_MAX_ITERATIONS {
        // Assign blocks to nearest centroid
        let clusters = assign_blocks_to_centroids(blocks, &centroids);

        // Update centroids
        let mut new_centroids = Vec::with_capacity(actual_k);
        for (i, cluster) in clusters.iter().enumerate() {
            if !cluster.is_empty() {
                new_centroids.push(cluster.iter().map(|b| b.font_size).sum::<f32>() / cluster.len() as f32);
            } else {
                new_centroids.push(centroids[i]);
            }
        }

        // Check for convergence
        let converged = centroids
            .iter()
            .zip(new_centroids.iter())
            .all(|(old, new)| (old - new).abs() < KMEANS_CONVERGENCE_THRESHOLD);

        std::mem::swap(&mut centroids, &mut new_centroids);

        if converged {
            break;
        }
    }

    // Final assignment to create result
    let clusters = assign_blocks_to_centroids(blocks, &centroids);

    // Create FontSizeCluster objects with centroids
    let mut result: Vec<FontSizeCluster> = Vec::new();

    for i in 0..actual_k {
        if !clusters[i].is_empty() {
            let centroid_value = centroids[i];
            result.push(FontSizeCluster {
                centroid: centroid_value,
                members: clusters[i].clone(),
            });
        }
    }

    // Sort by centroid size in descending order (largest font = H1)
    result.sort_by(|a, b| {
        b.centroid
            .partial_cmp(&a.centroid)
            .expect("Failed to compare centroids during final sort")
    });

    Ok(result)
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
    let char_count = chars.len();
    let mut char_data_list = Vec::with_capacity(char_count);

    // Use indexed access instead of iterator to avoid potential PDFium issues
    for i in 0..char_count {
        let Ok(pdf_char) = chars.get(i) else {
            continue;
        };

        // Get character unicode - skip if not available
        let Some(ch) = pdf_char.unicode_char() else {
            continue;
        };

        // Get font size - use DEFAULT_FONT_SIZE if not available
        let font_size = pdf_char.unscaled_font_size().value;
        let font_size = if font_size > 0.0 { font_size } else { DEFAULT_FONT_SIZE };

        // Get character bounds - skip character if bounds not available
        let Ok(bounds) = pdf_char.loose_bounds() else {
            continue;
        };

        // Extract position and size information
        let char_data = CharData {
            text: ch.to_string(),
            x: bounds.left().value,
            y: bounds.bottom().value,
            width: bounds.width().value,
            height: bounds.height().value,
            font_size,
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
        let y_diff =
            a.1.top
                .partial_cmp(&b.1.top)
                .expect("Failed to compare top coordinates");
        if y_diff != std::cmp::Ordering::Equal {
            y_diff
        } else {
            a.1.left
                .partial_cmp(&b.1.left)
                .expect("Failed to compare left coordinates")
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

                let intersection_ratio = block_bbox.intersection_ratio(&next_bbox);

                // Check individual component distances
                let (self_center_x, self_center_y) = block_bbox.center();
                let (other_center_x, other_center_y) = next_bbox.center();
                let dx = (self_center_x - other_center_x).abs();
                let dy = (self_center_y - other_center_y).abs();

                // Separate thresholds for X and Y to handle different scenarios
                // Horizontal merging: allow up to 2-3 character widths apart (typical letter spacing)
                // Width per character ≈ 0.6 * font_size, spacing between chars ≈ 0.3 * font_size
                let x_threshold = avg_font_size * MERGE_X_THRESHOLD_MULTIPLIER;
                // Vertical merging: allow characters on same line (Y threshold is font height)
                let y_threshold = avg_font_size * MERGE_Y_THRESHOLD_MULTIPLIER;

                // Merge if close enough in both dimensions or overlapping
                let merge_by_distance = (dx < x_threshold) && (dy < y_threshold);
                if merge_by_distance || intersection_ratio > MERGE_INTERSECTION_THRESHOLD {
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

            // Calculate bounding box and average font size in a single fold operation
            let (min_x, min_y, max_x, max_y, total_font_size) = block.iter().fold(
                (f32::INFINITY, f32::INFINITY, f32::NEG_INFINITY, f32::NEG_INFINITY, 0.0),
                |(min_x, min_y, max_x, max_y, total_font_size), char_data| {
                    (
                        min_x.min(char_data.x),
                        min_y.min(char_data.y - char_data.height),
                        max_x.max(char_data.x + char_data.width),
                        max_y.max(char_data.y),
                        total_font_size + char_data.font_size,
                    )
                },
            );

            let avg_font_size = total_font_size / block.len() as f32;

            // Bounding box coordinates (allow negative values from PDFs)
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

/// Determine whether OCR should be triggered based on text block coverage.
///
/// Analyzes the coverage of text blocks on a PDF page and decides if OCR
/// should be run. OCR is triggered when the text blocks cover less than a
/// certain percentage (default 50%) of the page area.
///
/// # Arguments
///
/// * `page` - The PDF page to analyze
/// * `blocks` - Slice of TextBlock objects present on the page
/// * `config` - Extraction configuration containing OCR and PDF settings
///
/// # Returns
///
/// `true` if OCR should be triggered (coverage below threshold), `false` otherwise.
pub fn should_trigger_ocr(page: &PdfPage, blocks: &[TextBlock], config: &ExtractionConfig) -> bool {
    // Get page dimensions using width() and height() methods
    let page_width = page.width().value;
    let page_height = page.height().value;
    let page_area = page_width * page_height;

    // Handle edge case: invalid page area
    if page_area <= 0.0 {
        return true; // Trigger OCR for invalid pages
    }

    // Calculate total text block area
    let text_area: f32 = blocks
        .iter()
        .map(|block| {
            let width = (block.bbox.right - block.bbox.left).max(0.0);
            let height = (block.bbox.bottom - block.bbox.top).max(0.0);
            width * height
        })
        .sum();

    // Calculate coverage ratio
    let coverage = text_area / page_area;

    // Get the OCR coverage threshold from config
    // Try to get from hierarchy config first, then fall back to default 0.5 (50%)
    let threshold = config
        .pdf_options
        .as_ref()
        .and_then(|pdf_config| pdf_config.hierarchy.as_ref())
        .and_then(|hierarchy_config| hierarchy_config.ocr_coverage_threshold)
        .unwrap_or(0.5);

    // Trigger OCR if coverage is below threshold
    coverage < threshold
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
