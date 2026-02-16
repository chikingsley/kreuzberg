# Plan: Port pdfplumber's Table Detection to Kreuzberg (Rust)

## Overview

Port pdfplumber's line-intersection table detection algorithm from Python to Rust,
integrating it alongside kreuzberg's existing spatial-clustering approach. This gives
kreuzberg two table detection strategies:
- **"lines"** (new): Detects table borders from PDF path/line/rect objects → pdfplumber's approach
- **"text"** (existing): Clusters word positions spatially → current approach

## What We're Porting

From `pdfplumber/table.py` + `pdfplumber/utils/geometry.py` + `pdfplumber/utils/clustering.py`:

### Core Algorithm (5 stages)
1. **Edge extraction** — Get edges from PDF drawn lines, rects, curves via PDFium's `page.objects()`
2. **Edge merging** — Snap nearby edges together, join collinear segments
3. **Intersection finding** — Find where horizontal and vertical edges cross
4. **Cell construction** — From intersection points, find rectangular cells
5. **Table grouping** — Group contiguous cells into separate tables (supports multiple tables per page!)

### Utility Functions to Port
From `geometry.py`: `snap_objects`, `cluster_objects`, `objects_to_rect`, `objects_to_bbox`,
`get_bbox_overlap`, `bbox_to_rect`, `obj_to_bbox`, `resize_object`, `filter_edges`,
`obj_to_edges` (line_to_edge, rect_to_edges, curve_to_edges), `move_object`

From `clustering.py`: `cluster_list`, `make_cluster_dict`, `cluster_objects`

## File Structure

```
crates/kreuzberg/src/pdf/
├── table.rs                    # existing (keep: word extraction from chars)
├── table_finder.rs             # NEW: main TableFinder + strategies
├── table_geometry.rs           # NEW: bbox/edge/rect geometry utils
├── table_clustering.rs         # NEW: cluster_list, cluster_objects
└── table_edges.rs              # NEW: edge extraction from PDFium path objects
```

## Implementation Steps

### Step 1: Geometry utilities (`table_geometry.rs`)
Port bbox operations, edge filtering, snap/resize/move objects.
- `Bbox` type alias: `(f64, f64, f64, f64)` → (x0, top, x1, bottom)
- `Edge` struct with orientation, x0/x1/top/bottom/width/height
- `get_bbox_overlap()`, `merge_bboxes()`, `bbox_to_rect()`
- `snap_objects()`, `resize_object()`, `filter_edges()`
- `rect_to_edges()`, `line_to_edge()`, `curve_to_edges()`

### Step 2: Clustering (`table_clustering.rs`)
Port the clustering algorithm:
- `cluster_list(values, tolerance)` → groups of nearby values
- `make_cluster_dict(values, tolerance)` → value→cluster_id mapping
- `cluster_objects(objects, key_fn, tolerance)` → groups of objects

### Step 3: Edge extraction from PDFium (`table_edges.rs`)
NEW code (not in pdfplumber) to bridge PDFium's page objects to our Edge type:
- Iterate `page.objects()` from pdfium-render
- Convert PdfPagePathObject segments to edges (h/v lines)
- Convert rect objects to 4 edges
- Filter diagonal/curved segments (only keep h/v)

### Step 4: TableFinder (`table_finder.rs`)
Port the main algorithm:
- `TableSettings` struct with all configuration knobs
- `snap_edges()` + `join_edge_group()` + `merge_edges()`
- `edges_to_intersections()` — the key algorithm
- `intersections_to_cells()` — find rectangular cells from intersection points
- `cells_to_tables()` — group contiguous cells into separate tables
- `Table` struct with rows/columns/extract methods
- Strategy support: "lines", "lines_strict", "text", "explicit"

### Step 5: Integration
- Modify `extract_tables_from_document()` in `extractors/pdf/extraction.rs`
- Try line-based detection first (if page has edges), fall back to text-based
- Support multiple tables per page (current limit is 1)
- Add `TableStrategy` to config

### Step 6: Port pdfplumber tests
- Copy test PDFs from `pdfplumber-src/tests/pdfs/` into kreuzberg's test fixtures
- Port `test_table.py` assertions to Rust integration tests
- Key test cases:
  - `test_edges_strict` (lines_strict strategy)
  - `test_rows_and_columns` (cell extraction)
  - `test_text_tolerance` (text strategy)
  - `test_order` (multiple tables per page)
  - `test_table_curves` (curve-based borders)

## Key Differences from pdfplumber

1. **Edge source**: pdfplumber uses pdfminer.six's object model; we use PDFium's `page.objects()` API
2. **Language**: Python dicts → Rust structs (type-safe, faster)
3. **No `doctop`**: pdfplumber tracks document-level top offset; we work per-page only
4. **Text extraction**: For cell text, reuse kreuzberg's existing char-position extraction
5. **Output format**: Emit `Vec<Vec<String>>` cells + markdown (existing kreuzberg format)

## Configuration Additions

```rust
pub struct TableConfig {
    pub strategy: TableStrategy,        // Lines, LinesStrict, Text, Explicit
    pub snap_tolerance: f64,            // default: 3.0
    pub join_tolerance: f64,            // default: 3.0
    pub edge_min_length: f64,           // default: 3.0
    pub min_words_vertical: usize,      // default: 3 (for text strategy)
    pub min_words_horizontal: usize,    // default: 1 (for text strategy)
    pub intersection_tolerance: f64,    // default: 3.0
}
```

## Estimated Scope
- ~800-1000 lines of new Rust code across 4 new files
- ~200 lines of test code
- ~50 lines of integration/config changes
- pdfplumber is MIT licensed — port is legally clean
