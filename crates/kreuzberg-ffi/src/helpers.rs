//! Helper utilities for FFI operations.
//!
//! This module contains shared helper functions for error handling, string conversion,
//! and type conversion between Rust and C types.

use std::cell::RefCell;
use std::ffi::CString;
use std::os::raw::c_char;
use std::ptr;

use kreuzberg::core::config::ExtractionConfig;
use kreuzberg::types::ExtractionResult;

use crate::panic_shield::{ErrorCode, StructuredError, clear_structured_error, set_structured_error};
use crate::types::{CExtractionResult, CStringGuard};

/// Type alias for FFI results that can fail with a String error message
pub type FfiResult<T> = std::result::Result<T, String>;

// Thread-local storage for the last error message (for backward compatibility)
thread_local! {
    pub(crate) static LAST_ERROR_C_STRING: RefCell<Option<CString>> = const { RefCell::new(None) };
}

/// Set the last error message (convenience wrapper for backward compatibility)
pub fn set_last_error(err: String) {
    if let Ok(c_str) = CString::new(err.clone()) {
        LAST_ERROR_C_STRING.with(|last| *last.borrow_mut() = Some(c_str));
    }

    let structured_err = StructuredError::from_message(err, ErrorCode::GenericError);
    set_structured_error(structured_err);
}

/// Clear the last error message
pub fn clear_last_error() {
    LAST_ERROR_C_STRING.with(|last| *last.borrow_mut() = None);
    clear_structured_error();
}

/// Convert a Rust String to a C string pointer
pub fn string_to_c_string(value: String) -> std::result::Result<*mut c_char, String> {
    CString::new(value)
        .map(CString::into_raw)
        .map_err(|e| format!("Failed to create C string: {}", e))
}

/// Parse extraction configuration from JSON string
pub fn parse_extraction_config_from_json(config_str: &str) -> FfiResult<ExtractionConfig> {
    use html_to_markdown_rs::options::{
        CodeBlockStyle, ConversionOptions, HeadingStyle, HighlightStyle, ListIndentType, NewlineStyle,
        PreprocessingPreset, WhitespaceMode,
    };

    fn parse_enum<T, F>(value: Option<&serde_json::Value>, parse_fn: F) -> FfiResult<Option<T>>
    where
        F: Fn(&str) -> std::result::Result<T, String>,
    {
        if let Some(raw) = value {
            let text = raw
                .as_str()
                .ok_or_else(|| "Expected string for html_options enum field".to_string())?;
            return parse_fn(text).map(Some);
        }
        Ok(None)
    }

    fn parse_heading_style(value: &str) -> FfiResult<HeadingStyle> {
        match value.to_lowercase().as_str() {
            "atx" => Ok(HeadingStyle::Atx),
            "underlined" => Ok(HeadingStyle::Underlined),
            "atx_closed" => Ok(HeadingStyle::AtxClosed),
            other => Err(format!(
                "Invalid heading_style '{}'. Expected one of: atx, underlined, atx_closed",
                other
            )),
        }
    }

    fn parse_list_indent_type(value: &str) -> FfiResult<ListIndentType> {
        match value.to_lowercase().as_str() {
            "spaces" => Ok(ListIndentType::Spaces),
            "tabs" => Ok(ListIndentType::Tabs),
            other => Err(format!(
                "Invalid list_indent_type '{}'. Expected 'spaces' or 'tabs'",
                other
            )),
        }
    }

    fn parse_highlight_style(value: &str) -> FfiResult<HighlightStyle> {
        match value.to_lowercase().as_str() {
            "double_equal" | "==" | "highlight" => Ok(HighlightStyle::DoubleEqual),
            "html" => Ok(HighlightStyle::Html),
            "bold" => Ok(HighlightStyle::Bold),
            "none" => Ok(HighlightStyle::None),
            other => Err(format!(
                "Invalid highlight_style '{}'. Expected one of: double_equal, html, bold, none",
                other
            )),
        }
    }

    fn parse_whitespace_mode(value: &str) -> FfiResult<WhitespaceMode> {
        match value.to_lowercase().as_str() {
            "normalized" => Ok(WhitespaceMode::Normalized),
            "strict" => Ok(WhitespaceMode::Strict),
            other => Err(format!(
                "Invalid whitespace_mode '{}'. Expected 'normalized' or 'strict'",
                other
            )),
        }
    }

    fn parse_newline_style(value: &str) -> FfiResult<NewlineStyle> {
        match value.to_lowercase().as_str() {
            "spaces" => Ok(NewlineStyle::Spaces),
            "backslash" => Ok(NewlineStyle::Backslash),
            other => Err(format!(
                "Invalid newline_style '{}'. Expected 'spaces' or 'backslash'",
                other
            )),
        }
    }

    fn parse_code_block_style(value: &str) -> FfiResult<CodeBlockStyle> {
        match value.to_lowercase().as_str() {
            "indented" => Ok(CodeBlockStyle::Indented),
            "backticks" => Ok(CodeBlockStyle::Backticks),
            "tildes" => Ok(CodeBlockStyle::Tildes),
            other => Err(format!(
                "Invalid code_block_style '{}'. Expected 'indented', 'backticks', or 'tildes'",
                other
            )),
        }
    }

    fn parse_preprocessing_preset(value: &str) -> FfiResult<PreprocessingPreset> {
        match value.to_lowercase().as_str() {
            "minimal" => Ok(PreprocessingPreset::Minimal),
            "standard" => Ok(PreprocessingPreset::Standard),
            "aggressive" => Ok(PreprocessingPreset::Aggressive),
            other => Err(format!(
                "Invalid preprocessing.preset '{}'. Expected one of: minimal, standard, aggressive",
                other
            )),
        }
    }

    fn parse_html_options(value: &serde_json::Value) -> FfiResult<ConversionOptions> {
        let mut opts = ConversionOptions::default();
        let obj = value
            .as_object()
            .ok_or_else(|| "html_options must be an object".to_string())?;

        if let Some(val) = obj.get("heading_style") {
            opts.heading_style = parse_enum(Some(val), parse_heading_style)?.unwrap_or(opts.heading_style);
        }

        if let Some(val) = obj.get("list_indent_type") {
            opts.list_indent_type = parse_enum(Some(val), parse_list_indent_type)?.unwrap_or(opts.list_indent_type);
        }

        if let Some(val) = obj.get("list_indent_width") {
            opts.list_indent_width = val
                .as_u64()
                .map(|v| v as usize)
                .ok_or_else(|| "list_indent_width must be an integer".to_string())?;
        }

        if let Some(val) = obj.get("bullets") {
            opts.bullets = val
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "bullets must be a string".to_string())?;
        }

        if let Some(val) = obj.get("strong_em_symbol") {
            let symbol = val
                .as_str()
                .ok_or_else(|| "strong_em_symbol must be a string".to_string())?;
            let mut chars = symbol.chars();
            opts.strong_em_symbol = chars
                .next()
                .ok_or_else(|| "strong_em_symbol must not be empty".to_string())?;
        }

        if let Some(val) = obj.get("escape_asterisks") {
            opts.escape_asterisks = val
                .as_bool()
                .ok_or_else(|| "escape_asterisks must be a boolean".to_string())?;
        }
        if let Some(val) = obj.get("escape_underscores") {
            opts.escape_underscores = val
                .as_bool()
                .ok_or_else(|| "escape_underscores must be a boolean".to_string())?;
        }
        if let Some(val) = obj.get("escape_misc") {
            opts.escape_misc = val
                .as_bool()
                .ok_or_else(|| "escape_misc must be a boolean".to_string())?;
        }
        if let Some(val) = obj.get("escape_ascii") {
            opts.escape_ascii = val
                .as_bool()
                .ok_or_else(|| "escape_ascii must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("code_language") {
            opts.code_language = val
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "code_language must be a string".to_string())?;
        }

        if let Some(val) = obj.get("autolinks") {
            opts.autolinks = val.as_bool().ok_or_else(|| "autolinks must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("default_title") {
            opts.default_title = val
                .as_bool()
                .ok_or_else(|| "default_title must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("br_in_tables") {
            opts.br_in_tables = val
                .as_bool()
                .ok_or_else(|| "br_in_tables must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("hocr_spatial_tables") {
            opts.hocr_spatial_tables = val
                .as_bool()
                .ok_or_else(|| "hocr_spatial_tables must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("highlight_style") {
            opts.highlight_style = parse_enum(Some(val), parse_highlight_style)?.unwrap_or(opts.highlight_style);
        }

        if let Some(val) = obj.get("extract_metadata") {
            opts.extract_metadata = val
                .as_bool()
                .ok_or_else(|| "extract_metadata must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("whitespace_mode") {
            opts.whitespace_mode = parse_enum(Some(val), parse_whitespace_mode)?.unwrap_or(opts.whitespace_mode);
        }

        if let Some(val) = obj.get("strip_newlines") {
            opts.strip_newlines = val
                .as_bool()
                .ok_or_else(|| "strip_newlines must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("wrap") {
            opts.wrap = val.as_bool().ok_or_else(|| "wrap must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("wrap_width") {
            opts.wrap_width = val
                .as_u64()
                .map(|v| v as usize)
                .ok_or_else(|| "wrap_width must be an integer".to_string())?;
        }

        if let Some(val) = obj.get("convert_as_inline") {
            opts.convert_as_inline = val
                .as_bool()
                .ok_or_else(|| "convert_as_inline must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("sub_symbol") {
            opts.sub_symbol = val
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "sub_symbol must be a string".to_string())?;
        }

        if let Some(val) = obj.get("sup_symbol") {
            opts.sup_symbol = val
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "sup_symbol must be a string".to_string())?;
        }

        if let Some(val) = obj.get("newline_style") {
            opts.newline_style = parse_enum(Some(val), parse_newline_style)?.unwrap_or(opts.newline_style);
        }

        if let Some(val) = obj.get("code_block_style") {
            opts.code_block_style = parse_enum(Some(val), parse_code_block_style)?.unwrap_or(opts.code_block_style);
        }

        if let Some(val) = obj.get("keep_inline_images_in") {
            opts.keep_inline_images_in = val
                .as_array()
                .ok_or_else(|| "keep_inline_images_in must be an array".to_string())?
                .iter()
                .map(|v| {
                    v.as_str()
                        .map(str::to_string)
                        .ok_or_else(|| "keep_inline_images_in entries must be strings".to_string())
                })
                .collect::<std::result::Result<Vec<_>, _>>()?;
        }

        if let Some(val) = obj.get("encoding") {
            opts.encoding = val
                .as_str()
                .map(str::to_string)
                .ok_or_else(|| "encoding must be a string".to_string())?;
        }

        if let Some(val) = obj.get("debug") {
            opts.debug = val.as_bool().ok_or_else(|| "debug must be a boolean".to_string())?;
        }

        if let Some(val) = obj.get("strip_tags") {
            opts.strip_tags = val
                .as_array()
                .ok_or_else(|| "strip_tags must be an array".to_string())?
                .iter()
                .map(|v| {
                    v.as_str()
                        .map(str::to_string)
                        .ok_or_else(|| "strip_tags entries must be strings".to_string())
                })
                .collect::<std::result::Result<Vec<_>, _>>()?;
        }

        if let Some(val) = obj.get("preserve_tags") {
            opts.preserve_tags = val
                .as_array()
                .ok_or_else(|| "preserve_tags must be an array".to_string())?
                .iter()
                .map(|v| {
                    v.as_str()
                        .map(str::to_string)
                        .ok_or_else(|| "preserve_tags entries must be strings".to_string())
                })
                .collect::<std::result::Result<Vec<_>, _>>()?;
        }

        if let Some(val) = obj.get("preprocessing") {
            let pre = val
                .as_object()
                .ok_or_else(|| "preprocessing must be an object".to_string())?;
            let mut preprocessing = opts.preprocessing.clone();

            if let Some(v) = pre.get("enabled") {
                preprocessing.enabled = v
                    .as_bool()
                    .ok_or_else(|| "preprocessing.enabled must be a boolean".to_string())?;
            }

            if let Some(v) = pre.get("preset") {
                let preset = v
                    .as_str()
                    .ok_or_else(|| "preprocessing.preset must be a string".to_string())?;
                preprocessing.preset = parse_preprocessing_preset(preset)?;
            }

            if let Some(v) = pre.get("remove_navigation") {
                preprocessing.remove_navigation = v
                    .as_bool()
                    .ok_or_else(|| "preprocessing.remove_navigation must be a boolean".to_string())?;
            }

            if let Some(v) = pre.get("remove_forms") {
                preprocessing.remove_forms = v
                    .as_bool()
                    .ok_or_else(|| "preprocessing.remove_forms must be a boolean".to_string())?;
            }

            opts.preprocessing = preprocessing;
        }

        Ok(opts)
    }

    let value: serde_json::Value =
        serde_json::from_str(config_str).map_err(|e| format!("Failed to parse config JSON: {}", e))?;

    let html_options = value.get("html_options").map(parse_html_options).transpose()?;

    let mut config: ExtractionConfig =
        serde_json::from_value(value).map_err(|e| format!("Failed to parse config JSON: {}", e))?;

    if let Some(options) = html_options {
        config.html_options = Some(options);
    }

    Ok(config)
}

/// Convert a Rust ExtractionResult to a C-compatible CExtractionResult
pub fn to_c_extraction_result(result: ExtractionResult) -> std::result::Result<*mut CExtractionResult, String> {
    let ExtractionResult {
        content,
        mime_type,
        metadata,
        tables,
        detected_languages,
        chunks,
        images,
        pages,
    } = result;

    let sanitized_content = if content.contains('\0') {
        content.replace('\0', "\u{FFFD}")
    } else {
        content
    };

    let content_guard = CStringGuard::new(
        CString::new(sanitized_content).map_err(|e| format!("Failed to convert content to C string: {}", e))?,
    );

    let mime_type_guard = CStringGuard::new(
        CString::new(mime_type).map_err(|e| format!("Failed to convert MIME type to C string: {}", e))?,
    );

    let language_guard = match &metadata.language {
        Some(lang) => Some(CStringGuard::new(
            CString::new(lang.as_str()).map_err(|e| format!("Failed to convert language to C string: {}", e))?,
        )),
        None => None,
    };

    let date_guard = match &metadata.created_at {
        Some(d) => {
            Some(CStringGuard::new(CString::new(d.as_str()).map_err(|e| {
                format!("Failed to convert created_at to C string: {}", e)
            })?))
        }
        None => None,
    };

    let subject_guard = match &metadata.subject {
        Some(subj) => Some(CStringGuard::new(
            CString::new(subj.as_str()).map_err(|e| format!("Failed to convert subject to C string: {}", e))?,
        )),
        None => None,
    };

    let tables_json_guard = if !tables.is_empty() {
        let json = serde_json::to_string(&tables).map_err(|e| format!("Failed to serialize tables to JSON: {}", e))?;
        Some(CStringGuard::new(CString::new(json).map_err(|e| {
            format!("Failed to convert tables JSON to C string: {}", e)
        })?))
    } else {
        None
    };

    let detected_languages_json_guard = match detected_languages {
        Some(langs) if !langs.is_empty() => {
            let json = serde_json::to_string(&langs)
                .map_err(|e| format!("Failed to serialize detected languages to JSON: {}", e))?;
            Some(CStringGuard::new(CString::new(json).map_err(|e| {
                format!("Failed to convert detected languages JSON to C string: {}", e)
            })?))
        }
        _ => None,
    };

    let metadata_json_guard = {
        let json =
            serde_json::to_string(&metadata).map_err(|e| format!("Failed to serialize metadata to JSON: {}", e))?;
        Some(CStringGuard::new(CString::new(json).map_err(|e| {
            format!("Failed to convert metadata JSON to C string: {}", e)
        })?))
    };

    let chunks_json_guard = match chunks {
        Some(chunks) if !chunks.is_empty() => {
            let json =
                serde_json::to_string(&chunks).map_err(|e| format!("Failed to serialize chunks to JSON: {}", e))?;
            Some(CStringGuard::new(CString::new(json).map_err(|e| {
                format!("Failed to convert chunks JSON to C string: {}", e)
            })?))
        }
        _ => None,
    };

    let images_json_guard = match images {
        Some(images) if !images.is_empty() => {
            let json =
                serde_json::to_string(&images).map_err(|e| format!("Failed to serialize images to JSON: {}", e))?;
            Some(CStringGuard::new(CString::new(json).map_err(|e| {
                format!("Failed to convert images JSON to C string: {}", e)
            })?))
        }
        _ => None,
    };

    let page_structure_json_guard = match &metadata.pages {
        Some(page_structure) => {
            let json = serde_json::to_string(&page_structure)
                .map_err(|e| format!("Failed to serialize page structure to JSON: {}", e))?;
            Some(CStringGuard::new(CString::new(json).map_err(|e| {
                format!("Failed to convert page structure JSON to C string: {}", e)
            })?))
        }
        _ => None,
    };

    let pages_json_guard = match pages {
        Some(pages) if !pages.is_empty() => {
            let json =
                serde_json::to_string(&pages).map_err(|e| format!("Failed to serialize pages to JSON: {}", e))?;
            Some(CStringGuard::new(CString::new(json).map_err(|e| {
                format!("Failed to convert pages JSON to C string: {}", e)
            })?))
        }
        _ => None,
    };

    Ok(Box::into_raw(Box::new(CExtractionResult {
        content: content_guard.into_raw(),
        mime_type: mime_type_guard.into_raw(),
        language: language_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        date: date_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        subject: subject_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        tables_json: tables_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        detected_languages_json: detected_languages_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        metadata_json: metadata_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        chunks_json: chunks_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        images_json: images_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        page_structure_json: page_structure_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        pages_json: pages_json_guard.map_or(ptr::null_mut(), |g| g.into_raw()),
        success: true,
        _padding1: [0u8; 7],
    })))
}

#[cfg(test)]
mod tests {
    use super::*;
    use kreuzberg::types::{Chunk, ChunkMetadata, ExtractionResult, Metadata, Table};
    use std::ffi::CStr;

    #[test]
    fn test_set_and_clear_error() {
        // Test that error functions don't panic
        set_last_error("test error".to_string());
        clear_last_error();
    }

    #[test]
    fn test_string_to_c_string_success() {
        let result = string_to_c_string("hello world".to_string());
        assert!(result.is_ok());

        // Clean up the allocated string
        if let Ok(ptr) = result {
            unsafe {
                let _ = CString::from_raw(ptr);
            }
        }
    }

    #[test]
    fn test_string_to_c_string_with_null_byte() {
        let result = string_to_c_string("hello\0world".to_string());
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Failed to create C string"));
    }

    #[test]
    fn test_parse_extraction_config_empty_json() {
        let result = parse_extraction_config_from_json("{}");
        assert!(result.is_ok());
        let config = result.unwrap();
        // Default config should be created
        assert!(config.html_options.is_none());
    }

    #[test]
    fn test_parse_extraction_config_with_basic_options() {
        let json = r#"{
            "use_cache": true,
            "enable_quality_processing": false
        }"#;

        let result = parse_extraction_config_from_json(json);
        assert!(result.is_ok());
        let config = result.unwrap();
        assert!(config.use_cache);
        assert!(!config.enable_quality_processing);
    }

    #[test]
    fn test_parse_extraction_config_with_html_options() {
        let json = r#"{
            "html_options": {
                "heading_style": "atx",
                "escape_asterisks": true,
                "autolinks": false
            }
        }"#;

        let result = parse_extraction_config_from_json(json);
        assert!(result.is_ok());
        let config = result.unwrap();
        assert!(config.html_options.is_some());

        let html_opts = config.html_options.unwrap();
        assert!(html_opts.escape_asterisks);
        assert!(!html_opts.autolinks);
    }

    #[test]
    fn test_parse_extraction_config_invalid_json() {
        let result = parse_extraction_config_from_json("not valid json");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Failed to parse config JSON"));
    }

    #[test]
    fn test_parse_extraction_config_invalid_heading_style() {
        let json = r#"{
            "html_options": {
                "heading_style": "invalid_style"
            }
        }"#;

        let result = parse_extraction_config_from_json(json);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Invalid heading_style"));
    }

    #[test]
    fn test_parse_extraction_config_all_heading_styles() {
        let styles = vec![
            ("atx", "Atx"),
            ("underlined", "Underlined"),
            ("atx_closed", "AtxClosed"),
        ];

        for (input, _expected) in styles {
            let json = format!(r#"{{"html_options": {{"heading_style": "{}"}}}}"#, input);
            let result = parse_extraction_config_from_json(&json);
            assert!(result.is_ok(), "Failed to parse heading_style: {}", input);
        }
    }

    #[test]
    fn test_parse_extraction_config_preprocessing() {
        let json = r#"{
            "html_options": {
                "preprocessing": {
                    "enabled": true,
                    "preset": "aggressive",
                    "remove_navigation": true,
                    "remove_forms": false
                }
            }
        }"#;

        let result = parse_extraction_config_from_json(json);
        assert!(result.is_ok());
        let config = result.unwrap();
        assert!(config.html_options.is_some());

        let preprocessing = &config.html_options.unwrap().preprocessing;
        assert!(preprocessing.enabled);
        assert!(preprocessing.remove_navigation);
        assert!(!preprocessing.remove_forms);
    }

    #[test]
    fn test_to_c_extraction_result_basic() {
        let result = ExtractionResult {
            content: "Test content".to_string(),
            mime_type: "text/plain".to_string(),
            metadata: Metadata::default(),
            tables: vec![],
            detected_languages: None,
            chunks: None,
            images: None,
            pages: None,
        };

        let c_result = to_c_extraction_result(result);
        assert!(c_result.is_ok());

        // Clean up the allocated result
        if let Ok(ptr) = c_result {
            unsafe {
                let boxed = Box::from_raw(ptr);
                // Verify success flag
                assert!(boxed.success);

                // Clean up strings
                if !boxed.content.is_null() {
                    let _ = CString::from_raw(boxed.content);
                }
                if !boxed.mime_type.is_null() {
                    let _ = CString::from_raw(boxed.mime_type);
                }
                if !boxed.metadata_json.is_null() {
                    let _ = CString::from_raw(boxed.metadata_json);
                }
            }
        }
    }

    #[test]
    fn test_to_c_extraction_result_with_null_bytes() {
        let result = ExtractionResult {
            content: "Test\0content with null".to_string(),
            mime_type: "text/plain".to_string(),
            metadata: Metadata::default(),
            tables: vec![],
            detected_languages: None,
            chunks: None,
            images: None,
            pages: None,
        };

        let c_result = to_c_extraction_result(result);
        assert!(c_result.is_ok());

        // Clean up
        if let Ok(ptr) = c_result {
            unsafe {
                let boxed = Box::from_raw(ptr);

                // Verify null bytes were replaced with replacement character
                let content_str = CStr::from_ptr(boxed.content).to_str().unwrap();
                assert!(!content_str.contains('\0'));
                assert!(content_str.contains('\u{FFFD}'));

                // Clean up strings
                if !boxed.content.is_null() {
                    let _ = CString::from_raw(boxed.content);
                }
                if !boxed.mime_type.is_null() {
                    let _ = CString::from_raw(boxed.mime_type);
                }
                if !boxed.metadata_json.is_null() {
                    let _ = CString::from_raw(boxed.metadata_json);
                }
            }
        }
    }

    #[test]
    fn test_to_c_extraction_result_with_metadata() {
        let metadata = Metadata {
            language: Some("en".to_string()),
            created_at: Some("2024-01-01".to_string()),
            subject: Some("Test Subject".to_string()),
            ..Default::default()
        };

        let result = ExtractionResult {
            content: "Test content".to_string(),
            mime_type: "text/plain".to_string(),
            metadata,
            tables: vec![],
            detected_languages: Some(vec!["en".to_string(), "de".to_string()]),
            chunks: None,
            images: None,
            pages: None,
        };

        let c_result = to_c_extraction_result(result);
        assert!(c_result.is_ok());

        // Clean up
        if let Ok(ptr) = c_result {
            unsafe {
                let boxed = Box::from_raw(ptr);

                // Verify metadata fields are not null
                assert!(!boxed.language.is_null());
                assert!(!boxed.date.is_null());
                assert!(!boxed.subject.is_null());
                assert!(!boxed.detected_languages_json.is_null());

                // Clean up all allocated strings
                if !boxed.content.is_null() {
                    let _ = CString::from_raw(boxed.content);
                }
                if !boxed.mime_type.is_null() {
                    let _ = CString::from_raw(boxed.mime_type);
                }
                if !boxed.language.is_null() {
                    let _ = CString::from_raw(boxed.language);
                }
                if !boxed.date.is_null() {
                    let _ = CString::from_raw(boxed.date);
                }
                if !boxed.subject.is_null() {
                    let _ = CString::from_raw(boxed.subject);
                }
                if !boxed.metadata_json.is_null() {
                    let _ = CString::from_raw(boxed.metadata_json);
                }
                if !boxed.detected_languages_json.is_null() {
                    let _ = CString::from_raw(boxed.detected_languages_json);
                }
            }
        }
    }

    #[test]
    fn test_to_c_extraction_result_with_tables_and_chunks() {
        let table = Table {
            cells: vec![
                vec!["Col1".to_string(), "Col2".to_string()],
                vec!["A1".to_string(), "A2".to_string()],
                vec!["B1".to_string(), "B2".to_string()],
            ],
            markdown: "| Col1 | Col2 |\n|------|------|\n| A1 | A2 |\n| B1 | B2 |".to_string(),
            page_number: 1,
        };

        let chunk = Chunk {
            content: "Chunk content".to_string(),
            embedding: None,
            metadata: ChunkMetadata {
                byte_start: 0,
                byte_end: 13,
                token_count: None,
                chunk_index: 0,
                total_chunks: 1,
                first_page: Some(1),
                last_page: Some(1),
            },
        };

        let result = ExtractionResult {
            content: "Test content".to_string(),
            mime_type: "text/plain".to_string(),
            metadata: Metadata::default(),
            tables: vec![table],
            detected_languages: None,
            chunks: Some(vec![chunk]),
            images: None,
            pages: None,
        };

        let c_result = to_c_extraction_result(result);
        assert!(c_result.is_ok());

        // Clean up
        if let Ok(ptr) = c_result {
            unsafe {
                let boxed = Box::from_raw(ptr);

                // Verify JSON fields are not null
                assert!(!boxed.tables_json.is_null());
                assert!(!boxed.chunks_json.is_null());

                // Clean up all allocated strings
                if !boxed.content.is_null() {
                    let _ = CString::from_raw(boxed.content);
                }
                if !boxed.mime_type.is_null() {
                    let _ = CString::from_raw(boxed.mime_type);
                }
                if !boxed.metadata_json.is_null() {
                    let _ = CString::from_raw(boxed.metadata_json);
                }
                if !boxed.tables_json.is_null() {
                    let _ = CString::from_raw(boxed.tables_json);
                }
                if !boxed.chunks_json.is_null() {
                    let _ = CString::from_raw(boxed.chunks_json);
                }
            }
        }
    }
}
