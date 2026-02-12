//! Extract edges from PDFium page objects for table detection.
//!
//! This module bridges PDFium's page object API to the table detection pipeline.
//! It extracts horizontal and vertical lines from PDF path objects (drawn lines,
//! rectangles, curves) and converts them to `Edge` format.

use super::error::Result;
use super::table_geometry::{Edge, EdgeType};
use pdfium_render::prelude::*;

/// Tolerance for considering a line as horizontal or vertical (in PDF points).
/// Lines with slope within this tolerance of perfectly h/v are accepted.
const ORIENTATION_TOLERANCE: f64 = 1.0;

/// Extract all edges (horizontal and vertical lines) from a PDF page's drawing objects.
///
/// Iterates through all page objects, extracts path objects, and converts their
/// segments into edges suitable for table detection.
///
/// # Arguments
///
/// * `page` - The PDF page to extract edges from
/// * `min_length` - Minimum edge length to include (filters noise)
///
/// # Returns
///
/// A vector of edges extracted from the page's drawing objects.
pub fn extract_edges_from_page(page: &PdfPage, min_length: f64) -> Result<Vec<Edge>> {
    let mut edges = Vec::new();
    let page_height = page.height().value as f64;

    let objects = page.objects();

    for object in objects.iter() {
        match object.as_path_object() {
            Some(path_obj) => {
                let path_edges = extract_edges_from_path(path_obj, page_height)?;
                edges.extend(path_edges);
            }
            None => continue,
        }
    }

    // Filter by minimum length
    edges.retain(|e| e.length() >= min_length);

    Ok(edges)
}

/// Extract edges from a single PDF path object.
///
/// Walks through the path segments, tracking the current position as we encounter
/// MoveTo/LineTo/BezierTo/Close operations. For each line segment, we check if
/// it's approximately horizontal or vertical, and if so, emit an Edge.
///
/// Edge types are classified by source:
/// - `LineTo` segments → `EdgeType::Line`
/// - `BezierTo` segments → `EdgeType::CurveEdge`
/// - Rectangular paths (MoveTo + 3-4 LineTo forming a rect) → `EdgeType::RectEdge`
///
/// This classification enables `LinesStrict` strategy to filter out rect/curve edges.
fn extract_edges_from_path(path_obj: &PdfPagePathObject, page_height: f64) -> Result<Vec<Edge>> {
    let mut edges = Vec::new();

    let segments = path_obj.segments();
    if segments.is_empty() {
        return Ok(edges);
    }

    // Collect all segment data for rectangle detection
    let mut points: Vec<(f64, f64)> = Vec::new();
    let mut has_bezier = false;
    let mut line_count = 0;

    let mut current_x: f64 = 0.0;
    let mut current_y: f64 = 0.0;
    let mut move_x: f64 = 0.0;
    let mut move_y: f64 = 0.0;

    for segment in segments.iter() {
        let seg_type = segment.segment_type();
        let x = segment.x().value as f64;
        let y = page_height - segment.y().value as f64;

        match seg_type {
            PdfPathSegmentType::MoveTo => {
                points.push((x, y));
            }
            PdfPathSegmentType::LineTo => {
                points.push((x, y));
                line_count += 1;
            }
            PdfPathSegmentType::BezierTo => {
                points.push((x, y));
                has_bezier = true;
            }
            _ => {}
        }
    }

    // Detect rectangular paths: MoveTo + 3-4 LineTo segments, no beziers,
    // forming an axis-aligned rectangle. These should be classified as RectEdge.
    let is_rect = !has_bezier && (line_count == 3 || line_count == 4) && is_rectangular_path(&points);

    // Now walk segments again to emit edges with correct types
    for segment in segments.iter() {
        let seg_type = segment.segment_type();
        let x = segment.x().value as f64;
        let y = page_height - segment.y().value as f64;

        match seg_type {
            PdfPathSegmentType::MoveTo => {
                current_x = x;
                current_y = y;
                move_x = x;
                move_y = y;
            }
            PdfPathSegmentType::LineTo => {
                let edge_type = if is_rect { EdgeType::RectEdge } else { EdgeType::Line };
                if let Some(edge) = line_to_edge(current_x, current_y, x, y, edge_type) {
                    edges.push(edge);
                }
                current_x = x;
                current_y = y;
            }
            PdfPathSegmentType::BezierTo => {
                // Bezier curves → CurveEdge. LinesStrict will filter these out.
                if let Some(edge) = line_to_edge(current_x, current_y, x, y, EdgeType::CurveEdge) {
                    edges.push(edge);
                }
                current_x = x;
                current_y = y;
            }
            _ => {}
        }

        // Handle close path — inherit type from the path classification
        if segment.is_close() {
            let edge_type = if is_rect {
                EdgeType::RectEdge
            } else if has_bezier {
                EdgeType::CurveEdge
            } else {
                EdgeType::Line
            };
            if let Some(edge) = line_to_edge(current_x, current_y, move_x, move_y, edge_type) {
                edges.push(edge);
            }
            current_x = move_x;
            current_y = move_y;
        }
    }

    Ok(edges)
}

/// Check if a sequence of points forms an axis-aligned rectangle.
///
/// A rectangular path has 4-5 points where consecutive edges are
/// alternately horizontal and vertical, forming a closed rectangle.
fn is_rectangular_path(points: &[(f64, f64)]) -> bool {
    if points.len() < 4 {
        return false;
    }

    // Check first 4 edges (from consecutive point pairs) for axis alignment
    for i in 0..points.len().min(4) {
        let j = (i + 1) % points.len();
        let dx = (points[j].0 - points[i].0).abs();
        let dy = (points[j].1 - points[i].1).abs();
        // Each edge must be either horizontal or vertical
        if dx > ORIENTATION_TOLERANCE && dy > ORIENTATION_TOLERANCE {
            return false;
        }
    }
    true
}

/// Convert a line segment to an Edge if it's approximately horizontal or vertical.
///
/// Returns `None` for diagonal lines (which aren't useful for table detection).
fn line_to_edge(x0: f64, y0: f64, x1: f64, y1: f64, edge_type: EdgeType) -> Option<Edge> {
    let dx = (x1 - x0).abs();
    let dy = (y1 - y0).abs();

    if dy <= ORIENTATION_TOLERANCE && dx > 0.0 {
        // Horizontal line
        let (left, right) = if x0 <= x1 { (x0, x1) } else { (x1, x0) };
        let avg_y = (y0 + y1) / 2.0;
        Some(Edge::horizontal(left, right, avg_y, edge_type))
    } else if dx <= ORIENTATION_TOLERANCE && dy > 0.0 {
        // Vertical line
        let (top, bottom) = if y0 <= y1 { (y0, y1) } else { (y1, y0) };
        let avg_x = (x0 + x1) / 2.0;
        Some(Edge::vertical(avg_x, top, bottom, edge_type))
    } else {
        // Diagonal — skip
        None
    }
}

/// Extract edges from a page and also compute "text" edges from word positions.
///
/// This combines drawn edges with edges inferred from text alignment,
/// similar to pdfplumber's "text" strategy.
pub fn words_to_edges_h(words: &[super::table_clustering::PositionedWord], word_threshold: usize) -> Vec<Edge> {
    use super::table_clustering::cluster_list;

    if words.is_empty() {
        return Vec::new();
    }

    // Cluster words by top coordinate
    let tops: Vec<f64> = words.iter().map(|w| w.top).collect();
    let clusters = cluster_list(&tops, 1.0);

    // Find clusters with enough words
    let large_clusters: Vec<Vec<usize>> = clusters
        .iter()
        .filter_map(|cluster| {
            // Find indices of words in this cluster
            let indices: Vec<usize> = words
                .iter()
                .enumerate()
                .filter(|(_, w)| cluster.iter().any(|&t| (w.top - t).abs() < f64::EPSILON))
                .map(|(i, _)| i)
                .collect();
            if indices.len() >= word_threshold {
                Some(indices)
            } else {
                None
            }
        })
        .collect();

    if large_clusters.is_empty() {
        return Vec::new();
    }

    // Find global x range
    let min_x0 = words.iter().map(|w| w.x0).fold(f64::INFINITY, f64::min);
    let max_x1 = words.iter().map(|w| w.x1).fold(f64::NEG_INFINITY, f64::max);

    let mut edges = Vec::new();
    for indices in &large_clusters {
        let cluster_words: Vec<&super::table_clustering::PositionedWord> = indices.iter().map(|&i| &words[i]).collect();
        let cluster_top = cluster_words.iter().map(|w| w.top).fold(f64::INFINITY, f64::min);
        let cluster_bottom = cluster_words.iter().map(|w| w.bottom).fold(f64::NEG_INFINITY, f64::max);

        // Top edge of text row
        edges.push(Edge::horizontal(min_x0, max_x1, cluster_top, EdgeType::Line));
        // Bottom edge of text row
        edges.push(Edge::horizontal(min_x0, max_x1, cluster_bottom, EdgeType::Line));
    }

    edges
}

/// Find vertical edges from word positions (text strategy).
///
/// Finds imaginary vertical lines that connect the left, right, or center
/// of at least `word_threshold` words.
pub fn words_to_edges_v(words: &[super::table_clustering::PositionedWord], word_threshold: usize) -> Vec<Edge> {
    use super::table_clustering::cluster_list;
    use super::table_geometry::get_bbox_overlap;

    if words.is_empty() {
        return Vec::new();
    }

    // Find words that share left, right, or center x-coordinates
    let x0s: Vec<f64> = words.iter().map(|w| w.x0).collect();
    let x1s: Vec<f64> = words.iter().map(|w| w.x1).collect();
    let centers: Vec<f64> = words.iter().map(|w| w.center_x()).collect();

    let mut all_clusters: Vec<(f64, Vec<usize>)> = Vec::new();

    for values in [&x0s, &x1s, &centers] {
        let clusters = cluster_list(values, 1.0);
        for cluster in &clusters {
            let indices: Vec<usize> = words
                .iter()
                .enumerate()
                .filter(|(_, w)| {
                    let val = if std::ptr::eq(values, &x0s) {
                        w.x0
                    } else if std::ptr::eq(values, &x1s) {
                        w.x1
                    } else {
                        w.center_x()
                    };
                    cluster.iter().any(|&c| (val - c).abs() < 1.0)
                })
                .map(|(i, _)| i)
                .collect();
            if indices.len() >= word_threshold {
                let avg_x = cluster.iter().sum::<f64>() / cluster.len() as f64;
                all_clusters.push((avg_x, indices));
            }
        }
    }

    // Sort by number of words (descending), then deduplicate overlapping
    all_clusters.sort_by(|a, b| b.1.len().cmp(&a.1.len()));

    let mut condensed_bboxes: Vec<(f64, f64, f64, f64)> = Vec::new();
    let mut kept_x_values: Vec<f64> = Vec::new();

    for (avg_x, indices) in &all_clusters {
        let min_top = indices.iter().map(|&i| words[i].top).fold(f64::INFINITY, f64::min);
        let max_bottom = indices
            .iter()
            .map(|&i| words[i].bottom)
            .fold(f64::NEG_INFINITY, f64::max);
        let bbox = (*avg_x - 0.5, min_top, *avg_x + 0.5, max_bottom);

        let overlaps = condensed_bboxes.iter().any(|&cb| get_bbox_overlap(bbox, cb).is_some());
        if !overlaps {
            condensed_bboxes.push(bbox);
            kept_x_values.push(*avg_x);
        }
    }

    if condensed_bboxes.is_empty() {
        return Vec::new();
    }

    kept_x_values.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let min_top = condensed_bboxes.iter().map(|b| b.1).fold(f64::INFINITY, f64::min);
    let max_bottom = condensed_bboxes.iter().map(|b| b.3).fold(f64::NEG_INFINITY, f64::max);

    // Add right-most edge from the furthest x1
    let max_x1 = words.iter().map(|w| w.x1).fold(f64::NEG_INFINITY, f64::max);

    let mut edges: Vec<Edge> = kept_x_values
        .iter()
        .map(|&x| Edge::vertical(x, min_top, max_bottom, EdgeType::Line))
        .collect();

    edges.push(Edge::vertical(max_x1, min_top, max_bottom, EdgeType::Line));

    edges
}

#[cfg(test)]
mod tests {
    use super::super::table_geometry::Orientation;
    use super::*;

    #[test]
    fn test_line_to_edge_horizontal() {
        let edge = line_to_edge(10.0, 50.0, 100.0, 50.0, EdgeType::Line);
        assert!(edge.is_some());
        let e = edge.unwrap();
        assert_eq!(e.orientation, Orientation::Horizontal);
        assert_eq!(e.x0, 10.0);
        assert_eq!(e.x1, 100.0);
        assert_eq!(e.edge_type, EdgeType::Line);
    }

    #[test]
    fn test_line_to_edge_vertical() {
        let edge = line_to_edge(50.0, 10.0, 50.0, 100.0, EdgeType::Line);
        assert!(edge.is_some());
        let e = edge.unwrap();
        assert_eq!(e.orientation, Orientation::Vertical);
        assert_eq!(e.top, 10.0);
        assert_eq!(e.bottom, 100.0);
    }

    #[test]
    fn test_line_to_edge_diagonal() {
        let edge = line_to_edge(10.0, 10.0, 100.0, 100.0, EdgeType::Line);
        assert!(edge.is_none());
    }

    #[test]
    fn test_line_to_edge_nearly_horizontal() {
        let edge = line_to_edge(10.0, 50.0, 100.0, 50.8, EdgeType::Line);
        assert!(edge.is_some());
        assert_eq!(edge.unwrap().orientation, Orientation::Horizontal);
    }

    #[test]
    fn test_line_to_edge_preserves_curve_type() {
        let edge = line_to_edge(10.0, 50.0, 100.0, 50.0, EdgeType::CurveEdge);
        assert!(edge.is_some());
        assert_eq!(edge.unwrap().edge_type, EdgeType::CurveEdge);
    }

    #[test]
    fn test_line_to_edge_preserves_rect_type() {
        let edge = line_to_edge(50.0, 10.0, 50.0, 100.0, EdgeType::RectEdge);
        assert!(edge.is_some());
        assert_eq!(edge.unwrap().edge_type, EdgeType::RectEdge);
    }

    #[test]
    fn test_is_rectangular_path() {
        // Axis-aligned rectangle: 4 corners
        let rect_points = vec![(0.0, 0.0), (100.0, 0.0), (100.0, 50.0), (0.0, 50.0)];
        assert!(is_rectangular_path(&rect_points));

        // Non-rectangular (diagonal edge)
        let non_rect = vec![(0.0, 0.0), (100.0, 50.0), (100.0, 100.0), (0.0, 50.0)];
        assert!(!is_rectangular_path(&non_rect));

        // Too few points
        assert!(!is_rectangular_path(&[(0.0, 0.0), (10.0, 0.0)]));
    }

    #[test]
    fn test_words_to_edges_h_empty() {
        assert!(words_to_edges_h(&[], 1).is_empty());
    }

    #[test]
    fn test_words_to_edges_v_empty() {
        assert!(words_to_edges_v(&[], 3).is_empty());
    }

    #[test]
    fn test_words_to_edges_h_basic() {
        use super::super::table_clustering::PositionedWord;
        let words = vec![
            PositionedWord {
                text: "a".into(),
                x0: 10.0,
                x1: 30.0,
                top: 50.0,
                bottom: 60.0,
            },
            PositionedWord {
                text: "b".into(),
                x0: 40.0,
                x1: 60.0,
                top: 50.0,
                bottom: 60.0,
            },
            PositionedWord {
                text: "c".into(),
                x0: 10.0,
                x1: 30.0,
                top: 100.0,
                bottom: 110.0,
            },
            PositionedWord {
                text: "d".into(),
                x0: 40.0,
                x1: 60.0,
                top: 100.0,
                bottom: 110.0,
            },
        ];
        let edges = words_to_edges_h(&words, 1);
        // Should produce 2 horizontal lines (top and bottom of each row)
        assert!(!edges.is_empty());
        assert!(edges.iter().all(|e| e.orientation == Orientation::Horizontal));
    }
}
