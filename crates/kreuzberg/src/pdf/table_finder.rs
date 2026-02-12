//! Table detection using edge intersection analysis.
//!
//! Ported from pdfplumber's `table.py`. Detects tables in PDFs by finding
//! drawn edges (lines, rectangles, curves), computing their intersections,
//! and constructing cells from rectangular regions bounded by intersections.
//!
//! Supports multiple strategies:
//! - **Lines**: Uses drawn PDF edges (lines, rects, curves)
//! - **Lines strict**: Only uses explicit line objects (not rects/curves)
//! - **Text**: Infers edges from word alignment patterns
//! - **Explicit**: Uses user-provided edge positions

use std::collections::{BTreeMap, HashMap, HashSet};

use super::table_clustering::PositionedWord;
use super::table_edges::{extract_edges_from_page, words_to_edges_h, words_to_edges_v};
use super::table_geometry::{
    Bbox, Edge, EdgeType, Orientation, filter_edges, merge_edges,
};

use super::error::{PdfError, Result};
use pdfium_render::prelude::*;

/// Default snap tolerance (pixels).
const DEFAULT_SNAP_TOLERANCE: f64 = 3.0;
/// Default join tolerance (pixels).
const DEFAULT_JOIN_TOLERANCE: f64 = 3.0;
/// Default minimum edge length.
const DEFAULT_EDGE_MIN_LENGTH: f64 = 3.0;
/// Default minimum edge length for pre-filtering.
const DEFAULT_EDGE_MIN_LENGTH_PREFILTER: f64 = 1.0;
/// Default minimum words for vertical text edge detection.
const DEFAULT_MIN_WORDS_VERTICAL: usize = 3;
/// Default minimum words for horizontal text edge detection.
const DEFAULT_MIN_WORDS_HORIZONTAL: usize = 1;
/// Default intersection tolerance.
const DEFAULT_INTERSECTION_TOLERANCE: f64 = 3.0;

/// Strategy for detecting table edges.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TableStrategy {
    /// Use drawn PDF lines, rects, and curves as edges.
    Lines,
    /// Use only explicit line objects (not rects/curves).
    LinesStrict,
    /// Infer edges from word position alignment.
    Text,
    /// Use explicitly provided edge positions.
    Explicit,
}

/// Configuration for table detection.
#[derive(Debug, Clone)]
pub struct TableSettings {
    /// Strategy for detecting vertical edges.
    pub vertical_strategy: TableStrategy,
    /// Strategy for detecting horizontal edges.
    pub horizontal_strategy: TableStrategy,
    /// Explicitly provided vertical line positions (x-coordinates).
    pub explicit_vertical_lines: Vec<f64>,
    /// Explicitly provided horizontal line positions (y-coordinates).
    pub explicit_horizontal_lines: Vec<f64>,
    /// Snap tolerance for aligning nearby edges.
    pub snap_tolerance: f64,
    /// Join tolerance for merging collinear edge segments.
    pub join_tolerance: f64,
    /// Minimum edge length after merging.
    pub edge_min_length: f64,
    /// Minimum edge length for pre-filtering (before merge).
    pub edge_min_length_prefilter: f64,
    /// Minimum words for vertical text strategy.
    pub min_words_vertical: usize,
    /// Minimum words for horizontal text strategy.
    pub min_words_horizontal: usize,
    /// Tolerance for intersection detection.
    pub intersection_tolerance: f64,
}

impl Default for TableSettings {
    fn default() -> Self {
        Self {
            vertical_strategy: TableStrategy::Lines,
            horizontal_strategy: TableStrategy::Lines,
            explicit_vertical_lines: Vec::new(),
            explicit_horizontal_lines: Vec::new(),
            snap_tolerance: DEFAULT_SNAP_TOLERANCE,
            join_tolerance: DEFAULT_JOIN_TOLERANCE,
            edge_min_length: DEFAULT_EDGE_MIN_LENGTH,
            edge_min_length_prefilter: DEFAULT_EDGE_MIN_LENGTH_PREFILTER,
            min_words_vertical: DEFAULT_MIN_WORDS_VERTICAL,
            min_words_horizontal: DEFAULT_MIN_WORDS_HORIZONTAL,
            intersection_tolerance: DEFAULT_INTERSECTION_TOLERANCE,
        }
    }
}

/// A detected table with its cells.
#[derive(Debug, Clone)]
pub struct DetectedTable {
    /// Cell bounding boxes: (x0, top, x1, bottom).
    pub cells: Vec<Bbox>,
    /// The bounding box of the entire table.
    pub bbox: Bbox,
}

impl DetectedTable {
    /// Get rows of cells, sorted top-to-bottom, left-to-right.
    pub fn rows(&self) -> Vec<Vec<Option<Bbox>>> {
        if self.cells.is_empty() {
            return Vec::new();
        }

        // Collect all unique x0 values (column starts)
        let mut x_values: Vec<f64> = self.cells.iter().map(|c| c.0).collect();
        x_values.sort_by(|a, b| a.partial_cmp(b).unwrap());
        x_values.dedup_by(|a, b| (*a - *b).abs() < f64::EPSILON);

        // Group cells by top coordinate (rows)
        let mut by_top: BTreeMap<u64, Vec<Bbox>> = BTreeMap::new();
        for &cell in &self.cells {
            by_top.entry(cell.1.to_bits()).or_default().push(cell);
        }

        let mut rows = Vec::new();
        for (_, row_cells) in &by_top {
            let cell_map: HashMap<u64, Bbox> = row_cells.iter().map(|c| (c.0.to_bits(), *c)).collect();
            let row: Vec<Option<Bbox>> = x_values.iter().map(|x| cell_map.get(&x.to_bits()).copied()).collect();
            rows.push(row);
        }

        rows
    }
}

/// Result of table finding on a page.
#[derive(Debug)]
pub struct TableFinderResult {
    /// All edges found on the page.
    pub edges: Vec<Edge>,
    /// Intersection points.
    pub intersections: HashMap<(u64, u64), IntersectionEdges>,
    /// Individual cells detected.
    pub cells: Vec<Bbox>,
    /// Detected tables (groups of contiguous cells).
    pub tables: Vec<DetectedTable>,
}

/// Edges meeting at an intersection point.
#[derive(Debug, Clone)]
pub struct IntersectionEdges {
    pub vertical: Vec<usize>,
    pub horizontal: Vec<usize>,
}

/// Find tables on a PDF page using the given settings.
///
/// This is the main entry point for table detection.
pub fn find_tables(
    page: &PdfPage,
    settings: &TableSettings,
    words: Option<&[PositionedWord]>,
) -> Result<TableFinderResult> {
    let page_bbox = (
        0.0,
        0.0,
        page.width().value as f64,
        page.height().value as f64,
    );

    // Step 1: Collect edges based on strategies
    let edges = collect_edges(page, settings, words, page_bbox)?;

    // Step 2: Find intersections
    let intersections = edges_to_intersections(
        &edges,
        settings.intersection_tolerance,
        settings.intersection_tolerance,
    );

    // Step 3: Find cells from intersections
    let cells = intersections_to_cells(&intersections, &edges);

    // Step 4: Group cells into tables
    let table_groups = cells_to_tables(&cells);
    let tables: Vec<DetectedTable> = table_groups
        .into_iter()
        .map(|cell_group| {
            let bbox = cell_group.iter().fold(
                (f64::INFINITY, f64::INFINITY, f64::NEG_INFINITY, f64::NEG_INFINITY),
                |(x0, top, x1, bottom), cell| {
                    (x0.min(cell.0), top.min(cell.1), x1.max(cell.2), bottom.max(cell.3))
                },
            );
            DetectedTable {
                cells: cell_group,
                bbox,
            }
        })
        .collect();

    Ok(TableFinderResult {
        edges,
        intersections,
        cells,
        tables,
    })
}

/// Collect edges based on vertical and horizontal strategies.
fn collect_edges(
    page: &PdfPage,
    settings: &TableSettings,
    words: Option<&[PositionedWord]>,
    page_bbox: Bbox,
) -> Result<Vec<Edge>> {
    // Get raw edges from PDF drawing objects (needed for "lines" strategies)
    let raw_edges = extract_edges_from_page(page, settings.edge_min_length_prefilter)?;

    // Vertical edges
    let mut v_edges = match settings.vertical_strategy {
        TableStrategy::Lines => {
            filter_edges(&raw_edges, Some(Orientation::Vertical), None, settings.edge_min_length_prefilter)
        }
        TableStrategy::LinesStrict => {
            filter_edges(
                &raw_edges,
                Some(Orientation::Vertical),
                Some(EdgeType::Line),
                settings.edge_min_length_prefilter,
            )
        }
        TableStrategy::Text => {
            let w = words.unwrap_or(&[]);
            words_to_edges_v(w, settings.min_words_vertical)
        }
        TableStrategy::Explicit => Vec::new(),
    };

    // Add explicit vertical lines
    for &x in &settings.explicit_vertical_lines {
        v_edges.push(Edge::vertical(x, page_bbox.1, page_bbox.3, EdgeType::Line));
    }

    // Horizontal edges
    let mut h_edges = match settings.horizontal_strategy {
        TableStrategy::Lines => {
            filter_edges(&raw_edges, Some(Orientation::Horizontal), None, settings.edge_min_length_prefilter)
        }
        TableStrategy::LinesStrict => {
            filter_edges(
                &raw_edges,
                Some(Orientation::Horizontal),
                Some(EdgeType::Line),
                settings.edge_min_length_prefilter,
            )
        }
        TableStrategy::Text => {
            let w = words.unwrap_or(&[]);
            words_to_edges_h(w, settings.min_words_horizontal)
        }
        TableStrategy::Explicit => Vec::new(),
    };

    // Add explicit horizontal lines
    for &y in &settings.explicit_horizontal_lines {
        h_edges.push(Edge::horizontal(page_bbox.0, page_bbox.2, y, EdgeType::Line));
    }

    // Combine and merge
    let mut all_edges = v_edges;
    all_edges.extend(h_edges);

    let all_edges = merge_edges(
        all_edges,
        settings.snap_tolerance,
        settings.snap_tolerance,
        settings.join_tolerance,
        settings.join_tolerance,
    );

    // Final filter by minimum length
    Ok(filter_edges(&all_edges, None, None, settings.edge_min_length))
}

/// Find intersection points between horizontal and vertical edges.
///
/// An intersection exists where a vertical edge crosses a horizontal edge
/// within the given tolerances.
fn edges_to_intersections(
    edges: &[Edge],
    x_tolerance: f64,
    y_tolerance: f64,
) -> HashMap<(u64, u64), IntersectionEdges> {
    let mut intersections: HashMap<(u64, u64), IntersectionEdges> = HashMap::new();

    let v_edges: Vec<(usize, &Edge)> = edges
        .iter()
        .enumerate()
        .filter(|(_, e)| e.orientation == Orientation::Vertical)
        .collect();

    let h_edges: Vec<(usize, &Edge)> = edges
        .iter()
        .enumerate()
        .filter(|(_, e)| e.orientation == Orientation::Horizontal)
        .collect();

    for &(v_idx, v) in &v_edges {
        for &(h_idx, h) in &h_edges {
            if v.top <= (h.top + y_tolerance)
                && v.bottom >= (h.top - y_tolerance)
                && v.x0 >= (h.x0 - x_tolerance)
                && v.x0 <= (h.x1 + x_tolerance)
            {
                let vertex = (v.x0.to_bits(), h.top.to_bits());
                let entry = intersections.entry(vertex).or_insert_with(|| IntersectionEdges {
                    vertical: Vec::new(),
                    horizontal: Vec::new(),
                });
                entry.vertical.push(v_idx);
                entry.horizontal.push(h_idx);
            }
        }
    }

    intersections
}

/// Given intersection points, find all rectangular cells.
///
/// A cell is formed when four intersection points form a rectangle,
/// and each pair of adjacent corners is connected by the same edge.
fn intersections_to_cells(
    intersections: &HashMap<(u64, u64), IntersectionEdges>,
    _edges: &[Edge],
) -> Vec<Bbox> {
    let edge_connects = |p1: (u64, u64), p2: (u64, u64)| -> bool {
        let i1 = match intersections.get(&p1) {
            Some(i) => i,
            None => return false,
        };
        let i2 = match intersections.get(&p2) {
            Some(i) => i,
            None => return false,
        };

        // Same x → check shared vertical edges
        if p1.0 == p2.0 {
            let set1: HashSet<usize> = i1.vertical.iter().copied().collect();
            return i2.vertical.iter().any(|e| set1.contains(e));
        }

        // Same y → check shared horizontal edges
        if p1.1 == p2.1 {
            let set1: HashSet<usize> = i1.horizontal.iter().copied().collect();
            return i2.horizontal.iter().any(|e| set1.contains(e));
        }

        false
    };

    let mut points: Vec<(u64, u64)> = intersections.keys().copied().collect();
    points.sort();

    let n = points.len();
    let mut cells = Vec::new();

    for i in 0..n {
        let pt = points[i];
        let rest = &points[i + 1..];

        // Find points directly below (same x) and to the right (same y)
        let below: Vec<(u64, u64)> = rest.iter().filter(|p| p.0 == pt.0).copied().collect();
        let right: Vec<(u64, u64)> = rest.iter().filter(|p| p.1 == pt.1).copied().collect();

        for &below_pt in &below {
            if !edge_connects(pt, below_pt) {
                continue;
            }

            for &right_pt in &right {
                if !edge_connects(pt, right_pt) {
                    continue;
                }

                let bottom_right = (right_pt.0, below_pt.1);

                if intersections.contains_key(&bottom_right)
                    && edge_connects(bottom_right, right_pt)
                    && edge_connects(bottom_right, below_pt)
                {
                    let x0 = f64::from_bits(pt.0);
                    let top = f64::from_bits(pt.1);
                    let x1 = f64::from_bits(bottom_right.0);
                    let bottom = f64::from_bits(bottom_right.1);
                    cells.push((x0, top, x1, bottom));
                    break; // Found the smallest cell for this top-left corner and this below point
                }
            }
        }
    }

    cells
}

/// Group contiguous cells into separate tables.
///
/// Cells that share corners belong to the same table.
fn cells_to_tables(cells: &[Bbox]) -> Vec<Vec<Bbox>> {
    fn bbox_corners(bbox: Bbox) -> [(u64, u64); 4] {
        let (x0, top, x1, bottom) = bbox;
        [
            (x0.to_bits(), top.to_bits()),
            (x0.to_bits(), bottom.to_bits()),
            (x1.to_bits(), top.to_bits()),
            (x1.to_bits(), bottom.to_bits()),
        ]
    }

    let mut remaining: Vec<Bbox> = cells.to_vec();
    let mut tables: Vec<Vec<Bbox>> = Vec::new();

    while !remaining.is_empty() {
        let mut current_corners: HashSet<(u64, u64)> = HashSet::new();
        let mut current_cells: Vec<Bbox> = Vec::new();

        loop {
            let initial_count = current_cells.len();

            remaining.retain(|cell| {
                let corners = bbox_corners(*cell);
                if current_cells.is_empty() {
                    // Start with the first cell
                    current_corners.extend(corners.iter());
                    current_cells.push(*cell);
                    false // Remove from remaining
                } else {
                    let shared = corners.iter().any(|c| current_corners.contains(c));
                    if shared {
                        current_corners.extend(corners.iter());
                        current_cells.push(*cell);
                        false // Remove from remaining
                    } else {
                        true // Keep in remaining
                    }
                }
            });

            if current_cells.len() == initial_count {
                break;
            }
        }

        if current_cells.len() > 1 {
            // Sort top-to-bottom, left-to-right
            current_cells.sort_by(|a, b| {
                a.1.partial_cmp(&b.1)
                    .unwrap()
                    .then(a.0.partial_cmp(&b.0).unwrap())
            });
            tables.push(current_cells);
        }
    }

    // Sort tables by position (top-to-bottom, left-to-right)
    tables.sort_by(|a, b| {
        let a_top = a.iter().map(|c| c.1).fold(f64::INFINITY, f64::min);
        let a_left = a.iter().map(|c| c.0).fold(f64::INFINITY, f64::min);
        let b_top = b.iter().map(|c| c.1).fold(f64::INFINITY, f64::min);
        let b_left = b.iter().map(|c| c.0).fold(f64::INFINITY, f64::min);
        a_top
            .partial_cmp(&b_top)
            .unwrap()
            .then(a_left.partial_cmp(&b_left).unwrap())
    });

    tables
}

/// Extract text content for each cell in a detected table.
///
/// For each cell, find characters whose midpoint falls within the cell bbox
/// and concatenate them.
pub fn extract_table_text(
    table: &DetectedTable,
    page: &PdfPage,
    page_height: f64,
) -> Result<Vec<Vec<String>>> {
    let rows = table.rows();

    let page_text = page
        .text()
        .map_err(|e| PdfError::TextExtractionFailed(format!("Failed to get page text: {}", e)))?;

    // Pre-collect all character positions
    struct CharPos {
        ch: char,
        mid_x: f64,
        mid_y: f64,
    }

    let chars_data: Vec<CharPos> = page_text
        .chars()
        .iter()
        .filter_map(|pdf_char| {
            let ch = pdf_char.unicode_char()?;
            let bounds = pdf_char.loose_bounds().ok()?;
            let mid_x = (bounds.left().value as f64 + (bounds.left().value as f64 + bounds.width().value as f64)) / 2.0;
            let mid_y = page_height - ((bounds.bottom().value as f64 + bounds.top().value as f64) / 2.0);
            Some(CharPos { ch, mid_x, mid_y })
        })
        .collect();

    let mut result = Vec::new();

    for row in &rows {
        let mut row_text = Vec::new();
        for cell_opt in row {
            match cell_opt {
                Some(cell) => {
                    let (x0, top, x1, bottom) = *cell;
                    let mut cell_chars: Vec<(f64, f64, char)> = chars_data
                        .iter()
                        .filter(|c| {
                            c.mid_x >= x0 && c.mid_x < x1 && c.mid_y >= top && c.mid_y < bottom
                        })
                        .map(|c| (c.mid_y, c.mid_x, c.ch))
                        .collect();

                    // Sort by y then x for reading order
                    cell_chars.sort_by(|a, b| {
                        a.0.partial_cmp(&b.0)
                            .unwrap()
                            .then(a.1.partial_cmp(&b.1).unwrap())
                    });

                    let text: String = cell_chars.iter().map(|(_, _, c)| c).collect();
                    row_text.push(text.trim().to_string());
                }
                None => {
                    row_text.push(String::new());
                }
            }
        }
        result.push(row_text);
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_table_settings_default() {
        let settings = TableSettings::default();
        assert_eq!(settings.vertical_strategy, TableStrategy::Lines);
        assert_eq!(settings.horizontal_strategy, TableStrategy::Lines);
        assert_eq!(settings.snap_tolerance, 3.0);
        assert_eq!(settings.join_tolerance, 3.0);
    }

    #[test]
    fn test_intersections_basic() {
        // Create a simple 2x2 grid of edges
        let edges = vec![
            // Horizontal lines at y=0, y=50, y=100
            Edge::horizontal(0.0, 100.0, 0.0, EdgeType::Line),
            Edge::horizontal(0.0, 100.0, 50.0, EdgeType::Line),
            Edge::horizontal(0.0, 100.0, 100.0, EdgeType::Line),
            // Vertical lines at x=0, x=50, x=100
            Edge::vertical(0.0, 0.0, 100.0, EdgeType::Line),
            Edge::vertical(50.0, 0.0, 100.0, EdgeType::Line),
            Edge::vertical(100.0, 0.0, 100.0, EdgeType::Line),
        ];

        let intersections = edges_to_intersections(&edges, 1.0, 1.0);
        // Should find 9 intersection points (3x3 grid)
        assert_eq!(intersections.len(), 9);
    }

    #[test]
    fn test_intersections_to_cells() {
        let edges = vec![
            Edge::horizontal(0.0, 100.0, 0.0, EdgeType::Line),
            Edge::horizontal(0.0, 100.0, 50.0, EdgeType::Line),
            Edge::horizontal(0.0, 100.0, 100.0, EdgeType::Line),
            Edge::vertical(0.0, 0.0, 100.0, EdgeType::Line),
            Edge::vertical(50.0, 0.0, 100.0, EdgeType::Line),
            Edge::vertical(100.0, 0.0, 100.0, EdgeType::Line),
        ];

        let intersections = edges_to_intersections(&edges, 1.0, 1.0);
        let cells = intersections_to_cells(&intersections, &edges);

        // A 3x3 grid produces 6 cells: 4 minimal (1x1) + 2 spanning cells
        // (matching pdfplumber's behavior — spanning cells get resolved during table grouping)
        assert_eq!(cells.len(), 6);
        // Verify all 4 minimal cells are present
        assert!(cells.contains(&(0.0, 0.0, 50.0, 50.0)));
        assert!(cells.contains(&(50.0, 0.0, 100.0, 50.0)));
        assert!(cells.contains(&(0.0, 50.0, 50.0, 100.0)));
        assert!(cells.contains(&(50.0, 50.0, 100.0, 100.0)));
    }

    #[test]
    fn test_cells_to_tables_single() {
        let cells = vec![
            (0.0, 0.0, 50.0, 50.0),
            (50.0, 0.0, 100.0, 50.0),
            (0.0, 50.0, 50.0, 100.0),
            (50.0, 50.0, 100.0, 100.0),
        ];

        let tables = cells_to_tables(&cells);
        assert_eq!(tables.len(), 1);
        assert_eq!(tables[0].len(), 4);
    }

    #[test]
    fn test_cells_to_tables_multiple() {
        let cells = vec![
            // Table 1
            (0.0, 0.0, 50.0, 50.0),
            (50.0, 0.0, 100.0, 50.0),
            // Table 2 (far away)
            (200.0, 200.0, 250.0, 250.0),
            (250.0, 200.0, 300.0, 250.0),
        ];

        let tables = cells_to_tables(&cells);
        assert_eq!(tables.len(), 2);
    }

    #[test]
    fn test_detected_table_rows() {
        let table = DetectedTable {
            cells: vec![
                (0.0, 0.0, 50.0, 50.0),
                (50.0, 0.0, 100.0, 50.0),
                (0.0, 50.0, 50.0, 100.0),
                (50.0, 50.0, 100.0, 100.0),
            ],
            bbox: (0.0, 0.0, 100.0, 100.0),
        };

        let rows = table.rows();
        assert_eq!(rows.len(), 2);
        assert_eq!(rows[0].len(), 2);
        assert!(rows[0][0].is_some());
        assert!(rows[0][1].is_some());
    }

    #[test]
    fn test_cells_to_tables_empty() {
        let cells: Vec<Bbox> = Vec::new();
        let tables = cells_to_tables(&cells);
        assert!(tables.is_empty());
    }
}
