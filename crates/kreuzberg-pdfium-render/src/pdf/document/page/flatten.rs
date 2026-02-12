use crate::bindgen::FPDF_PAGE;
use crate::error::PdfiumError;

pub(super) fn flatten_page(_page_handle: FPDF_PAGE) -> Result<(), PdfiumError> {
    unimplemented!()
}
