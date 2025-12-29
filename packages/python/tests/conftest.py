"""Shared pytest fixtures for binding-specific tests."""

from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture
def docx_document() -> Path:
    """Path to DOCX test file used across binding-specific suites."""
    path = Path(__file__).parent.parent.parent.parent / "test_documents" / "documents" / "lorem_ipsum.docx"
    if not path.exists():
        pytest.skip(f"Test file not found: {path}")
    return path


@pytest.fixture(scope="session")
def test_documents() -> Path:
    """Path to test_documents directory containing PDF and other test files."""
    path = Path(__file__).parent.parent.parent.parent / "test_documents"
    if not path.exists():
        pytest.skip(f"Test documents directory not found: {path}")
    return path


# Session-level cache for all PDF extractions
# PDFium can only be initialized once per process
_pdf_extraction_cache = {}
_pdfium_initialized = False


@pytest.fixture(scope="session", autouse=True)
def _pdfium_session_management():
    """Manage PDFium initialization state for the session.

    PDFium is a C++ library that can only be initialized once per process.
    This fixture tracks that initialization to prevent "PdfiumLibraryBindingsAlreadyInitialized" errors
    when multiple test modules try to extract PDFs in the same process.

    NOTE: We do NOT initialize Pdfium here. Instead, we rely on the first PDF extraction
    (which typically comes from test_images.py::test_pdf_image_extraction_with_metadata)
    to initialize it. Once initialized, all subsequent PDF extractions reuse the
    already-initialized library. If that first test runs a different PDF, no worries -
    Pdfium only needs to be initialized once, it doesn't matter which PDF initializes it.
    """
    global _pdfium_initialized

    yield

    # Clear cache after session
    _pdf_extraction_cache.clear()
    _pdfium_initialized = False
