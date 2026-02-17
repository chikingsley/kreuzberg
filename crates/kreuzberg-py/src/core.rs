//! Core extraction functions
//!
//! Provides both synchronous and asynchronous extraction functions for Python.

use crate::config::ExtractionConfig;
use crate::error::to_py_err;
use crate::types::ExtractionResult;
use pyo3::prelude::*;
use pyo3::types::PyList;

/// Extract format strings from ExtractionConfig before it's consumed.
fn extract_format_strings(config: &ExtractionConfig) -> (Option<String>, Option<String>) {
    let output_fmt = match config.inner.output_format {
        kreuzberg::core::config::formats::OutputFormat::Plain => Some("plain".to_string()),
        kreuzberg::core::config::formats::OutputFormat::Markdown => Some("markdown".to_string()),
        kreuzberg::core::config::formats::OutputFormat::Djot => Some("djot".to_string()),
        kreuzberg::core::config::formats::OutputFormat::Html => Some("html".to_string()),
        kreuzberg::core::config::formats::OutputFormat::Structured => Some("structured".to_string()),
    };
    let result_fmt = match config.inner.result_format {
        kreuzberg::types::OutputFormat::Unified => Some("unified".to_string()),
        kreuzberg::types::OutputFormat::ElementBased => Some("element_based".to_string()),
    };
    (output_fmt, result_fmt)
}

/// Extract a path string from Python input (str, pathlib.Path, or bytes).
///
/// Supports:
/// - `str`: Direct string paths
/// - `pathlib.Path`: Extracts via `__fspath__()` protocol
/// - `bytes`: UTF-8 decoded path bytes (Unix paths)
fn extract_path_string(path: &Bound<'_, PyAny>) -> PyResult<String> {
    if let Ok(s) = path.extract::<String>() {
        return Ok(s);
    }

    if let Ok(fspath) = path.call_method0("__fspath__")
        && let Ok(s) = fspath.extract::<String>()
    {
        return Ok(s);
    }

    if let Ok(b) = path.extract::<Vec<u8>>() {
        if let Ok(s) = String::from_utf8(b) {
            return Ok(s);
        }
        return Err(pyo3::exceptions::PyValueError::new_err(
            "Path bytes must be valid UTF-8",
        ));
    }

    Err(pyo3::exceptions::PyTypeError::new_err(
        "Path must be a string, pathlib.Path, or bytes",
    ))
}

/// Extract content from a file (synchronous).
///
/// Args:
///     path: Path to the file to extract (str or pathlib.Path)
///     mime_type: Optional MIME type hint (auto-detected if None)
///     config: Extraction configuration
///
/// Returns:
///     ExtractionResult with content, metadata, and tables
///
/// Raises:
///     ValueError: Invalid configuration or unsupported format
///     IOError: File access errors
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> from kreuzberg import extract_file_sync, ExtractionConfig
///     >>> result = extract_file_sync("document.pdf", None, ExtractionConfig())
///     >>> print(result.content)
///     >>> # Also works with pathlib.Path
///     >>> from pathlib import Path
///     >>> result = extract_file_sync(Path("document.pdf"), None, ExtractionConfig())
#[pyfunction]
#[pyo3(signature = (path, mime_type=None, config=ExtractionConfig::default()))]
pub fn extract_file_sync(
    py: Python,
    path: &Bound<'_, PyAny>,
    mime_type: Option<String>,
    config: ExtractionConfig,
) -> PyResult<ExtractionResult> {
    let path_str = extract_path_string(path)?;
    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config = config.into();

    // Release GIL during sync extraction - OSError/RuntimeError must bubble up ~keep
    let result = Python::detach(py, || {
        kreuzberg::extract_file_sync(&path_str, mime_type.as_deref(), &rust_config)
    })
    .map_err(to_py_err)?;

    ExtractionResult::from_rust(result, py, output_fmt, result_fmt)
}

/// Extract content from bytes (synchronous).
///
/// Args:
///     data: Bytes to extract (bytes or bytearray)
///     mime_type: MIME type of the data
///     config: Extraction configuration
///
/// Returns:
///     ExtractionResult with content, metadata, and tables
///
/// Raises:
///     ValueError: Invalid configuration or unsupported format
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> from kreuzberg import extract_bytes_sync, ExtractionConfig
///     >>> with open("document.pdf", "rb") as f:
///     ...     data = f.read()
///     >>> result = extract_bytes_sync(data, "application/pdf", ExtractionConfig())
///     >>> print(result.content)
#[pyfunction]
#[pyo3(signature = (data, mime_type, config=ExtractionConfig::default()))]
pub fn extract_bytes_sync(
    py: Python,
    data: Vec<u8>,
    mime_type: String,
    config: ExtractionConfig,
) -> PyResult<ExtractionResult> {
    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config = config.into();

    // Release GIL during extraction and result conversion - OSError/RuntimeError must bubble up ~keep
    let result =
        Python::detach(py, || kreuzberg::extract_bytes_sync(&data, &mime_type, &rust_config)).map_err(to_py_err)?;

    ExtractionResult::from_rust(result, py, output_fmt, result_fmt)
}

/// Batch extract content from multiple files (synchronous).
///
/// MIME types are auto-detected for each file.
///
/// Args:
///     paths: List of file paths to extract (str, pathlib.Path, or bytes)
///     config: Extraction configuration
///
/// Returns:
///     List of ExtractionResult objects (one per file)
///
/// Raises:
///     ValueError: Invalid configuration
///     IOError: File access errors
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> from kreuzberg import batch_extract_files_sync, ExtractionConfig
///     >>> paths = ["doc1.pdf", "doc2.docx"]
///     >>> results = batch_extract_files_sync(paths, ExtractionConfig())
///     >>> for result in results:
///     ...     print(result.content)
///     >>> # Also works with pathlib.Path
///     >>> from pathlib import Path
///     >>> paths = [Path("doc1.pdf"), Path("doc2.docx")]
///     >>> results = batch_extract_files_sync(paths, ExtractionConfig())
#[pyfunction]
#[pyo3(signature = (paths, config=ExtractionConfig::default()))]
pub fn batch_extract_files_sync(
    py: Python,
    paths: &Bound<'_, PyList>,
    config: ExtractionConfig,
) -> PyResult<Py<PyList>> {
    let path_strings: PyResult<Vec<String>> = paths.iter().map(|p| extract_path_string(&p)).collect();
    let path_strings = path_strings?;

    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config = config.into();

    // Release GIL during sync batch extraction - OSError/RuntimeError must bubble up ~keep
    let results =
        Python::detach(py, || kreuzberg::batch_extract_file_sync(path_strings, &rust_config)).map_err(to_py_err)?;

    let converted: PyResult<Vec<_>> = results
        .into_iter()
        .map(|result| {
            ExtractionResult::from_rust(result, py, output_fmt.as_ref().cloned(), result_fmt.as_ref().cloned())
        })
        .collect();
    let list = PyList::new(py, converted?)?;
    Ok(list.unbind())
}

/// Batch extract content from multiple byte arrays (synchronous).
///
/// Args:
///     data_list: List of bytes objects to extract
///     mime_types: List of MIME types (one per data object)
///     config: Extraction configuration
///
/// Returns:
///     List of ExtractionResult objects (one per data object)
///
/// Raises:
///     ValueError: Invalid configuration or list length mismatch
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> from kreuzberg import batch_extract_bytes_sync, ExtractionConfig
///     >>> data_list = [open("doc1.pdf", "rb").read(), open("doc2.pdf", "rb").read()]
///     >>> mime_types = ["application/pdf", "application/pdf"]
///     >>> results = batch_extract_bytes_sync(data_list, mime_types, ExtractionConfig())
#[pyfunction]
#[pyo3(signature = (data_list, mime_types, config=ExtractionConfig::default()))]
pub fn batch_extract_bytes_sync(
    py: Python,
    data_list: Vec<Vec<u8>>,
    mime_types: Vec<String>,
    config: ExtractionConfig,
) -> PyResult<Py<PyList>> {
    if data_list.len() != mime_types.len() {
        return Err(pyo3::exceptions::PyValueError::new_err(format!(
            "data_list and mime_types must have the same length (got {} and {})",
            data_list.len(),
            mime_types.len()
        )));
    }

    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config = config.into();

    let contents: Vec<(&[u8], &str)> = data_list
        .iter()
        .zip(mime_types.iter())
        .map(|(data, mime)| (data.as_slice(), mime.as_str()))
        .collect();

    let owned_contents: Vec<(Vec<u8>, String)> = contents
        .into_iter()
        .map(|(bytes, mime)| (bytes.to_vec(), mime.to_string()))
        .collect();

    // Release GIL during sync batch extraction - OSError/RuntimeError must bubble up ~keep
    let results =
        Python::detach(py, || kreuzberg::batch_extract_bytes_sync(owned_contents, &rust_config)).map_err(to_py_err)?;

    let converted: PyResult<Vec<_>> = results
        .into_iter()
        .map(|result| ExtractionResult::from_rust(result, py, output_fmt.clone(), result_fmt.clone()))
        .collect();
    let list = PyList::new(py, converted?)?;
    Ok(list.unbind())
}

/// Extract content from a file (asynchronous).
///
/// Args:
///     path: Path to the file to extract (str or pathlib.Path)
///     mime_type: Optional MIME type hint (auto-detected if None)
///     config: Extraction configuration
///
/// Returns:
///     ExtractionResult with content, metadata, and tables
///
/// Raises:
///     ValueError: Invalid configuration or unsupported format
///     IOError: File access errors
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> import asyncio
///     >>> from kreuzberg import extract_file, ExtractionConfig
///     >>> async def main():
///     ...     result = await extract_file("document.pdf", None, ExtractionConfig())
///     ...     print(result.content)
///     >>> asyncio.run(main())
///     >>> # Also works with pathlib.Path
///     >>> from pathlib import Path
///     >>> async def main():
///     ...     result = await extract_file(Path("document.pdf"))
#[pyfunction]
#[pyo3(signature = (path, mime_type=None, config=ExtractionConfig::default()))]
pub fn extract_file<'py>(
    py: Python<'py>,
    path: &Bound<'py, PyAny>,
    mime_type: Option<String>,
    config: ExtractionConfig,
) -> PyResult<Bound<'py, PyAny>> {
    let path_str = extract_path_string(path)?;
    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config: kreuzberg::ExtractionConfig = config.into();
    pyo3_async_runtimes::tokio::future_into_py(py, async move {
        let result = kreuzberg::extract_file(&path_str, mime_type.as_deref(), &rust_config)
            .await
            .map_err(to_py_err)?;
        Python::attach(|py| ExtractionResult::from_rust(result, py, output_fmt, result_fmt))
    })
}

/// Extract content from bytes (asynchronous).
///
/// Args:
///     data: Bytes to extract (bytes or bytearray)
///     mime_type: MIME type of the data
///     config: Extraction configuration
///
/// Returns:
///     ExtractionResult with content, metadata, and tables
///
/// Raises:
///     ValueError: Invalid configuration or unsupported format
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> import asyncio
///     >>> from kreuzberg import extract_bytes, ExtractionConfig
///     >>> async def main():
///     ...     with open("document.pdf", "rb") as f:
///     ...         data = f.read()
///     ...     result = await extract_bytes(data, "application/pdf", ExtractionConfig())
///     ...     print(result.content)
///     >>> asyncio.run(main())
#[pyfunction]
#[pyo3(signature = (data, mime_type, config=ExtractionConfig::default()))]
pub fn extract_bytes<'py>(
    py: Python<'py>,
    data: Vec<u8>,
    mime_type: String,
    config: ExtractionConfig,
) -> PyResult<Bound<'py, PyAny>> {
    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config: kreuzberg::ExtractionConfig = config.into();
    pyo3_async_runtimes::tokio::future_into_py(py, async move {
        let result = kreuzberg::extract_bytes(&data, &mime_type, &rust_config)
            .await
            .map_err(to_py_err)?;
        Python::attach(|py| ExtractionResult::from_rust(result, py, output_fmt, result_fmt))
    })
}

/// Batch extract content from multiple files (asynchronous).
///
/// MIME types are auto-detected for each file.
///
/// Args:
///     paths: List of file paths to extract (str, pathlib.Path, or bytes)
///     config: Extraction configuration
///
/// Returns:
///     List of ExtractionResult objects (one per file)
///
/// Raises:
///     ValueError: Invalid configuration
///     IOError: File access errors
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> import asyncio
///     >>> from kreuzberg import batch_extract_files, ExtractionConfig
///     >>> async def main():
///     ...     paths = ["doc1.pdf", "doc2.docx"]
///     ...     results = await batch_extract_files(paths, ExtractionConfig())
///     ...     for result in results:
///     ...         print(result.content)
///     >>> asyncio.run(main())
///     >>> # Also works with pathlib.Path
///     >>> from pathlib import Path
///     >>> async def main():
///     ...     paths = [Path("doc1.pdf"), Path("doc2.docx")]
///     ...     results = await batch_extract_files(paths, ExtractionConfig())
#[pyfunction]
#[pyo3(signature = (paths, config=ExtractionConfig::default()))]
pub fn batch_extract_files<'py>(
    py: Python<'py>,
    paths: &Bound<'py, PyList>,
    config: ExtractionConfig,
) -> PyResult<Bound<'py, PyAny>> {
    let path_strings: PyResult<Vec<String>> = paths.iter().map(|p| extract_path_string(&p)).collect();
    let path_strings = path_strings?;

    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config: kreuzberg::ExtractionConfig = config.into();
    pyo3_async_runtimes::tokio::future_into_py(py, async move {
        let results = kreuzberg::batch_extract_file(path_strings, &rust_config)
            .await
            .map_err(to_py_err)?;

        Python::attach(|py| {
            let converted: PyResult<Vec<_>> = results
                .into_iter()
                .map(|result| {
                    ExtractionResult::from_rust(result, py, output_fmt.as_ref().cloned(), result_fmt.as_ref().cloned())
                })
                .collect();
            let list = PyList::new(py, converted?)?;
            Ok(list.unbind())
        })
    })
}

/// Batch extract content from multiple byte arrays (asynchronous).
///
/// Args:
///     data_list: List of bytes objects to extract
///     mime_types: List of MIME types (one per data object)
///     config: Extraction configuration
///
/// Returns:
///     List of ExtractionResult objects (one per data object)
///
/// Raises:
///     ValueError: Invalid configuration or list length mismatch
///     RuntimeError: Extraction failures
///
/// Example:
///     >>> import asyncio
///     >>> from kreuzberg import batch_extract_bytes, ExtractionConfig
///     >>> async def main():
///     ...     data_list = [open("doc1.pdf", "rb").read(), open("doc2.pdf", "rb").read()]
///     ...     mime_types = ["application/pdf", "application/pdf"]
///     ...     results = await batch_extract_bytes(data_list, mime_types, ExtractionConfig())
///     >>> asyncio.run(main())
#[pyfunction]
#[pyo3(signature = (data_list, mime_types, config=ExtractionConfig::default()))]
pub fn batch_extract_bytes<'py>(
    py: Python<'py>,
    data_list: Vec<Vec<u8>>,
    mime_types: Vec<String>,
    config: ExtractionConfig,
) -> PyResult<Bound<'py, PyAny>> {
    if data_list.len() != mime_types.len() {
        return Err(pyo3::exceptions::PyValueError::new_err(format!(
            "data_list and mime_types must have the same length (got {} and {})",
            data_list.len(),
            mime_types.len()
        )));
    }

    let (output_fmt, result_fmt) = extract_format_strings(&config);
    let rust_config: kreuzberg::ExtractionConfig = config.into();
    pyo3_async_runtimes::tokio::future_into_py(py, async move {
        let contents: Vec<(&[u8], &str)> = data_list
            .iter()
            .zip(mime_types.iter())
            .map(|(data, mime)| (data.as_slice(), mime.as_str()))
            .collect();

        let owned_contents: Vec<(Vec<u8>, String)> = contents
            .into_iter()
            .map(|(bytes, mime)| (bytes.to_vec(), mime.to_string()))
            .collect();

        let results = kreuzberg::batch_extract_bytes(owned_contents, &rust_config)
            .await
            .map_err(to_py_err)?;

        Python::attach(|py| {
            let converted: PyResult<Vec<_>> = results
                .into_iter()
                .map(|result| {
                    ExtractionResult::from_rust(result, py, output_fmt.as_ref().cloned(), result_fmt.as_ref().cloned())
                })
                .collect();
            let list = PyList::new(py, converted?)?;
            Ok(list.unbind())
        })
    })
}

// ── PDF utilities (split, render, page count) ────────────────────────

/// Split a PDF into parts by page ranges.
///
/// Each range is a ``(start, end)`` tuple of **1-indexed, inclusive** page numbers.
/// Returns a list of ``bytes`` objects, each a complete PDF file.
///
/// Args:
///     data (bytes): PDF file content
///     ranges (list[tuple[int, int]]): Page ranges to extract, e.g. ``[(1, 3), (5, 5)]``
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     list[bytes]: One PDF per range
///
/// Raises:
///     ValueError: If a range is invalid (start > end, page 0, out of bounds)
///     RuntimeError: If the PDF cannot be loaded
///
/// Example:
///     >>> from kreuzberg import split_pdf
///     >>> pdf = open("big.pdf", "rb").read()
///     >>> parts = split_pdf(pdf, [(1, 5), (6, 10)])
///     >>> open("part1.pdf", "wb").write(parts[0])
#[pyfunction]
#[pyo3(signature = (data, ranges, password=None))]
pub fn split_pdf(
    py: Python,
    data: Vec<u8>,
    ranges: Vec<(u32, u32)>,
    password: Option<String>,
) -> PyResult<Vec<pyo3::Py<pyo3::types::PyBytes>>> {
    let page_ranges: Vec<kreuzberg::pdf::split::PageRange> = ranges
        .into_iter()
        .map(|(s, e)| kreuzberg::pdf::split::PageRange::new(s, e))
        .collect();

    let results = Python::detach(py, || {
        kreuzberg::pdf::split::split_pdf_with_password(&data, &page_ranges, password.as_deref())
    })
    .map_err(|e| to_py_err(e.into()))?;

    Ok(results
        .into_iter()
        .map(|bytes| pyo3::types::PyBytes::new(py, &bytes).unbind())
        .collect())
}

/// Split a PDF into individual single-page PDFs.
///
/// Args:
///     data (bytes): PDF file content
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     list[bytes]: One single-page PDF per page in the document
///
/// Example:
///     >>> from kreuzberg import split_pdf_into_pages
///     >>> pdf = open("document.pdf", "rb").read()
///     >>> pages = split_pdf_into_pages(pdf)
///     >>> for i, page in enumerate(pages):
///     ...     open(f"page_{i+1}.pdf", "wb").write(page)
#[pyfunction]
#[pyo3(signature = (data, password=None))]
pub fn split_pdf_into_pages(
    py: Python,
    data: Vec<u8>,
    password: Option<String>,
) -> PyResult<Vec<pyo3::Py<pyo3::types::PyBytes>>> {
    let results = Python::detach(py, || {
        kreuzberg::pdf::split::split_pdf_into_pages_with_password(&data, password.as_deref())
    })
    .map_err(|e| to_py_err(e.into()))?;

    Ok(results
        .into_iter()
        .map(|bytes| pyo3::types::PyBytes::new(py, &bytes).unbind())
        .collect())
}

/// Split a PDF into chunks of N pages each.
///
/// The last chunk may have fewer pages if the total isn't evenly divisible.
///
/// Args:
///     data (bytes): PDF file content
///     chunk_size (int): Number of pages per chunk
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     list[bytes]: One PDF per chunk
///
/// Example:
///     >>> from kreuzberg import split_pdf_into_chunks
///     >>> pdf = open("book.pdf", "rb").read()
///     >>> chunks = split_pdf_into_chunks(pdf, 10)  # 10 pages per chunk
#[pyfunction]
#[pyo3(signature = (data, chunk_size, password=None))]
pub fn split_pdf_into_chunks(
    py: Python,
    data: Vec<u8>,
    chunk_size: u32,
    password: Option<String>,
) -> PyResult<Vec<pyo3::Py<pyo3::types::PyBytes>>> {
    let results = Python::detach(py, || {
        kreuzberg::pdf::split::split_pdf_into_chunks_with_password(&data, chunk_size, password.as_deref())
    })
    .map_err(|e| to_py_err(e.into()))?;

    Ok(results
        .into_iter()
        .map(|bytes| pyo3::types::PyBytes::new(py, &bytes).unbind())
        .collect())
}

/// Get the page count of a PDF.
///
/// Args:
///     data (bytes): PDF file content
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     int: Number of pages
///
/// Example:
///     >>> from kreuzberg import pdf_page_count
///     >>> pdf = open("document.pdf", "rb").read()
///     >>> count = pdf_page_count(pdf)
///     >>> print(f"{count} pages")
#[pyfunction]
#[pyo3(signature = (data, password=None))]
pub fn pdf_page_count(py: Python, data: Vec<u8>, password: Option<String>) -> PyResult<u32> {
    Python::detach(py, || {
        kreuzberg::pdf::split::page_count_with_password(&data, password.as_deref())
    })
    .map_err(|e| to_py_err(e.into()))
}

/// Render a single PDF page to a PNG image.
///
/// Args:
///     data (bytes): PDF file content
///     page_index (int): 0-indexed page number
///     dpi (int): Resolution in dots per inch (default: 300)
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     bytes: PNG image data
///
/// Raises:
///     ValueError: If page_index is out of bounds
///     RuntimeError: If rendering fails
///
/// Example:
///     >>> from kreuzberg import render_page_to_image
///     >>> pdf = open("document.pdf", "rb").read()
///     >>> png = render_page_to_image(pdf, 0, dpi=150)
///     >>> open("page1.png", "wb").write(png)
#[pyfunction]
#[pyo3(signature = (data, page_index, dpi=300, password=None))]
pub fn render_page_to_image(
    py: Python,
    data: Vec<u8>,
    page_index: usize,
    dpi: i32,
    password: Option<String>,
) -> PyResult<pyo3::Py<pyo3::types::PyBytes>> {
    let png_bytes = Python::detach(py, || -> Result<Vec<u8>, kreuzberg::KreuzbergError> {
        let renderer = kreuzberg::pdf::rendering::PdfRenderer::new()?;

        let options = kreuzberg::pdf::rendering::PageRenderOptions {
            target_dpi: dpi,
            ..Default::default()
        };

        let image = renderer.render_page_to_image_with_password(&data, page_index, &options, password.as_deref())?;

        let mut buf = std::io::Cursor::new(Vec::new());
        image
            .write_to(&mut buf, image::ImageFormat::Png)
            .map_err(|e| kreuzberg::KreuzbergError::image_processing(format!("PNG encoding failed: {}", e)))?;

        Ok(buf.into_inner())
    })
    .map_err(to_py_err)?;

    Ok(pyo3::types::PyBytes::new(py, &png_bytes).unbind())
}

/// Render all pages of a PDF to PNG images.
///
/// Args:
///     data (bytes): PDF file content
///     dpi (int): Resolution in dots per inch (default: 300)
///     password (str | None): Optional password for encrypted PDFs
///
/// Returns:
///     list[bytes]: PNG image data for each page
///
/// Example:
///     >>> from kreuzberg import render_all_pages_to_images
///     >>> pdf = open("document.pdf", "rb").read()
///     >>> images = render_all_pages_to_images(pdf, dpi=150)
///     >>> for i, png in enumerate(images):
///     ...     open(f"page_{i+1}.png", "wb").write(png)
#[pyfunction]
#[pyo3(signature = (data, dpi=300, password=None))]
pub fn render_all_pages_to_images(
    py: Python,
    data: Vec<u8>,
    dpi: i32,
    password: Option<String>,
) -> PyResult<Vec<pyo3::Py<pyo3::types::PyBytes>>> {
    let all_png_bytes = Python::detach(py, || -> Result<Vec<Vec<u8>>, kreuzberg::KreuzbergError> {
        let renderer = kreuzberg::pdf::rendering::PdfRenderer::new()?;

        let options = kreuzberg::pdf::rendering::PageRenderOptions {
            target_dpi: dpi,
            ..Default::default()
        };

        let images = renderer.render_all_pages_with_password(&data, &options, password.as_deref())?;

        images
            .into_iter()
            .map(|image: image::DynamicImage| {
                let mut buf = std::io::Cursor::new(Vec::new());
                image
                    .write_to(&mut buf, image::ImageFormat::Png)
                    .map_err(|e| kreuzberg::KreuzbergError::image_processing(format!("PNG encoding failed: {}", e)))?;
                Ok(buf.into_inner())
            })
            .collect()
    })
    .map_err(to_py_err)?;

    Ok(all_png_bytes
        .into_iter()
        .map(|bytes| pyo3::types::PyBytes::new(py, &bytes).unbind())
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    use pyo3::types::{PyBytes, PyString};
    use std::sync::Once;

    fn prepare_python() {
        static INIT: Once = Once::new();
        INIT.call_once(Python::initialize);
    }

    fn with_py<F, R>(f: F) -> R
    where
        F: FnOnce(Python<'_>) -> R,
    {
        prepare_python();
        Python::attach(f)
    }

    #[test]
    fn test_extract_path_string_from_str() {
        with_py(|py| {
            let value = PyString::new(py, "document.txt");
            let result = extract_path_string(&value.into_any()).expect("string path should extract");
            assert_eq!(result, "document.txt");
        });
    }

    #[test]
    fn test_extract_path_string_from_pathlib_path() {
        with_py(|py| -> PyResult<()> {
            let pathlib = py.import("pathlib")?;
            let path_obj = pathlib.getattr("Path")?.call1(("nested/file.md",))?;
            let extracted = extract_path_string(&path_obj)?;
            assert!(
                extracted.ends_with("nested/file.md"),
                "expected path to end with nested/file.md, got {extracted}"
            );
            Ok(())
        })
        .expect("pathlib.Path extraction should succeed");
    }

    #[test]
    fn test_extract_path_string_from_bytes() {
        with_py(|py| {
            let value = PyBytes::new(py, b"ascii.bin");
            let result = extract_path_string(&value.into_any()).expect("bytes path should extract");
            assert_eq!(result, "ascii.bin");
        });
    }

    #[test]
    fn test_extract_path_string_invalid_type() {
        with_py(|py| {
            let value = py
                .eval(pyo3::ffi::c_str!("42"), None, None)
                .expect("should evaluate literal");
            let err = extract_path_string(&value).expect_err("non-path type should fail");
            assert!(err.is_instance_of::<pyo3::exceptions::PyTypeError>(py));
        });
    }

    #[test]
    fn test_extract_bytes_sync_returns_content() {
        with_py(|py| {
            let data = b"hello kreuzberg".to_vec();
            let result = extract_bytes_sync(py, data, "text/plain".to_string(), ExtractionConfig::default())
                .expect("text/plain extraction should succeed");
            assert_eq!(result.mime_type, "text/plain");
            assert!(result.content.contains("hello"));
        });
    }

    #[test]
    fn test_batch_extract_bytes_sync_length_mismatch() {
        with_py(|py| {
            let err = batch_extract_bytes_sync(
                py,
                vec![b"a".to_vec(), b"b".to_vec()],
                vec!["text/plain".to_string()],
                ExtractionConfig::default(),
            )
            .expect_err("length mismatch should error");
            assert!(err.is_instance_of::<pyo3::exceptions::PyValueError>(py));
        });
    }

    #[test]
    fn test_batch_extract_bytes_sync_returns_list() {
        with_py(|py| {
            let data = vec![b"first".to_vec(), b"second".to_vec()];
            let mimes = vec!["text/plain".to_string(), "text/plain".to_string()];
            let list = batch_extract_bytes_sync(py, data, mimes, ExtractionConfig::default())
                .expect("batch extraction should succeed");
            assert_eq!(list.bind(py).len(), 2);
        });
    }
}
