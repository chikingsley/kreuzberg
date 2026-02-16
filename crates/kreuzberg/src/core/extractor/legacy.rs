//! Legacy synchronous extraction for WASM compatibility.
//!
//! This module provides truly synchronous extraction implementations
//! for environments where Tokio runtime is not available (e.g., WASM).

/// Synchronous extraction implementation for WASM compatibility.
///
/// This function performs extraction without requiring a tokio runtime.
/// It calls the sync extractor methods directly.
///
/// # Arguments
///
/// * `content` - The byte content to extract
/// * `mime_type` - Optional MIME type to validate/use
/// * `config` - Optional extraction configuration
///
/// # Returns
///
/// An `ExtractionResult` or a `KreuzbergError`
///
/// # Implementation Notes
///
/// This is called when the `tokio-runtime` feature is disabled.
/// It replicates the logic of `extract_bytes` but uses synchronous extractor methods.
#[cfg(not(feature = "tokio-runtime"))]
pub(super) fn extract_bytes_sync_impl(
    content: &[u8],
    mime_type: Option<&str>,
    config: Option<&crate::core::config::ExtractionConfig>,
) -> crate::Result<crate::types::ExtractionResult> {
    use crate::KreuzbergError;
    use crate::core::extractor::helpers::get_extractors;
    use crate::core::mime;

    let cfg = config.cloned().unwrap_or_default();

    let validated_mime = if let Some(mime) = mime_type {
        mime::validate_mime_type(mime)?
    } else {
        return Err(KreuzbergError::Validation {
            message: "MIME type is required for synchronous extraction".to_string(),
            source: None,
        });
    };

    crate::extractors::ensure_initialized()?;

    let extractors = get_extractors(&validated_mime)?;
    let mut failures = Vec::new();
    let mut last_error = None;

    for extractor in extractors {
        let extractor_name = extractor.name().to_string();
        let sync_extractor = match extractor.as_sync_extractor() {
            Some(sync_extractor) => sync_extractor,
            None => {
                failures.push(format!(
                    "{}: extractor does not support synchronous extraction",
                    extractor_name
                ));
                continue;
            }
        };

        match sync_extractor.extract_sync(content, &validated_mime, &cfg) {
            Ok(mut result) => {
                result = crate::core::pipeline::run_pipeline_sync(result, &cfg)?;
                return Ok(result);
            }
            Err(err) => {
                if matches!(&err, KreuzbergError::Io(_) | KreuzbergError::LockPoisoned(_)) {
                    return Err(err);
                }
                let error_message = err.to_string();
                failures.push(format!("{}: {}", extractor_name, error_message));
                last_error = Some(err);
            }
        }
    }

    tracing::debug!(
        "All synchronous extractors failed for MIME '{}'. Attempts: {}",
        validated_mime,
        failures.join(" | ")
    );

    match last_error {
        Some(err) => Err(err),
        None => Err(KreuzbergError::parsing(format!(
            "All synchronous extractors failed for MIME '{}'. Attempts: {}",
            validated_mime,
            failures.join(" | ")
        ))),
    }
}
