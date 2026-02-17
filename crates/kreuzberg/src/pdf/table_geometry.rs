//! Geometry utilities for PDF table detection.
//!
//! Ported from pdfplumber's `utils/geometry.py`. Provides bounding box operations,
//! edge manipulation, and spatial snapping for table border detection.

use std::collections::{BTreeMap, HashSet};

/// A bounding box: (x0, top, x1, bottom).
pub type Bbox = (f64, f64, f64, f64);

/// Orientation of an edge (horizontal or vertical).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Orientation {
    Horizontal,
    Vertical,
}

/// The source type of an edge.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EdgeType {
    Line,
    RectEdge,
    CurveEdge,
}

/// A geometric edge extracted from PDF drawing objects.
#[derive(Debug, Clone)]
pub struct Edge {
    pub x0: f64,
    pub x1: f64,
    pub top: f64,
    pub bottom: f64,
    pub width: f64,
    pub height: f64,
    pub orientation: Orientation,
    pub edge_type: EdgeType,
}

impl Edge {
    /// Create a horizontal edge.
    pub fn horizontal(x0: f64, x1: f64, y: f64, edge_type: EdgeType) -> Self {
        Self {
            x0,
            x1,
            top: y,
            bottom: y,
            width: x1 - x0,
            height: 0.0,
            orientation: Orientation::Horizontal,
            edge_type,
        }
    }

    /// Create a vertical edge.
    pub fn vertical(x: f64, top: f64, bottom: f64, edge_type: EdgeType) -> Self {
        Self {
            x0: x,
            x1: x,
            top,
            bottom,
            width: 0.0,
            height: bottom - top,
            orientation: Orientation::Vertical,
            edge_type,
        }
    }

    /// Get the bounding box of this edge.
    pub fn bbox(&self) -> Bbox {
        (self.x0, self.top, self.x1, self.bottom)
    }

    /// Get the length of this edge (width for horizontal, height for vertical).
    pub fn length(&self) -> f64 {
        match self.orientation {
            Orientation::Horizontal => self.width,
            Orientation::Vertical => self.height,
        }
    }

    /// Get the primary coordinate used for snapping/grouping.
    /// For horizontal edges, this is `top`. For vertical, this is `x0`.
    pub fn primary_coord(&self) -> f64 {
        match self.orientation {
            Orientation::Horizontal => self.top,
            Orientation::Vertical => self.x0,
        }
    }

    /// Set the primary coordinate, adjusting related fields.
    pub fn set_primary_coord(&mut self, value: f64) {
        match self.orientation {
            Orientation::Horizontal => {
                self.top = value;
                self.bottom = value;
            }
            Orientation::Vertical => {
                self.x0 = value;
                self.x1 = value;
            }
        }
    }
}

/// Convert a rectangle to its 4 constituent edges.
pub fn rect_to_edges(x0: f64, top: f64, x1: f64, bottom: f64) -> Vec<Edge> {
    vec![
        Edge::horizontal(x0, x1, top, EdgeType::RectEdge),
        Edge::horizontal(x0, x1, bottom, EdgeType::RectEdge),
        Edge::vertical(x0, top, bottom, EdgeType::RectEdge),
        Edge::vertical(x1, top, bottom, EdgeType::RectEdge),
    ]
}

/// Merge multiple bounding boxes into the smallest containing bbox.
pub fn merge_bboxes(bboxes: &[Bbox]) -> Option<Bbox> {
    bboxes
        .iter()
        .copied()
        .reduce(|(x0, top, x1, bottom), (bx0, btop, bx1, bbottom)| {
            (x0.min(bx0), top.min(btop), x1.max(bx1), bottom.max(bbottom))
        })
}

/// Check if two bounding boxes overlap. Returns the overlap bbox if they do.
pub fn get_bbox_overlap(a: Bbox, b: Bbox) -> Option<Bbox> {
    let o_left = a.0.max(b.0);
    let o_top = a.1.max(b.1);
    let o_right = a.2.min(b.2);
    let o_bottom = a.3.min(b.3);
    let o_width = o_right - o_left;
    let o_height = o_bottom - o_top;
    if o_height >= 0.0 && o_width >= 0.0 && (o_height + o_width) > 0.0 {
        Some((o_left, o_top, o_right, o_bottom))
    } else {
        None
    }
}

/// Filter edges by orientation, edge type, and minimum length.
pub fn filter_edges(
    edges: &[Edge],
    orientation: Option<Orientation>,
    edge_type: Option<EdgeType>,
    min_length: f64,
) -> Vec<Edge> {
    edges
        .iter()
        .filter(|e| {
            orientation.is_none_or(|o| e.orientation == o)
                && edge_type.is_none_or(|t| e.edge_type == t)
                && e.length() >= min_length
        })
        .cloned()
        .collect()
}

/// Snap edges along their primary coordinate using clustering.
///
/// Edges within `tolerance` of each other are snapped to their average position.
pub fn snap_edges(edges: Vec<Edge>, x_tolerance: f64, y_tolerance: f64) -> Vec<Edge> {
    use super::table_clustering::cluster_list;

    let mut v_edges: Vec<Edge> = Vec::new();
    let mut h_edges: Vec<Edge> = Vec::new();

    for e in edges {
        match e.orientation {
            Orientation::Vertical => v_edges.push(e),
            Orientation::Horizontal => h_edges.push(e),
        }
    }

    // Snap vertical edges by x0
    if x_tolerance > 0.0 && !v_edges.is_empty() {
        let x_values: Vec<f64> = v_edges.iter().map(|e| e.x0).collect();
        let clusters = cluster_list(&x_values, x_tolerance);
        let mut snapped = Vec::new();
        for cluster in &clusters {
            let avg: f64 = cluster.iter().sum::<f64>() / cluster.len() as f64;
            let cluster_set: HashSet<u64> = cluster.iter().map(|v| v.to_bits()).collect();
            for mut edge in v_edges.iter().cloned() {
                if cluster_set.contains(&edge.x0.to_bits()) {
                    edge.set_primary_coord(avg);
                    snapped.push(edge);
                }
            }
        }
        v_edges = snapped;
    }

    // Snap horizontal edges by top
    if y_tolerance > 0.0 && !h_edges.is_empty() {
        let y_values: Vec<f64> = h_edges.iter().map(|e| e.top).collect();
        let clusters = cluster_list(&y_values, y_tolerance);
        let mut snapped = Vec::new();
        for cluster in &clusters {
            let avg: f64 = cluster.iter().sum::<f64>() / cluster.len() as f64;
            let cluster_set: HashSet<u64> = cluster.iter().map(|v| v.to_bits()).collect();
            for mut edge in h_edges.iter().cloned() {
                if cluster_set.contains(&edge.top.to_bits()) {
                    edge.set_primary_coord(avg);
                    snapped.push(edge);
                }
            }
        }
        h_edges = snapped;
    }

    v_edges.extend(h_edges);
    v_edges
}

/// Join collinear edge segments that are within `tolerance` of each other.
///
/// Given edges along the same infinite line, merge overlapping or close segments.
pub fn join_edge_group(edges: &[Edge], tolerance: f64) -> Vec<Edge> {
    if edges.is_empty() {
        return Vec::new();
    }

    let orientation = edges[0].orientation;
    let mut sorted = edges.to_vec();

    match orientation {
        Orientation::Horizontal => sorted.sort_by(|a, b| a.x0.partial_cmp(&b.x0).unwrap()),
        Orientation::Vertical => sorted.sort_by(|a, b| a.top.partial_cmp(&b.top).unwrap()),
    }

    let mut joined = vec![sorted[0].clone()];

    for e in &sorted[1..] {
        let last = joined.last_mut().unwrap();
        match orientation {
            Orientation::Horizontal => {
                if e.x0 <= last.x1 + tolerance {
                    if e.x1 > last.x1 {
                        last.x1 = e.x1;
                        last.width = last.x1 - last.x0;
                    }
                } else {
                    joined.push(e.clone());
                }
            }
            Orientation::Vertical => {
                if e.top <= last.bottom + tolerance {
                    if e.bottom > last.bottom {
                        last.bottom = e.bottom;
                        last.height = last.bottom - last.top;
                    }
                } else {
                    joined.push(e.clone());
                }
            }
        }
    }

    joined
}

/// Merge edges by snapping nearby edges and joining collinear segments.
///
/// This is the main edge preprocessing step that produces clean, deduplicated edges.
pub fn merge_edges(
    edges: Vec<Edge>,
    snap_x_tolerance: f64,
    snap_y_tolerance: f64,
    join_x_tolerance: f64,
    join_y_tolerance: f64,
) -> Vec<Edge> {
    let edges = if snap_x_tolerance > 0.0 || snap_y_tolerance > 0.0 {
        snap_edges(edges, snap_x_tolerance, snap_y_tolerance)
    } else {
        edges
    };

    // Group edges by (orientation, primary_coord) and join each group
    let mut groups: BTreeMap<(u8, u64), Vec<Edge>> = BTreeMap::new();

    for edge in &edges {
        let orient_key = edge.orientation == Orientation::Vertical;
        let coord_key = edge.primary_coord().to_bits();
        groups
            .entry((orient_key as u8, coord_key))
            .or_default()
            .push(edge.clone());
    }

    let mut result = Vec::new();
    for ((orient_key, _), group) in &groups {
        let tolerance = if *orient_key == 0 {
            join_x_tolerance
        } else {
            join_y_tolerance
        };
        result.extend(join_edge_group(group, tolerance));
    }

    result
}

/// Check whether two rectangles are neighbors (within snap tolerance).
///
/// Two rectangles are considered neighbors if the minimum distance between
/// any of their corner points is not larger than the snap tolerance.
/// This is used for joining vector graphics that form table borders.
pub fn are_neighbors(r1: Bbox, r2: Bbox, snap_x: f64, snap_y: f64) -> bool {
    // Check if any corner of r1 falls within the extended bounds of r2
    let check = |r_a: Bbox, r_b: Bbox| -> bool {
        let x_in_range = |x: f64| r_b.0 - snap_x <= x && x <= r_b.2 + snap_x;
        let y_in_range = |y: f64| r_b.1 - snap_y <= y && y <= r_b.3 + snap_y;

        // Check all 4 corners of r_a against the extended bounds of r_b
        (x_in_range(r_a.0) || x_in_range(r_a.2)) && (y_in_range(r_a.1) || y_in_range(r_a.3))
    };

    check(r1, r2) || check(r2, r1)
}

/// Join neighboring rectangles into unified bounding regions.
///
/// Iteratively merges adjacent rectangles that are within the snap tolerance,
/// forming larger bounding regions that represent table boundaries.
/// Only keeps regions that satisfy the provided predicate (e.g., "contains text").
///
/// This mirrors PyMuPDF's `clean_graphics` algorithm.
pub fn join_neighboring_rects<F>(rects: &[Bbox], snap_x: f64, snap_y: f64, keep_predicate: F) -> Vec<Bbox>
where
    F: Fn(Bbox) -> bool,
{
    if rects.is_empty() {
        return Vec::new();
    }

    let mut remaining: Vec<Bbox> = rects.to_vec();
    let mut result = Vec::new();

    while !remaining.is_empty() {
        let mut current = remaining.remove(0);
        let mut changed = true;

        // Keep extending the current rect by absorbing neighbors
        while changed {
            changed = false;
            let mut i = 0;
            while i < remaining.len() {
                if are_neighbors(current, remaining[i], snap_x, snap_y) {
                    // Merge: extend current to include the neighbor
                    let neighbor = remaining.remove(i);
                    current.0 = current.0.min(neighbor.0);
                    current.1 = current.1.min(neighbor.1);
                    current.2 = current.2.max(neighbor.2);
                    current.3 = current.3.max(neighbor.3);
                    changed = true;
                } else {
                    i += 1;
                }
            }
        }

        if keep_predicate(current) {
            result.push(current);
        }
    }

    result
}

/// Clip edges to a bounding box region.
///
/// Edges entirely outside the clip region are removed.
/// Edges partially overlapping are trimmed to the clip boundaries.
pub fn clip_edges(edges: Vec<Edge>, clip: Bbox) -> Vec<Edge> {
    let (cx0, ctop, cx1, cbottom) = clip;
    edges
        .into_iter()
        .filter_map(|edge| match edge.orientation {
            Orientation::Horizontal => {
                // Horizontal edge at y=edge.top. Must be within vertical clip bounds.
                if edge.top < ctop || edge.top > cbottom {
                    return None;
                }
                let new_x0 = edge.x0.max(cx0);
                let new_x1 = edge.x1.min(cx1);
                if new_x0 >= new_x1 {
                    return None;
                }
                Some(Edge::horizontal(new_x0, new_x1, edge.top, edge.edge_type))
            }
            Orientation::Vertical => {
                // Vertical edge at x=edge.x0. Must be within horizontal clip bounds.
                if edge.x0 < cx0 || edge.x0 > cx1 {
                    return None;
                }
                let new_top = edge.top.max(ctop);
                let new_bottom = edge.bottom.min(cbottom);
                if new_top >= new_bottom {
                    return None;
                }
                Some(Edge::vertical(edge.x0, new_top, new_bottom, edge.edge_type))
            }
        })
        .collect()
}

/// Check if a point (x, y) is inside a bounding box.
pub fn point_in_bbox(x: f64, y: f64, bbox: Bbox) -> bool {
    x >= bbox.0 && x < bbox.2 && y >= bbox.1 && y < bbox.3
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_edge_horizontal() {
        let e = Edge::horizontal(10.0, 100.0, 50.0, EdgeType::Line);
        assert_eq!(e.orientation, Orientation::Horizontal);
        assert_eq!(e.length(), 90.0);
        assert_eq!(e.primary_coord(), 50.0);
    }

    #[test]
    fn test_edge_vertical() {
        let e = Edge::vertical(50.0, 10.0, 100.0, EdgeType::Line);
        assert_eq!(e.orientation, Orientation::Vertical);
        assert_eq!(e.length(), 90.0);
        assert_eq!(e.primary_coord(), 50.0);
    }

    #[test]
    fn test_rect_to_edges() {
        let edges = rect_to_edges(0.0, 0.0, 100.0, 50.0);
        assert_eq!(edges.len(), 4);
        let h_count = edges
            .iter()
            .filter(|e| e.orientation == Orientation::Horizontal)
            .count();
        let v_count = edges.iter().filter(|e| e.orientation == Orientation::Vertical).count();
        assert_eq!(h_count, 2);
        assert_eq!(v_count, 2);
    }

    #[test]
    fn test_merge_bboxes() {
        let bboxes = vec![(0.0, 0.0, 10.0, 10.0), (5.0, 5.0, 20.0, 20.0)];
        let merged = merge_bboxes(&bboxes).unwrap();
        assert_eq!(merged, (0.0, 0.0, 20.0, 20.0));
    }

    #[test]
    fn test_merge_bboxes_empty() {
        assert!(merge_bboxes(&[]).is_none());
    }

    #[test]
    fn test_get_bbox_overlap() {
        let a = (0.0, 0.0, 10.0, 10.0);
        let b = (5.0, 5.0, 15.0, 15.0);
        let overlap = get_bbox_overlap(a, b);
        assert!(overlap.is_some());
        assert_eq!(overlap.unwrap(), (5.0, 5.0, 10.0, 10.0));
    }

    #[test]
    fn test_get_bbox_no_overlap() {
        let a = (0.0, 0.0, 10.0, 10.0);
        let b = (20.0, 20.0, 30.0, 30.0);
        assert!(get_bbox_overlap(a, b).is_none());
    }

    #[test]
    fn test_filter_edges() {
        let edges = vec![
            Edge::horizontal(0.0, 100.0, 10.0, EdgeType::Line),
            Edge::vertical(50.0, 0.0, 100.0, EdgeType::RectEdge),
            Edge::horizontal(0.0, 2.0, 20.0, EdgeType::Line), // too short
        ];
        let filtered = filter_edges(&edges, Some(Orientation::Horizontal), None, 3.0);
        assert_eq!(filtered.len(), 1);
        assert_eq!(filtered[0].x0, 0.0);
        assert_eq!(filtered[0].x1, 100.0);
    }

    #[test]
    fn test_join_edge_group_horizontal() {
        let edges = vec![
            Edge::horizontal(0.0, 50.0, 10.0, EdgeType::Line),
            Edge::horizontal(48.0, 100.0, 10.0, EdgeType::Line),
            Edge::horizontal(200.0, 300.0, 10.0, EdgeType::Line),
        ];
        let joined = join_edge_group(&edges, 3.0);
        assert_eq!(joined.len(), 2);
        assert_eq!(joined[0].x0, 0.0);
        assert_eq!(joined[0].x1, 100.0);
        assert_eq!(joined[1].x0, 200.0);
    }

    #[test]
    fn test_join_edge_group_vertical() {
        let edges = vec![
            Edge::vertical(10.0, 0.0, 50.0, EdgeType::Line),
            Edge::vertical(10.0, 48.0, 100.0, EdgeType::Line),
        ];
        let joined = join_edge_group(&edges, 3.0);
        assert_eq!(joined.len(), 1);
        assert_eq!(joined[0].top, 0.0);
        assert_eq!(joined[0].bottom, 100.0);
    }

    #[test]
    fn test_are_neighbors_touching() {
        // Two rects sharing an edge
        let r1 = (0.0, 0.0, 50.0, 50.0);
        let r2 = (50.0, 0.0, 100.0, 50.0);
        assert!(are_neighbors(r1, r2, 3.0, 3.0));
    }

    #[test]
    fn test_are_neighbors_close() {
        // Two rects with a small gap (within tolerance)
        let r1 = (0.0, 0.0, 50.0, 50.0);
        let r2 = (52.0, 0.0, 100.0, 50.0);
        assert!(are_neighbors(r1, r2, 3.0, 3.0));
    }

    #[test]
    fn test_are_neighbors_far_apart() {
        let r1 = (0.0, 0.0, 50.0, 50.0);
        let r2 = (200.0, 200.0, 300.0, 300.0);
        assert!(!are_neighbors(r1, r2, 3.0, 3.0));
    }

    #[test]
    fn test_join_neighboring_rects() {
        let rects = vec![
            (0.0, 0.0, 50.0, 50.0),
            (50.0, 0.0, 100.0, 50.0),     // neighbor of first
            (200.0, 200.0, 300.0, 300.0), // far away
        ];
        let joined = join_neighboring_rects(&rects, 3.0, 3.0, |_| true);
        assert_eq!(joined.len(), 2);
        // First two should be merged
        assert_eq!(joined[0], (0.0, 0.0, 100.0, 50.0));
        // Third stays alone
        assert_eq!(joined[1], (200.0, 200.0, 300.0, 300.0));
    }

    #[test]
    fn test_join_neighboring_rects_chain() {
        // Three rects in a chain: A-B-C where A touches B and B touches C
        let rects = vec![
            (0.0, 0.0, 50.0, 50.0),
            (50.0, 0.0, 100.0, 50.0),
            (100.0, 0.0, 150.0, 50.0),
        ];
        let joined = join_neighboring_rects(&rects, 3.0, 3.0, |_| true);
        assert_eq!(joined.len(), 1);
        assert_eq!(joined[0], (0.0, 0.0, 150.0, 50.0));
    }

    #[test]
    fn test_join_neighboring_rects_with_predicate() {
        let rects = vec![(0.0, 0.0, 50.0, 50.0), (50.0, 0.0, 100.0, 50.0)];
        // Predicate rejects small rects
        let joined = join_neighboring_rects(&rects, 3.0, 3.0, |r| (r.2 - r.0) > 80.0);
        assert_eq!(joined.len(), 1); // Merged rect is 100 wide, passes predicate
    }
}
