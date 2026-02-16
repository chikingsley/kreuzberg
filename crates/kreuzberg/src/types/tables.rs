//! Table-related types for document extraction.

use serde::{Deserialize, Serialize};

/// Extracted table structure.
///
/// Represents a table detected and extracted from a document (PDF, image, etc.).
/// Tables are converted to both structured cell data and Markdown format.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "api", derive(utoipa::ToSchema))]
pub struct Table {
    /// Table cells as a 2D vector (rows × columns)
    pub cells: Vec<Vec<String>>,
    /// Markdown representation of the table (with inline style formatting)
    pub markdown: String,
    /// Page number where the table was found (1-indexed)
    pub page_number: usize,
    /// Detected table header information.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub header: Option<TableHeader>,
}

/// Detected table header information.
///
/// Identifies which row(s) constitute the table header and provides
/// metadata about how the header was detected.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "api", derive(utoipa::ToSchema))]
pub struct TableHeader {
    /// Column header names extracted from the header row.
    pub names: Vec<String>,
    /// Whether the header is external (above the table body, not part of it).
    ///
    /// When `false`, the header is the first row of the table.
    /// When `true`, the header text was found above the table's bounding box.
    pub external: bool,
    /// Index of the header row in the `cells` array (0 for first row).
    pub row_index: usize,
}

/// Individual table cell with content and optional styling.
///
/// Future extension point for rich table support with cell-level metadata.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "api", derive(utoipa::ToSchema))]
pub struct TableCell {
    /// Cell content as text
    pub content: String,
    /// Row span (number of rows this cell spans)
    #[serde(default = "default_span")]
    pub row_span: usize,
    /// Column span (number of columns this cell spans)
    #[serde(default = "default_span")]
    pub col_span: usize,
    /// Whether this is a header cell
    #[serde(default)]
    pub is_header: bool,
}

impl Table {
    /// Convert the table to CSV format.
    ///
    /// Properly escapes cells containing commas, double quotes, or newlines
    /// per RFC 4180.
    pub fn to_csv(&self) -> String {
        let mut csv = String::new();
        for row in &self.cells {
            for (i, cell) in row.iter().enumerate() {
                if i > 0 {
                    csv.push(',');
                }
                let needs_quoting = cell.contains(',') || cell.contains('"') || cell.contains('\n');
                if needs_quoting {
                    csv.push('"');
                    csv.push_str(&cell.replace('"', "\"\""));
                    csv.push('"');
                } else {
                    csv.push_str(cell);
                }
            }
            csv.push('\n');
        }
        csv
    }

    /// Number of rows in the table.
    pub fn row_count(&self) -> usize {
        self.cells.len()
    }

    /// Number of columns in the table (based on the first row).
    pub fn col_count(&self) -> usize {
        self.cells.first().map(|r| r.len()).unwrap_or(0)
    }
}

fn default_span() -> usize {
    1
}
