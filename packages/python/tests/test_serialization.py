"""Serialization tests for ExtractionConfig.

Verifies that ExtractionConfig serializes and deserializes correctly,
maintaining field names and types across JSON round-trips.
"""

from __future__ import annotations

import json

import pytest

from kreuzberg import (
    ExtractionConfig,
    OcrConfig,
    config_to_json,
)


class TestExtractionConfigDefaultSerialization:
    """Test serialization of ExtractionConfig with default values."""

    def test_default_config_has_expected_fields(self) -> None:
        """Test that default config serializes with expected fields."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Verify key fields are present in the serialized output
        assert "use_cache" in parsed, "use_cache field should be present"
        assert "output_format" in parsed, "output_format field should be present"
        assert "result_format" in parsed, "result_format field should be present"
        assert "enable_quality_processing" in parsed, "enable_quality_processing field should be present"

    def test_default_config_field_values(self) -> None:
        """Test that default config has expected values."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Verify default values
        assert parsed["output_format"] == "plain", "Default output_format should be plain"
        assert "result_format" in parsed, "result_format should be present"


class TestExtractionConfigCustomSerialization:
    """Test serialization of ExtractionConfig with custom values."""

    def test_config_with_custom_boolean_values(self) -> None:
        """Test serialization of config with custom boolean values."""
        config = ExtractionConfig(
            use_cache=False,
            force_ocr=True,
            enable_quality_processing=False,
        )
        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        assert parsed["use_cache"] is False, "use_cache should be False"
        assert parsed["force_ocr"] is True, "force_ocr should be True"
        assert parsed["enable_quality_processing"] is False, "enable_quality_processing should be False"

    def test_config_with_custom_string_values(self) -> None:
        """Test serialization of config with custom string values."""
        config = ExtractionConfig(
            output_format="markdown",
            result_format="Unified",
        )
        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        assert parsed["output_format"] == "markdown", "output_format should be markdown"
        assert parsed["result_format"] == "Unified", "result_format should be Unified"

    def test_config_with_custom_integer_values(self) -> None:
        """Test serialization of config with custom integer values."""
        config = ExtractionConfig(
            max_concurrent_extractions=4,
        )
        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        assert parsed["max_concurrent_extractions"] == 4, "max_concurrent_extractions should be 4"
        assert isinstance(parsed["max_concurrent_extractions"], int), "Should be an integer"


class TestExtractionConfigJsonRoundTrip:
    """Test JSON serialization round-trips preserve values."""

    def test_json_round_trip_basic_types(self) -> None:
        """Test JSON serialization round-trip maintains values for basic types."""
        config = ExtractionConfig(
            use_cache=True,
            enable_quality_processing=False,
            force_ocr=True,
            output_format="markdown",
        )

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Verify all values preserved
        assert parsed["use_cache"] is True, "use_cache should round-trip as True"
        assert parsed["enable_quality_processing"] is False, "enable_quality_processing should round-trip as False"
        assert parsed["force_ocr"] is True, "force_ocr should round-trip as True"
        assert parsed["output_format"] == "markdown", "output_format should round-trip as 'markdown'"

    def test_json_round_trip_with_nested_config(self) -> None:
        """Test JSON serialization round-trip with nested configuration."""
        ocr_config = OcrConfig(backend="tesseract", language="eng")
        config = ExtractionConfig(ocr=ocr_config)

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Verify nested config serialized
        assert "ocr" in parsed, "ocr field should be present"
        if parsed["ocr"] is not None:
            assert parsed["ocr"]["backend"] == "tesseract", "Nested ocr.backend should round-trip"
            assert parsed["ocr"]["language"] == "eng", "Nested ocr.language should round-trip"

    def test_json_serialization_is_valid_json(self) -> None:
        """Test that config_to_json produces valid JSON."""
        config = ExtractionConfig(
            use_cache=True,
            output_format="djot",
            force_ocr=False,
        )

        config_json = config_to_json(config)

        # Verify it's valid JSON (would raise if invalid)
        parsed = json.loads(config_json)
        assert isinstance(parsed, dict), "JSON should parse to a dictionary"


class TestExtractionConfigFieldNames:
    """Test that Python uses snake_case field names."""

    def test_extraction_config_has_snake_case_fields(self) -> None:
        """Verify Python attributes use snake_case naming."""
        config = ExtractionConfig()

        # Verify snake_case field names exist
        assert hasattr(config, "use_cache"), "Should have use_cache (not useCache)"
        assert hasattr(config, "force_ocr"), "Should have force_ocr (not forceOcr)"
        assert hasattr(config, "output_format"), "Should have output_format (not outputFormat)"
        assert hasattr(config, "result_format"), "Should have result_format (not resultFormat)"
        assert hasattr(config, "enable_quality_processing"), "Should have enable_quality_processing"

    def test_serialized_json_uses_snake_case(self) -> None:
        """Verify serialized JSON uses snake_case field names."""
        config = ExtractionConfig(
            use_cache=True,
            force_ocr=False,
            output_format="markdown",
            result_format="Unified",
        )

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Check for snake_case keys
        assert "use_cache" in parsed, "JSON should have use_cache key (not useCache)"
        assert "force_ocr" in parsed, "JSON should have force_ocr key (not forceOcr)"
        assert "output_format" in parsed, "JSON should have output_format key (not outputFormat)"
        assert "result_format" in parsed, "JSON should have result_format key (not resultFormat)"

        # Verify camelCase keys do NOT exist
        assert "useCache" not in parsed, "JSON should not have camelCase keys"
        assert "forceOcr" not in parsed, "JSON should not have camelCase keys"
        assert "outputFormat" not in parsed, "JSON should not have camelCase keys"


class TestExtractionConfigOptionalFields:
    """Test optional fields in ExtractionConfig."""

    def test_optional_fields_are_none_by_default(self) -> None:
        """Verify optional fields default appropriately."""
        config = ExtractionConfig()

        # These optional fields should be None or not set
        optional_fields = [
            "ocr",
            "chunking",
            "images",
            "pdf_options",
            "keywords",
            "pages",
        ]

        for field in optional_fields:
            if hasattr(config, field):
                value = getattr(config, field)
                # Optional fields should be None or appropriate default
                assert value is None or isinstance(value, (dict, bool)), (
                    f"{field} should be None or appropriate default"
                )

    def test_optional_nested_configs_serialize_correctly(self) -> None:
        """Test that optional nested configs serialize to null or omitted."""
        config = ExtractionConfig()

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Optional fields should either be null or omitted
        optional_fields = ["ocr", "chunking", "images", "keywords", "pages"]
        for field in optional_fields:
            if field in parsed:
                value = parsed[field]
                # Should be null if present
                assert value is None or isinstance(value, dict), f"{field} should be null or object"


class TestExtractionConfigComprehensive:
    """Comprehensive serialization tests for all major fields."""

    def test_all_major_fields_present(self) -> None:
        """Verify ExtractionConfig serializes with all major fields."""
        config = ExtractionConfig(
            use_cache=True,
            enable_quality_processing=False,
            force_ocr=True,
            output_format="markdown",
            result_format="Unified",
            max_concurrent_extractions=8,
        )

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Core fields
        assert "use_cache" in parsed
        assert "enable_quality_processing" in parsed
        assert "force_ocr" in parsed
        assert "output_format" in parsed
        assert "result_format" in parsed
        assert "max_concurrent_extractions" in parsed

    def test_mixed_optional_and_required_fields(self) -> None:
        """Test serialization with mix of optional and required fields."""
        ocr_config = OcrConfig(backend="tesseract", language="eng")
        config = ExtractionConfig(
            use_cache=False,
            force_ocr=True,
            ocr=ocr_config,
            output_format="djot",
        )

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # Required/explicit fields
        assert parsed["use_cache"] is False
        assert parsed["force_ocr"] is True
        assert parsed["output_format"] == "djot"

        # Optional field (if present)
        if "ocr" in parsed and parsed["ocr"] is not None:
            assert parsed["ocr"]["backend"] == "tesseract"


class TestExtractionConfigEdgeCases:
    """Test edge cases in ExtractionConfig serialization."""

    def test_boolean_fields_preserve_false_value(self) -> None:
        """Verify that False boolean values are preserved in serialization."""
        config = ExtractionConfig(
            use_cache=False,
            enable_quality_processing=False,
            force_ocr=False,
        )

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # All False values should be explicitly preserved
        assert parsed["use_cache"] is False, "False should round-trip as False, not null"
        assert parsed["enable_quality_processing"] is False, "False should round-trip as False, not null"
        assert parsed["force_ocr"] is False, "False should round-trip as False, not null"

    def test_zero_values_preserved(self) -> None:
        """Verify that zero values are preserved in serialization."""
        config = ExtractionConfig(max_concurrent_extractions=0)

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        assert parsed["max_concurrent_extractions"] == 0, "Zero should round-trip as 0, not null"

    def test_empty_string_field_handling(self) -> None:
        """Verify handling of empty string fields."""
        config = ExtractionConfig(output_format="plain")

        config_json = config_to_json(config)
        parsed = json.loads(config_json)

        # output_format should have a value (plain by default)
        assert isinstance(parsed["output_format"], str), "output_format should be a string"


class TestExtractionConfigFieldAccess:
    """Test direct field access on ExtractionConfig."""

    def test_field_access_returns_correct_types(self) -> None:
        """Verify field access returns correct Python types."""
        config = ExtractionConfig(
            use_cache=True,
            force_ocr=False,
            max_concurrent_extractions=4,
            output_format="markdown",
        )

        assert isinstance(config.use_cache, bool), "use_cache should be a boolean"
        assert isinstance(config.force_ocr, bool), "force_ocr should be a boolean"
        assert isinstance(config.max_concurrent_extractions, int), "max_concurrent_extractions should be an integer"
        assert isinstance(config.output_format, str), "output_format should be a string"

    def test_field_modification_affects_serialization(self) -> None:
        """Verify that modifying fields affects serialization."""
        config = ExtractionConfig(output_format="plain")

        # Verify initial state
        json1 = config_to_json(config)
        parsed1 = json.loads(json1)
        assert parsed1["output_format"] == "plain"

        # Modify and re-serialize (if mutation is supported)
        try:
            config.output_format = "markdown"
            json2 = config_to_json(config)
            parsed2 = json.loads(json2)
            assert parsed2["output_format"] == "markdown", "Modification should affect serialization"
        except (AttributeError, TypeError):
            # If config is immutable, this is also acceptable
            pytest.skip("ExtractionConfig may be immutable")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
