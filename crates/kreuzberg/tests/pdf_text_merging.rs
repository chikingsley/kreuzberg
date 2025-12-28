//! Tests for PDF text extraction with font information and bounding box operations.
//!
//! This module tests character extraction functionality following TDD principles,
//! verifying that characters are extracted with positions and font sizes,
//! and that bounding box operations work correctly.

#![cfg(feature = "pdf")]

mod helpers;

use helpers::get_test_file_path;
use kreuzberg::pdf::hierarchy::{BoundingBox, extract_chars_with_fonts};
use pdfium_render::prelude::*;

// ============================================================================
// Character Extraction Tests (Following TDD)
// ============================================================================

/// Test basic character extraction with positions and font sizes.
///
/// Verifies that:
/// - Characters are extracted with their positions
/// - Font sizes are captured
/// - Position order is preserved
#[test]
fn test_extract_chars_basic() {
    let pdf_path = get_test_file_path("pdfs_with_tables/tiny.pdf");

    // Load PDF
    let pdfium = Pdfium::default();
    let document = pdfium
        .load_pdf_from_file(pdf_path.to_str().unwrap(), None)
        .expect("Failed to load test PDF");

    // Get first page
    let page = document.pages().get(0).expect("Failed to get first page");

    // Extract characters with fonts
    let chars = extract_chars_with_fonts(&page).expect("Failed to extract characters with fonts");

    // Verify we got some characters
    assert!(!chars.is_empty(), "Should extract at least one character from test PDF");

    // Verify each character has required fields
    for char_data in chars.iter() {
        assert!(!char_data.text.is_empty(), "Character text should not be empty");
        assert!(char_data.font_size > 0.0, "Font size should be positive");
        assert!(char_data.x >= 0.0, "X position should be non-negative");
        assert!(char_data.y >= 0.0, "Y position should be non-negative");
    }
}

/// Test that character extraction preserves reading order.
///
/// Verifies that:
/// - Characters appear in left-to-right order
/// - Y-coordinates generally decrease as we move down the page
#[test]
fn test_extract_chars_preserves_order() {
    let pdf_path = get_test_file_path("pdfs_with_tables/tiny.pdf");

    // Load PDF
    let pdfium = Pdfium::default();
    let document = pdfium
        .load_pdf_from_file(pdf_path.to_str().unwrap(), None)
        .expect("Failed to load test PDF");

    // Get first page
    let page = document.pages().get(0).expect("Failed to get first page");

    // Extract characters with fonts
    let chars = extract_chars_with_fonts(&page).expect("Failed to extract characters with fonts");

    assert!(!chars.is_empty(), "Should extract at least one character");

    // Within each line (similar y-coordinate), characters should be left-to-right
    let mut last_y = f32::NEG_INFINITY;
    let mut last_x = f32::NEG_INFINITY;
    let y_line_threshold = 5.0; // Consider within 5 units as same line

    for char_data in chars.iter() {
        // If we're on a new line
        if (char_data.y - last_y).abs() > y_line_threshold {
            last_x = f32::NEG_INFINITY;
            last_y = char_data.y;
        }

        // On same line, x should generally increase (allowing for small variations)
        // We use a threshold to allow for measurement precision issues
        if (char_data.y - last_y).abs() <= y_line_threshold && char_data.x < last_x - 1.0 {
            // This is acceptable if it's a new line or small variation
            if last_x != f32::NEG_INFINITY && (char_data.y - last_y).abs() <= y_line_threshold {
                assert!(
                    false,
                    "Characters should be left-to-right on same line: {} < {} at y={}",
                    char_data.x, last_x, char_data.y
                );
            }
        }

        last_x = char_data.x;
        last_y = char_data.y;
    }
}

// ============================================================================
// Bounding Box Tests
// ============================================================================

/// Helper function to create a BoundingBox from x, y, width, height
fn create_bbox(x: f32, y: f32, width: f32, height: f32) -> BoundingBox {
    BoundingBox {
        left: x,
        top: y,
        right: x + width,
        bottom: y + height,
    }
}

#[test]
fn test_iou_calculation() {
    // Two overlapping boxes
    let bbox1 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox2 = create_bbox(5.0, 5.0, 10.0, 10.0);

    // Expected intersection: 5x5 = 25
    // Expected union: 100 + 100 - 25 = 175
    // Expected IOU: 25/175 ≈ 0.1429
    let iou = bbox1.iou(&bbox2);
    assert!((iou - 0.1429).abs() < 0.001, "IOU calculation failed");
}

#[test]
fn test_weighted_distance_calculation() {
    // Two boxes with different X and Y distances
    let bbox1 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox2 = create_bbox(20.0, 5.0, 10.0, 10.0);

    // Distance: X=20, Y=5
    // Weighted: X*5.0 + Y*1.0 = 20*5.0 + 5*1.0 = 100 + 5 = 105
    let weighted_dist = bbox1.weighted_distance(&bbox2);
    assert!(
        (weighted_dist - 105.0).abs() < 0.001,
        "Weighted distance calculation failed"
    );

    // Verify X weight (5.0) > Y weight (1.0) by checking ratio
    let bbox3 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox4 = create_bbox(10.0, 0.0, 10.0, 10.0);
    let only_x_dist = bbox3.weighted_distance(&bbox4);

    let bbox5 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox6 = create_bbox(0.0, 10.0, 10.0, 10.0);
    let only_y_dist = bbox5.weighted_distance(&bbox6);

    // X distance of 10 with weight 5.0 = 50
    // Y distance of 10 with weight 1.0 = 10
    // X weight should be 5x larger than Y weight
    assert!(only_x_dist > only_y_dist, "X weight should be greater than Y weight");
    assert!((only_x_dist - 50.0).abs() < 0.001, "X-only weighted distance failed");
    assert!((only_y_dist - 10.0).abs() < 0.001, "Y-only weighted distance failed");
}

#[test]
fn test_intersection_ratio() {
    // Two overlapping boxes
    let bbox1 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox2 = create_bbox(5.0, 5.0, 10.0, 10.0);

    // Expected intersection: 5x5 = 25
    // bbox1 area: 100
    // Expected ratio: 25/100 = 0.25
    let ratio = bbox1.intersection_ratio(&bbox2);
    assert!((ratio - 0.25).abs() < 0.001, "Intersection ratio calculation failed");
}

#[test]
fn test_edge_case_no_overlap() {
    // Two non-overlapping boxes
    let bbox1 = create_bbox(0.0, 0.0, 10.0, 10.0);
    let bbox2 = create_bbox(20.0, 20.0, 10.0, 10.0);

    // IOU should be 0
    let iou = bbox1.iou(&bbox2);
    assert!((iou - 0.0).abs() < 0.001, "Non-overlapping boxes should have IOU of 0");

    // Intersection ratio should be 0
    let ratio = bbox1.intersection_ratio(&bbox2);
    assert!(
        (ratio - 0.0).abs() < 0.001,
        "Non-overlapping boxes should have intersection ratio of 0"
    );
}

#[test]
fn test_edge_case_fully_contained() {
    // Smaller box fully contained in larger box
    let bbox_large = create_bbox(0.0, 0.0, 20.0, 20.0);
    let bbox_small = create_bbox(5.0, 5.0, 10.0, 10.0);

    // Intersection: 10x10 = 100
    // Union: 400 + 100 - 100 = 400
    // IOU: 100/400 = 0.25
    let iou = bbox_large.iou(&bbox_small);
    assert!((iou - 0.25).abs() < 0.001, "Fully contained box IOU calculation failed");

    // Intersection ratio: 100/400 = 0.25
    let ratio = bbox_large.intersection_ratio(&bbox_small);
    assert!(
        (ratio - 0.25).abs() < 0.001,
        "Fully contained box intersection ratio failed"
    );
}

// ============================================================================
// Character Merging Tests (Following TDD)
// ============================================================================

use kreuzberg::pdf::hierarchy::{CharData, merge_chars_into_blocks};

/// Factory helper to create a CharData with minimal parameters.
fn create_char(text: &str, x: f32, y: f32, font_size: f32) -> CharData {
    CharData {
        text: text.to_string(),
        font_size,
        x,
        y,
        width: font_size * 0.6,
        height: font_size,
    }
}

/// Test horizontal text merging: characters at (0,10), (10,10), (20,10) should merge into 1 block.
///
/// This test validates that characters on the same horizontal line and within the merge
/// distance threshold are grouped into a single text block.
#[test]
fn test_merge_horizontal_text_merging() {
    let chars = vec![
        create_char("H", 0.0, 10.0, 12.0),
        create_char("e", 10.0, 10.0, 12.0),
        create_char("y", 20.0, 10.0, 12.0),
    ];

    let blocks = merge_chars_into_blocks(chars);

    assert_eq!(blocks.len(), 1, "Expected 1 block for horizontal text");
    assert_eq!(blocks[0].text, "Hey", "Expected merged text 'Hey'");
}

/// Test vertical text separation: characters at (0,10) and (0,50) should be 2 blocks.
///
/// This test validates that characters with large vertical separation are kept in separate blocks.
#[test]
fn test_merge_vertical_text_separation() {
    let chars = vec![create_char("A", 0.0, 10.0, 12.0), create_char("B", 0.0, 50.0, 12.0)];

    let blocks = merge_chars_into_blocks(chars);

    assert_eq!(blocks.len(), 2, "Expected 2 blocks for vertically separated text");
    assert_eq!(blocks[0].text, "A", "Expected first block to contain 'A'");
    assert_eq!(blocks[1].text, "B", "Expected second block to contain 'B'");
}

/// Test edge case with negative coordinates.
///
/// This test ensures the merging algorithm handles negative coordinates correctly.
#[test]
fn test_merge_edge_case_negative_coordinates() {
    let chars = vec![
        create_char("X", -10.0, -5.0, 12.0),
        create_char("Y", 0.0, -5.0, 12.0),
        create_char("Z", 10.0, -5.0, 12.0),
    ];

    let blocks = merge_chars_into_blocks(chars);

    assert_eq!(blocks.len(), 1, "Expected 1 block for negative coordinates");
    assert_eq!(blocks[0].text, "XYZ", "Expected merged text 'XYZ'");
}

/// Test edge case with overlapping blocks.
///
/// This test validates behavior when characters have overlapping or very close bounding boxes.
#[test]
fn test_merge_edge_case_overlapping_blocks() {
    let chars = vec![
        create_char("O", 0.0, 0.0, 12.0),
        create_char("V", 1.0, 0.0, 12.0),
        create_char("E", 2.0, 0.0, 12.0),
    ];

    let blocks = merge_chars_into_blocks(chars);

    assert_eq!(blocks.len(), 1, "Expected 1 block for overlapping characters");
    assert_eq!(blocks[0].text, "OVE", "Expected merged text 'OVE'");
}

/// Test max merge distance threshold.
///
/// This test validates that characters beyond the maximum merge distance are kept separate.
#[test]
fn test_merge_max_merge_distance_threshold() {
    let chars = vec![
        create_char("T", 0.0, 10.0, 12.0),
        create_char("e", 50.0, 10.0, 12.0),  // Large gap, should be separate
        create_char("s", 100.0, 10.0, 12.0), // Even larger gap
    ];

    let blocks = merge_chars_into_blocks(chars);

    // With reasonable merge distance (should be ~2.5x font size for distance),
    // characters at 50 and 100 units apart should create separate blocks
    assert!(blocks.len() > 1, "Expected multiple blocks due to large gaps");
    assert_eq!(
        blocks.iter().map(|b| b.text.len()).sum::<usize>(),
        3,
        "Expected all 3 characters to be preserved"
    );
}
