//! Python PostProcessor wrapper bridge with GIL management.
//!
//! Provides a Rust wrapper that makes Python PostProcessors usable from Rust by implementing
//! the `PostProcessor` trait and managing the FFI boundary with proper GIL handling.

use async_trait::async_trait;
use pyo3::prelude::*;
use pyo3::types::PyDict;
use std::sync::Arc;

use kreuzberg::core::config::ExtractionConfig;
use kreuzberg::plugins::registry::get_post_processor_registry;
use kreuzberg::plugins::{Plugin, PostProcessor, ProcessingStage};
use kreuzberg::types::ExtractionResult;
use kreuzberg::{KreuzbergError, Result};

use super::common::{json_value_to_py, python_to_json, validate_plugin_object};

/// Wrapper that makes a Python PostProcessor usable from Rust.
///
/// This struct implements the Rust `PostProcessor` trait by forwarding calls
/// to a Python object via PyO3, bridging the FFI boundary with proper
/// GIL management and type conversions.
pub struct PythonPostProcessor {
    /// Python object implementing the PostProcessor protocol
    python_obj: Py<PyAny>,
    /// Cached processor name (to avoid repeated GIL acquisition)
    name: String,
    /// Processing stage (cached from Python or default to Middle)
    stage: ProcessingStage,
}

impl PythonPostProcessor {
    /// Create a new Python PostProcessor wrapper.
    ///
    /// # Arguments
    ///
    /// * `py` - Python GIL token
    /// * `python_obj` - Python object implementing the processor protocol
    ///
    /// # Returns
    ///
    /// A new `PythonPostProcessor` or an error if the Python object is invalid.
    ///
    /// # Errors
    ///
    /// Returns an error if:
    /// - Python object doesn't have required methods
    /// - Method calls fail during initialization
    pub fn new(py: Python<'_>, python_obj: Py<PyAny>) -> PyResult<Self> {
        let obj = python_obj.bind(py);

        validate_plugin_object(obj, "PostProcessor", &["name", "process"])?;

        let name: String = obj.call_method0("name")?.extract()?;
        if name.is_empty() {
            return Err(pyo3::exceptions::PyValueError::new_err(
                "PostProcessor name cannot be empty",
            ));
        }

        let stage = if obj.hasattr("processing_stage")? {
            let stage_str: String = obj.call_method0("processing_stage")?.extract()?;
            match stage_str.to_lowercase().as_str() {
                "early" => ProcessingStage::Early,
                "middle" => ProcessingStage::Middle,
                "late" => ProcessingStage::Late,
                _ => ProcessingStage::Middle,
            }
        } else {
            ProcessingStage::Middle
        };

        Ok(Self {
            python_obj,
            name,
            stage,
        })
    }
}

impl Plugin for PythonPostProcessor {
    fn name(&self) -> &str {
        &self.name
    }

    fn version(&self) -> String {
        Python::attach(|py| {
            self.python_obj
                .bind(py)
                .getattr("version")
                .and_then(|v| v.call0())
                .and_then(|v| v.extract::<String>())
                .unwrap_or_else(|_| "1.0.0".to_string())
        })
    }

    fn initialize(&self) -> Result<()> {
        Python::attach(|py| {
            let obj = self.python_obj.bind(py);
            if obj.hasattr("initialize")? {
                obj.call_method0("initialize")?;
            }
            Ok(())
        })
        .map_err(|e: PyErr| KreuzbergError::Plugin {
            message: format!("Failed to initialize Python PostProcessor '{}': {}", self.name, e),
            plugin_name: self.name.clone(),
        })
    }

    fn shutdown(&self) -> Result<()> {
        Python::attach(|py| {
            let obj = self.python_obj.bind(py);
            if obj.hasattr("shutdown")? {
                obj.call_method0("shutdown")?;
            }
            Ok(())
        })
        .map_err(|e: PyErr| KreuzbergError::Plugin {
            message: format!("Failed to shutdown Python PostProcessor '{}': {}", self.name, e),
            plugin_name: self.name.clone(),
        })
    }
}

#[async_trait]
impl PostProcessor for PythonPostProcessor {
    async fn process(&self, result: &mut ExtractionResult, _config: &ExtractionConfig) -> Result<()> {
        let processor_name = self.name.clone();

        let updated_result = tokio::task::block_in_place(|| {
            Python::attach(|py| {
                let obj = self.python_obj.bind(py);

                let result_dict = extraction_result_to_dict(py, result).map_err(|e| KreuzbergError::Plugin {
                    message: format!("Failed to convert ExtractionResult to Python dict: {}", e),
                    plugin_name: processor_name.clone(),
                })?;

                let py_result = result_dict.bind(py);
                let processed = obj
                    .call_method1("process", (py_result,))
                    .map_err(|e| KreuzbergError::Plugin {
                        message: format!("Python PostProcessor '{}' failed during process: {}", processor_name, e),
                        plugin_name: processor_name.clone(),
                    })?;

                let processed_dict = processed.cast_into::<PyDict>().map_err(|e| KreuzbergError::Plugin {
                    message: format!("PostProcessor did not return a dict: {}", e),
                    plugin_name: processor_name.clone(),
                })?;

                let mut updated_result = result.clone();
                merge_dict_to_extraction_result(py, &processed_dict, &mut updated_result)?;

                Ok::<ExtractionResult, KreuzbergError>(updated_result)
            })
        })?;

        *result = updated_result;
        Ok(())
    }

    fn processing_stage(&self) -> ProcessingStage {
        self.stage
    }
}

/// Convert Rust ExtractionResult to Python dict.
///
/// This creates a Python dict that can be passed to Python processors:
/// ```python
/// {
///     "content": "extracted text",
///     "mime_type": "application/pdf",
///     "metadata": {"key": "value"},
///     "tables": [...]
/// }
/// ```
fn extraction_result_to_dict(py: Python<'_>, result: &ExtractionResult) -> PyResult<Py<PyDict>> {
    let dict = PyDict::new(py);

    dict.set_item("content", &result.content)?;

    dict.set_item("mime_type", &result.mime_type)?;

    let metadata_dict = PyDict::new(py);

    if let Some(title) = &result.metadata.title {
        metadata_dict.set_item("title", title)?;
    }
    if let Some(subject) = &result.metadata.subject {
        metadata_dict.set_item("subject", subject)?;
    }
    if let Some(authors) = &result.metadata.authors {
        metadata_dict.set_item("authors", authors)?;
    }
    if let Some(keywords) = &result.metadata.keywords {
        metadata_dict.set_item("keywords", keywords)?;
    }
    if let Some(language) = &result.metadata.language {
        metadata_dict.set_item("language", language)?;
    }
    if let Some(created_at) = &result.metadata.created_at {
        metadata_dict.set_item("created_at", created_at)?;
    }
    if let Some(modified_at) = &result.metadata.modified_at {
        metadata_dict.set_item("modified_at", modified_at)?;
    }
    if let Some(created_by) = &result.metadata.created_by {
        metadata_dict.set_item("created_by", created_by)?;
    }
    if let Some(modified_by) = &result.metadata.modified_by {
        metadata_dict.set_item("modified_by", modified_by)?;
    }
    if let Some(created_at) = &result.metadata.created_at {
        metadata_dict.set_item("created_at", created_at)?;
    }

    for (key, value) in &result.metadata.additional {
        let py_value = json_value_to_py(py, value)?;
        metadata_dict.set_item(key, py_value)?;
    }

    dict.set_item("metadata", metadata_dict)?;

    dict.set_item("tables", pyo3::types::PyList::empty(py))?;

    Ok(dict.unbind())
}

/// Merge Python dict back into ExtractionResult.
///
/// This updates the result in place, preserving existing fields and only
/// merging new metadata fields. Does not overwrite existing metadata keys.
fn merge_dict_to_extraction_result(
    _py: Python<'_>,
    dict: &Bound<'_, PyDict>,
    result: &mut ExtractionResult,
) -> Result<()> {
    if let Some(val) = dict.get_item("content").map_err(|e| KreuzbergError::Plugin {
        message: format!("Failed to get 'content' from result dict: {}", e),
        plugin_name: "python".to_string(),
    })? && !val.is_none()
    {
        result.content = val.extract().map_err(|e| KreuzbergError::Plugin {
            message: format!("PostProcessor returned invalid 'content': {}", e),
            plugin_name: "python".to_string(),
        })?;
    }

    if let Some(m) = dict.get_item("metadata").map_err(|e| KreuzbergError::Plugin {
        message: format!("Failed to get 'metadata' from result dict: {}", e),
        plugin_name: "python".to_string(),
    })? && !m.is_none()
        && let Ok(meta_dict) = m.cast_into::<PyDict>()
    {
        for (key, value) in meta_dict.iter() {
            let key_str: String = key.extract().map_err(|_| KreuzbergError::Plugin {
                message: "Metadata keys must be strings".to_string(),
                plugin_name: "python".to_string(),
            })?;

            let json_value = python_to_json(&value)?;
            result.metadata.additional.insert(key_str, json_value);
        }
    }

    Ok(())
}

/// Register a Python PostProcessor with the Rust core.
///
/// This function validates the Python processor object, wraps it in a Rust
/// `PostProcessor` implementation, and registers it with the global PostProcessor
/// registry. Once registered, the processor will be called automatically after
/// extraction to enrich results with metadata, entities, keywords, etc.
///
/// # Arguments
///
/// * `processor` - Python object implementing the PostProcessor protocol
///
/// # Required Methods on Python PostProcessor
///
/// The Python processor must implement:
/// - `name() -> str` - Return processor name
/// - `process(result: dict) -> dict` - Process and enrich the extraction result
///
/// # Optional Methods
///
/// - `processing_stage() -> str` - Return "early", "middle", or "late" (defaults to "middle")
/// - `initialize()` - Called when processor is registered (e.g., load ML models)
/// - `shutdown()` - Called when processor is unregistered
/// - `version() -> str` - Processor version (defaults to "1.0.0")
///
/// # Example
///
/// ```python
/// from kreuzberg import register_post_processor
///
/// class EntityExtractor:
///     def name(self) -> str:
///         return "entity_extraction"
///
///     def processing_stage(self) -> str:
///         return "early"
///
///     def process(self, result: dict) -> dict:
///         # Extract entities from result["content"]
///         entities = {"PERSON": ["John Doe"], "ORG": ["Microsoft"]}
///         result["metadata"]["entities"] = entities
///         return result
///
/// register_post_processor(EntityExtractor())
/// ```
///
/// # Errors
///
/// Returns an error if:
/// - Processor is missing required methods
/// - Processor name is empty or duplicate
/// - Registration fails
#[pyfunction]
pub fn register_post_processor(py: Python<'_>, processor: Py<PyAny>) -> PyResult<()> {
    let rust_processor = PythonPostProcessor::new(py, processor)?;
    let processor_name = rust_processor.name().to_string();

    let arc_processor: Arc<dyn PostProcessor> = Arc::new(rust_processor);

    py.detach(|| {
        let registry = get_post_processor_registry();
        let mut registry = registry.write().map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!(
                "Failed to acquire write lock on PostProcessor registry: {}",
                e
            ))
        })?;

        registry.register(arc_processor, 0).map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!(
                "Failed to register PostProcessor '{}': {}",
                processor_name, e
            ))
        })
    })?;

    Ok(())
}

/// Unregister a PostProcessor by name.
///
/// Removes a previously registered processor from the global registry and
/// calls its `shutdown()` method to release resources.
///
/// # Arguments
///
/// * `name` - Processor name to unregister
///
/// # Example
///
/// ```python
/// from kreuzberg import register_post_processor, unregister_post_processor
///
/// class MyProcessor:
///     def name(self) -> str:
///         return "my_processor"
///
///     def process(self, result: dict) -> dict:
///         return result
///
/// register_post_processor(MyProcessor())
/// # ... use processor ...
/// unregister_post_processor("my_processor")
/// ```
#[pyfunction]
pub fn unregister_post_processor(py: Python<'_>, name: &str) -> PyResult<()> {
    py.detach(|| {
        let registry = get_post_processor_registry();
        let mut registry = registry.write().map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!(
                "Failed to acquire write lock on PostProcessor registry: {}",
                e
            ))
        })?;

        registry.remove(name).map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!("Failed to unregister PostProcessor '{}': {}", name, e))
        })
    })?;

    Ok(())
}

/// Clear all registered PostProcessors.
///
/// Removes all processors from the global registry and calls their `shutdown()`
/// methods. Useful for test cleanup or resetting state.
///
/// # Example
///
/// ```python
/// from kreuzberg import clear_post_processors
///
/// # In pytest fixture or test cleanup
/// clear_post_processors()
/// ```
#[pyfunction]
pub fn clear_post_processors(py: Python<'_>) -> PyResult<()> {
    py.detach(|| {
        let registry = get_post_processor_registry();
        let mut registry = registry.write().map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!(
                "Failed to acquire write lock on PostProcessor registry: {}",
                e
            ))
        })?;

        registry.shutdown_all().map_err(|e| {
            pyo3::exceptions::PyRuntimeError::new_err(format!("Failed to clear PostProcessor registry: {}", e))
        })
    })?;

    Ok(())
}

/// List all registered post-processor names.
///
/// Returns a list of all post-processor names currently registered in the global registry.
///
/// # Returns
///
/// List of post-processor names.
///
/// # Example
///
/// ```python
/// from kreuzberg import list_post_processors, register_post_processor, clear_post_processors
///
/// class MyProcessor:
///     def name(self) -> str:
///         return "my_processor"
///
///     def process(self, result: dict) -> dict:
///         return result
///
/// # Register processor
/// register_post_processor(MyProcessor())
///
/// # List processors
/// processors = list_post_processors()
/// assert "my_processor" in processors
///
/// # Cleanup
/// clear_post_processors()
/// ```
#[pyfunction]
pub fn list_post_processors() -> PyResult<Vec<String>> {
    kreuzberg::plugins::list_post_processors().map_err(|e| pyo3::exceptions::PyRuntimeError::new_err(e.to_string()))
}
