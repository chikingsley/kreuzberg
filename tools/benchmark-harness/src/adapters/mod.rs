//! Framework adapter implementations

use std::env;

pub mod external;
pub mod kreuzberg;
pub mod native;
pub mod node;
pub mod python;
pub mod ruby;
pub mod subprocess;

pub use external::{
    create_docling_adapter, create_docling_batch_adapter, create_markitdown_adapter, create_mineru_adapter,
    create_mineru_batch_adapter, create_pandoc_adapter, create_pdfplumber_adapter, create_pdfplumber_batch_adapter,
    create_pymupdf4llm_adapter, create_tika_adapter, create_tika_batch_adapter, create_unstructured_adapter,
};
pub use kreuzberg::{
    create_csharp_adapter, create_csharp_batch_adapter, create_elixir_adapter, create_elixir_batch_adapter,
    create_go_adapter, create_go_batch_adapter, create_java_adapter, create_java_batch_adapter, create_node_adapter,
    create_node_batch_adapter, create_php_adapter, create_php_batch_adapter, create_python_adapter,
    create_python_batch_adapter, create_ruby_adapter, create_ruby_batch_adapter, create_wasm_adapter,
    create_wasm_batch_adapter,
};
pub use native::NativeAdapter;
pub use node::NodeAdapter;
pub use python::PythonAdapter;
pub use ruby::RubyAdapter;
pub use subprocess::SubprocessAdapter;

/// Returns the OCR flag string based on the BENCHMARK_OCR_ENABLED env var
pub(crate) fn ocr_flag() -> String {
    if env::var("BENCHMARK_OCR_ENABLED").unwrap_or_default() == "true" {
        "--ocr".to_string()
    } else {
        "--no-ocr".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ocr_flag_when_enabled() {
        // Ensure clean state before test
        unsafe {
            env::remove_var("BENCHMARK_OCR_ENABLED");
        }

        unsafe {
            env::set_var("BENCHMARK_OCR_ENABLED", "true");
        }
        let result = ocr_flag();
        unsafe {
            env::remove_var("BENCHMARK_OCR_ENABLED");
        }

        assert_eq!(result, "--ocr", "Should return '--ocr' when BENCHMARK_OCR_ENABLED=true");
    }

    #[test]
    fn test_ocr_flag_when_disabled() {
        // Ensure clean state before test
        unsafe {
            env::remove_var("BENCHMARK_OCR_ENABLED");
        }

        unsafe {
            env::set_var("BENCHMARK_OCR_ENABLED", "false");
        }
        let result = ocr_flag();
        unsafe {
            env::remove_var("BENCHMARK_OCR_ENABLED");
        }

        assert_eq!(
            result, "--no-ocr",
            "Should return '--no-ocr' when BENCHMARK_OCR_ENABLED=false"
        );
    }

    #[test]
    fn test_ocr_flag_when_unset() {
        // Ensure clean state before test
        unsafe {
            env::remove_var("BENCHMARK_OCR_ENABLED");
        }

        let result = ocr_flag();

        assert_eq!(
            result, "--no-ocr",
            "Should return '--no-ocr' when BENCHMARK_OCR_ENABLED is unset"
        );
    }
}
