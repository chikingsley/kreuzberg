//! Spatial clustering for table detection.
//!
//! Ported from pdfplumber's `utils/clustering.py`. Groups nearby values and objects
//! together based on a tolerance threshold.

use std::collections::HashMap;

/// Cluster a sorted list of numbers by proximity.
///
/// Values within `tolerance` of each other are grouped together.
/// Returns a list of clusters (each cluster is a sorted vec of values).
///
/// # Example
///
/// ```ignore
/// let clusters = cluster_list(&[1.0, 2.0, 5.0, 6.0, 10.0], 2.0);
/// // Returns: [[1.0, 2.0], [5.0, 6.0], [10.0]]
/// ```
pub fn cluster_list(xs: &[f64], tolerance: f64) -> Vec<Vec<f64>> {
    if xs.is_empty() {
        return Vec::new();
    }

    let mut sorted: Vec<f64> = xs.to_vec();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());

    if tolerance == 0.0 || sorted.len() < 2 {
        return sorted.into_iter().map(|x| vec![x]).collect();
    }

    let mut groups: Vec<Vec<f64>> = Vec::new();
    let mut current_group = vec![sorted[0]];
    let mut last = sorted[0];

    for &x in &sorted[1..] {
        if x <= last + tolerance {
            current_group.push(x);
        } else {
            groups.push(current_group);
            current_group = vec![x];
        }
        last = x;
    }
    groups.push(current_group);
    groups
}

/// Build a mapping from values to cluster indices.
///
/// Each unique value is assigned a cluster ID based on proximity clustering.
fn make_cluster_dict(values: &[f64], tolerance: f64) -> HashMap<u64, usize> {
    let mut unique: Vec<f64> = values.to_vec();
    unique.sort_by(|a, b| a.partial_cmp(b).unwrap());
    unique.dedup_by(|a, b| (*a - *b).abs() < f64::EPSILON);

    let clusters = cluster_list(&unique, tolerance);

    let mut dict = HashMap::new();
    for (cluster_id, cluster) in clusters.iter().enumerate() {
        for &val in cluster {
            dict.insert(val.to_bits(), cluster_id);
        }
    }
    dict
}

/// Cluster objects by a key function with a given tolerance.
///
/// Objects whose key values are within `tolerance` of each other are grouped together.
/// Returns groups of indices into the original slice.
pub fn cluster_objects_by<F>(objects: &[f64], key_fn: F, tolerance: f64) -> Vec<Vec<usize>>
where
    F: Fn(f64) -> f64,
{
    if objects.is_empty() {
        return Vec::new();
    }

    let values: Vec<f64> = objects.iter().map(|&o| key_fn(o)).collect();
    let cluster_dict = make_cluster_dict(&values, tolerance);

    // Group indices by cluster ID
    let mut groups: HashMap<usize, Vec<usize>> = HashMap::new();
    for (idx, val) in values.iter().enumerate() {
        if let Some(&cluster_id) = cluster_dict.get(&val.to_bits()) {
            groups.entry(cluster_id).or_default().push(idx);
        }
    }

    // Return sorted by cluster ID
    let mut sorted_groups: Vec<(usize, Vec<usize>)> = groups.into_iter().collect();
    sorted_groups.sort_by_key(|(k, _)| *k);
    sorted_groups.into_iter().map(|(_, v)| v).collect()
}

/// A word with position information for text-based table detection.
#[derive(Debug, Clone)]
pub struct PositionedWord {
    pub text: String,
    pub x0: f64,
    pub x1: f64,
    pub top: f64,
    pub bottom: f64,
}

impl PositionedWord {
    pub fn center_x(&self) -> f64 {
        (self.x0 + self.x1) / 2.0
    }
}

/// Cluster positioned words by their top coordinate.
pub fn cluster_words_by_top(words: &[PositionedWord], tolerance: f64) -> Vec<Vec<usize>> {
    if words.is_empty() {
        return Vec::new();
    }

    let tops: Vec<f64> = words.iter().map(|w| w.top).collect();
    cluster_objects_by(&tops, |t| t, tolerance)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cluster_list_basic() {
        let clusters = cluster_list(&[1.0, 2.0, 5.0, 6.0, 10.0], 1.5);
        assert_eq!(clusters.len(), 3);
        assert_eq!(clusters[0], vec![1.0, 2.0]);
        assert_eq!(clusters[1], vec![5.0, 6.0]);
        assert_eq!(clusters[2], vec![10.0]);
    }

    #[test]
    fn test_cluster_list_all_close() {
        let clusters = cluster_list(&[1.0, 2.0, 3.0], 2.0);
        assert_eq!(clusters.len(), 1);
        assert_eq!(clusters[0], vec![1.0, 2.0, 3.0]);
    }

    #[test]
    fn test_cluster_list_all_separate() {
        let clusters = cluster_list(&[1.0, 10.0, 20.0], 1.0);
        assert_eq!(clusters.len(), 3);
    }

    #[test]
    fn test_cluster_list_empty() {
        let clusters: Vec<Vec<f64>> = cluster_list(&[], 1.0);
        assert!(clusters.is_empty());
    }

    #[test]
    fn test_cluster_list_single() {
        let clusters = cluster_list(&[5.0], 1.0);
        assert_eq!(clusters.len(), 1);
        assert_eq!(clusters[0], vec![5.0]);
    }

    #[test]
    fn test_cluster_list_zero_tolerance() {
        let clusters = cluster_list(&[1.0, 2.0, 3.0], 0.0);
        assert_eq!(clusters.len(), 3);
    }

    #[test]
    fn test_cluster_objects_by() {
        let values = vec![1.0, 2.0, 10.0, 11.0, 20.0];
        let groups = cluster_objects_by(&values, |x| x, 2.0);
        assert_eq!(groups.len(), 3);
        // First cluster: indices 0, 1
        assert!(groups[0].contains(&0));
        assert!(groups[0].contains(&1));
        // Second cluster: indices 2, 3
        assert!(groups[1].contains(&2));
        assert!(groups[1].contains(&3));
        // Third cluster: index 4
        assert!(groups[2].contains(&4));
    }

    #[test]
    fn test_cluster_words_by_top() {
        let words = vec![
            PositionedWord {
                text: "hello".into(),
                x0: 0.0,
                x1: 50.0,
                top: 10.0,
                bottom: 20.0,
            },
            PositionedWord {
                text: "world".into(),
                x0: 60.0,
                x1: 110.0,
                top: 11.0,
                bottom: 21.0,
            },
            PositionedWord {
                text: "foo".into(),
                x0: 0.0,
                x1: 30.0,
                top: 50.0,
                bottom: 60.0,
            },
        ];
        let clusters = cluster_words_by_top(&words, 2.0);
        assert_eq!(clusters.len(), 2);
        assert_eq!(clusters[0].len(), 2); // hello + world
        assert_eq!(clusters[1].len(), 1); // foo
    }
}
