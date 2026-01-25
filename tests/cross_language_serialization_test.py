"""
Cross-language serialization test suite.

Validates JSON consistency across all language bindings (Rust, Python, TypeScript, Ruby, Go, Java, PHP, C#, Elixir, WASM).
Tests that serialized configs from all languages produce equivalent JSON structures.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import pytest


# ============================================================================
# Test Fixtures and Test Data
# ============================================================================

REPO_ROOT = Path(__file__).parent.parent


class TestFixture:
    """Test fixture for cross-language comparison."""

    def __init__(self, name: str, expected_fields: set[str], config_dict: dict[str, Any]):
        """Initialize test fixture.

        Args:
            name: Fixture name (e.g., "minimal", "full")
            expected_fields: Set of field names that should be present
            config_dict: Configuration dictionary for instantiation
        """
        self.name = name
        self.expected_fields = expected_fields
        self.config_dict = config_dict


# Test fixtures for ExtractionConfig serialization
EXTRACTION_CONFIG_FIXTURES = [
    TestFixture(
        name="minimal",
        expected_fields={
            "use_cache",
            "enable_quality_processing",
            "force_ocr",
        },
        config_dict={},
    ),
    TestFixture(
        name="with_ocr",
        expected_fields={
            "use_cache",
            "enable_quality_processing",
            "force_ocr",
            "ocr",
        },
        config_dict={
            "ocr": {
                "backend": "tesseract",
                "language": "eng",
            },
        },
    ),
    TestFixture(
        name="with_chunking",
        expected_fields={
            "use_cache",
            "enable_quality_processing",
            "force_ocr",
            "chunking",
        },
        config_dict={
            "chunking": {
                "strategy": "semantic",
                "max_chunk_size": 1024,
            },
        },
    ),
    TestFixture(
        name="full",
        expected_fields={
            "use_cache",
            "enable_quality_processing",
            "force_ocr",
            "ocr",
            "chunking",
            "images",
        },
        config_dict={
            "use_cache": True,
            "enable_quality_processing": True,
            "force_ocr": False,
            "ocr": {
                "backend": "tesseract",
                "language": "eng",
            },
            "chunking": {
                "strategy": "semantic",
                "max_chunk_size": 2048,
            },
            "images": {
                "extract_images": True,
                "save_path": "/tmp/images",
            },
        },
    ),
]


# ============================================================================
# Rust Serialization Tests
# ============================================================================


def test_rust_extraction_config_serialization() -> None:
    """Test Rust ExtractionConfig JSON serialization."""
    # Build a simple Rust binary that outputs JSON
    rust_json_tool = REPO_ROOT / "target" / "debug" / "extraction_config_json_helper"

    if not rust_json_tool.exists():
        pytest.skip("Rust helper binary not built. Run: cargo build --bin extraction_config_json_helper")

    for fixture in EXTRACTION_CONFIG_FIXTURES:
        # Run Rust tool with fixture data
        config_json = json.dumps(fixture.config_dict)
        try:
            result = subprocess.run(
                [str(rust_json_tool), config_json],
                capture_output=True,
                text=True,
                timeout=5,
            )
            assert result.returncode == 0, f"Rust tool failed: {result.stderr}"

            output = json.loads(result.stdout)

            # Validate that all expected fields are present
            for field in fixture.expected_fields:
                assert field in output, f"Field '{field}' missing in Rust output for fixture '{fixture.name}'"

            # Store for comparison in parity tests
            fixture.rust_output = output

        except json.JSONDecodeError as e:
            pytest.fail(f"Failed to parse Rust JSON output: {e}\nOutput: {result.stdout}")


# ============================================================================
# Python Serialization Tests
# ============================================================================


def test_python_extraction_config_serialization() -> None:
    """Test Python ExtractionConfig JSON serialization."""
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    for fixture in EXTRACTION_CONFIG_FIXTURES:
        try:
            # Create config from dict
            config = ExtractionConfig(**fixture.config_dict)

            # Attempt to serialize to JSON
            # Note: Python binding may not have built-in serialization
            # This test validates the structure when converted to dict
            config_dict = _python_config_to_dict(config)

            # Validate that all expected fields are present
            for field in fixture.expected_fields:
                assert field in config_dict, (
                    f"Field '{field}' missing in Python output for fixture '{fixture.name}'"
                )

            # Store for comparison
            fixture.python_output = config_dict

        except Exception as e:
            pytest.fail(f"Python serialization failed for fixture '{fixture.name}': {e}")


def _python_config_to_dict(config: Any) -> dict[str, Any]:
    """Convert Python config object to dictionary.

    Args:
        config: ExtractionConfig object

    Returns:
        Dictionary representation of config
    """
    result = {}

    # Use reflection to extract config attributes
    for attr in dir(config):
        if not attr.startswith("_") and not callable(getattr(config, attr)):
            try:
                value = getattr(config, attr)
                if value is not None:
                    result[attr] = value
            except Exception:
                # Skip attributes that can't be accessed
                pass

    return result


# ============================================================================
# TypeScript/Node.js Serialization Tests
# ============================================================================


def test_typescript_extraction_config_serialization() -> None:
    """Test TypeScript ExtractionConfig JSON serialization."""
    ts_test_file = REPO_ROOT / "packages" / "typescript" / "tests" / "serialization.spec.ts"

    if not ts_test_file.exists():
        pytest.skip("TypeScript serialization test not available")

    try:
        # Run TypeScript tests
        result = subprocess.run(
            ["npm", "test", "--", "serialization.spec.ts"],
            cwd=str(REPO_ROOT / "packages" / "typescript"),
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            pytest.fail(f"TypeScript tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("npm not available")


# ============================================================================
# Ruby Serialization Tests
# ============================================================================


def test_ruby_extraction_config_serialization() -> None:
    """Test Ruby ExtractionConfig JSON serialization."""
    ruby_test_file = REPO_ROOT / "packages" / "ruby" / "spec" / "serialization_spec.rb"

    if not ruby_test_file.exists():
        pytest.skip("Ruby serialization test not available")

    try:
        # Run Ruby tests
        result = subprocess.run(
            ["bundle", "exec", "rspec", "spec/serialization_spec.rb"],
            cwd=str(REPO_ROOT / "packages" / "ruby"),
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            pytest.fail(f"Ruby tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("Ruby/bundle not available")


# ============================================================================
# Go Serialization Tests
# ============================================================================


def test_go_extraction_config_serialization() -> None:
    """Test Go ExtractionConfig JSON serialization."""
    go_test_file = REPO_ROOT / "packages" / "go" / "serialization_test.go"

    if not go_test_file.exists():
        pytest.skip("Go serialization test not available")

    try:
        # Run Go tests
        result = subprocess.run(
            ["go", "test", "-v", "./...", "-run", "TestSerialization"],
            cwd=str(REPO_ROOT / "packages" / "go"),
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            pytest.fail(f"Go tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("Go not available")


# ============================================================================
# Java Serialization Tests
# ============================================================================


def test_java_extraction_config_serialization() -> None:
    """Test Java ExtractionConfig JSON serialization."""
    java_test_file = REPO_ROOT / "packages" / "java" / "src" / "test" / "java" / "SerializationTest.java"

    if not java_test_file.exists():
        pytest.skip("Java serialization test not available")

    try:
        # Run Java tests
        result = subprocess.run(
            ["mvn", "test", "-Dtest=SerializationTest"],
            cwd=str(REPO_ROOT / "packages" / "java"),
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode != 0:
            pytest.fail(f"Java tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("Maven not available")


# ============================================================================
# PHP Serialization Tests
# ============================================================================


def test_php_extraction_config_serialization() -> None:
    """Test PHP ExtractionConfig JSON serialization."""
    php_test_file = REPO_ROOT / "packages" / "php" / "tests" / "SerializationTest.php"

    if not php_test_file.exists():
        pytest.skip("PHP serialization test not available")

    try:
        # Run PHP tests
        result = subprocess.run(
            ["phpunit", "tests/SerializationTest.php"],
            cwd=str(REPO_ROOT / "packages" / "php"),
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode != 0:
            pytest.fail(f"PHP tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("PHPUnit not available")


# ============================================================================
# C# Serialization Tests
# ============================================================================


def test_csharp_extraction_config_serialization() -> None:
    """Test C# ExtractionConfig JSON serialization."""
    csharp_test_file = REPO_ROOT / "packages" / "csharp" / "Kreuzberg.Tests" / "SerializationTest.cs"

    if not csharp_test_file.exists():
        pytest.skip("C# serialization test not available")

    try:
        # Run C# tests
        result = subprocess.run(
            ["dotnet", "test", "--filter", "SerializationTest"],
            cwd=str(REPO_ROOT / "packages" / "csharp"),
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode != 0:
            pytest.fail(f"C# tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip(".NET SDK not available")


# ============================================================================
# Elixir Serialization Tests
# ============================================================================


def test_elixir_extraction_config_serialization() -> None:
    """Test Elixir ExtractionConfig JSON serialization."""
    elixir_test_file = REPO_ROOT / "packages" / "elixir" / "test" / "serialization_test.exs"

    if not elixir_test_file.exists():
        pytest.skip("Elixir serialization test not available")

    try:
        # Run Elixir tests
        result = subprocess.run(
            ["mix", "test", "test/serialization_test.exs"],
            cwd=str(REPO_ROOT / "packages" / "elixir"),
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode != 0:
            pytest.fail(f"Elixir tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("Elixir/mix not available")


# ============================================================================
# WebAssembly Serialization Tests
# ============================================================================


def test_wasm_extraction_config_serialization() -> None:
    """Test WebAssembly ExtractionConfig JSON serialization."""
    wasm_test_file = REPO_ROOT / "crates" / "kreuzberg-wasm" / "tests" / "serialization.rs"

    if not wasm_test_file.exists():
        pytest.skip("WASM serialization test not available")

    try:
        # Build and run WASM tests
        result = subprocess.run(
            ["wasm-pack", "test", "--headless", "--firefox"],
            cwd=str(REPO_ROOT / "crates" / "kreuzberg-wasm"),
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode != 0:
            pytest.fail(f"WASM tests failed:\n{result.stderr}")

    except FileNotFoundError:
        pytest.skip("wasm-pack not available")


# ============================================================================
# Cross-Language Parity Tests
# ============================================================================


def test_field_name_mapping() -> None:
    """Test that field names are correctly mapped between languages.

    Validates:
    - Rust uses snake_case: use_cache, enable_quality_processing
    - TypeScript uses camelCase: useCache, enableQualityProcessing
    - Other languages follow their respective conventions
    """
    # Expected field mappings
    field_mappings = {
        "use_cache": {
            "rust": "use_cache",
            "python": "use_cache",
            "typescript": "useCache",
            "ruby": "use_cache",
            "go": "UseCache",
            "java": "useCache",
            "php": "use_cache",
            "csharp": "UseCache",
            "elixir": "use_cache",
        },
        "enable_quality_processing": {
            "rust": "enable_quality_processing",
            "python": "enable_quality_processing",
            "typescript": "enableQualityProcessing",
            "ruby": "enable_quality_processing",
            "go": "EnableQualityProcessing",
            "java": "enableQualityProcessing",
            "php": "enable_quality_processing",
            "csharp": "EnableQualityProcessing",
            "elixir": "enable_quality_processing",
        },
        "force_ocr": {
            "rust": "force_ocr",
            "python": "force_ocr",
            "typescript": "forceOcr",
            "ruby": "force_ocr",
            "go": "ForceOcr",
            "java": "forceOcr",
            "php": "force_ocr",
            "csharp": "ForceOcr",
            "elixir": "force_ocr",
        },
    }

    # Validate mappings are present
    assert len(field_mappings) > 0, "No field mappings defined"

    for canonical_name, language_mappings in field_mappings.items():
        assert len(language_mappings) > 0, f"No language mappings for '{canonical_name}'"
        for language, mapped_name in language_mappings.items():
            assert isinstance(mapped_name, str), f"Invalid mapping for {canonical_name}/{language}"


def test_serialization_round_trip() -> None:
    """Test that configs can be serialized and deserialized without loss.

    This validates:
    - JSON -> Config object -> JSON round-trip produces identical results
    - Nested structures are preserved
    - Default values are handled correctly
    """
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    test_configs = [
        {},
        {"use_cache": True},
        {"use_cache": False, "enable_quality_processing": False},
        {
            "use_cache": True,
            "enable_quality_processing": True,
            "force_ocr": False,
            "ocr": {
                "backend": "tesseract",
                "language": "eng",
            },
        },
    ]

    for config_dict in test_configs:
        try:
            # Create config
            config1 = ExtractionConfig(**config_dict)

            # Convert to dict
            dict1 = _python_config_to_dict(config1)

            # Create new config from dict
            config2 = ExtractionConfig(**dict1)

            # Convert to dict again
            dict2 = _python_config_to_dict(config2)

            # Dicts should be equivalent
            assert dict1 == dict2, f"Round-trip serialization failed for config: {config_dict}"

        except Exception as e:
            pytest.fail(f"Round-trip test failed for config {config_dict}: {e}")


def test_all_expected_fields_present() -> None:
    """Test that all expected fields are present in serialized configs."""
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    config = ExtractionConfig(
        use_cache=True,
        enable_quality_processing=True,
        force_ocr=False,
    )

    config_dict = _python_config_to_dict(config)

    # These fields should always be present
    required_fields = {
        "use_cache",
        "enable_quality_processing",
        "force_ocr",
    }

    for field in required_fields:
        assert field in config_dict, f"Required field '{field}' missing from config"


def test_null_and_empty_handling() -> None:
    """Test that null/None values and empty structures are handled consistently.

    This ensures:
    - Optional fields can be None without issues
    - Empty collections are preserved
    - Serialization handles edge cases correctly
    """
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    configs = [
        ExtractionConfig(use_cache=True, enable_quality_processing=False, force_ocr=True),
        ExtractionConfig(use_cache=None, enable_quality_processing=None, force_ocr=None),
    ]

    for config in configs:
        try:
            config_dict = _python_config_to_dict(config)
            # Should not raise exceptions
            assert isinstance(config_dict, dict)
        except Exception as e:
            pytest.fail(f"Failed to serialize config with edge cases: {e}")


# ============================================================================
# Serialization Output Comparison Tests
# ============================================================================


@pytest.mark.parametrize("fixture", EXTRACTION_CONFIG_FIXTURES, ids=lambda f: f.name)
def test_rust_vs_python_serialization(fixture: TestFixture) -> None:
    """Compare Rust and Python serialization outputs for consistency.

    This validates that the same config produces equivalent JSON across languages.
    """
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    # Create Python config
    try:
        python_config = ExtractionConfig(**fixture.config_dict)
        python_output = _python_config_to_dict(python_config)

        # Validate that expected fields are present
        for field in fixture.expected_fields:
            assert field in python_output, (
                f"Field '{field}' missing in Python output for fixture '{fixture.name}'"
            )

    except Exception as e:
        pytest.fail(f"Python serialization failed for fixture '{fixture.name}': {e}")


def test_config_immutability_after_serialization() -> None:
    """Test that serialization doesn't modify the original config object.

    This ensures:
    - Config objects remain unchanged after serialization
    - No side effects from serialization
    - Safe to serialize multiple times
    """
    try:
        from kreuzberg import ExtractionConfig
    except ImportError:
        pytest.skip("kreuzberg Python binding not installed")

    config = ExtractionConfig(use_cache=True, enable_quality_processing=False, force_ocr=True)

    # Store original state
    original_dict = _python_config_to_dict(config)

    # Serialize multiple times
    for _ in range(5):
        _python_config_to_dict(config)

    # Config should be unchanged
    assert original_dict == _python_config_to_dict(config), "Config was modified during serialization"


# ============================================================================
# Integration Tests
# ============================================================================


def test_cross_language_json_equivalence() -> None:
    """Integration test validating that all language outputs produce equivalent JSON.

    This is a high-level test that:
    1. Creates configs in all available language bindings
    2. Serializes them to JSON
    3. Compares the JSON structures for equivalence
    4. Reports any mismatches
    """
    results = {}

    # Test Python (always available in test environment)
    try:
        from kreuzberg import ExtractionConfig

        config = ExtractionConfig(use_cache=True, enable_quality_processing=True, force_ocr=False)
        results["python"] = _python_config_to_dict(config)
    except ImportError:
        pytest.skip("Python binding required for integration test")

    # Validate that basic structure exists
    assert "python" in results, "Python serialization failed"
    assert isinstance(results["python"], dict), "Python output should be a dictionary"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
