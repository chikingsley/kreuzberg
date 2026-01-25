"""Tests for output_format and result_format fields in ExtractionConfig."""

from __future__ import annotations

import json

from kreuzberg import ExtractionConfig, config_to_json


class TestOutputFormatField:
    """Test output_format configuration field."""

    def test_output_format_default_value(self) -> None:
        """Verify output_format defaults to plain."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "plain", "Default output_format should be plain"

    def test_output_format_plain(self) -> None:
        """Test setting output_format to plain."""
        config = ExtractionConfig(output_format="plain")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "plain"

    def test_output_format_markdown(self) -> None:
        """Test setting output_format to markdown."""
        config = ExtractionConfig(output_format="markdown")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "markdown"

    def test_output_format_djot(self) -> None:
        """Test setting output_format to djot."""
        config = ExtractionConfig(output_format="djot")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "djot"

    def test_output_format_html(self) -> None:
        """Test setting output_format to html."""
        config = ExtractionConfig(output_format="html")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "html"

    def test_output_format_all_variants(self) -> None:
        """Test all valid output_format variants."""
        formats = ["plain", "markdown", "djot", "html"]
        for fmt in formats:
            config = ExtractionConfig(output_format=fmt)
            config_json = config_to_json(config)
            parsed = json.loads(config_json)
            assert parsed["output_format"] == fmt, f"Should preserve {fmt} format"

    def test_output_format_serialization_lowercase(self) -> None:
        """Verify output_format is serialized as lowercase string."""
        config = ExtractionConfig(output_format="markdown")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert isinstance(parsed["output_format"], str), "output_format should be string"
        assert parsed["output_format"].islower(), "output_format should be lowercase"

    def test_output_format_none_uses_default(self) -> None:
        """Test that output_format=None uses the default."""
        config = ExtractionConfig(output_format=None)
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "plain", "None should use default plain"

    def test_output_format_type_is_string(self) -> None:
        """Verify output_format is a string in JSON."""
        config = ExtractionConfig(output_format="markdown")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert isinstance(parsed["output_format"], str), "output_format should be string type in JSON"


class TestResultFormatField:
    """Test result_format configuration field."""

    def test_result_format_default_value(self) -> None:
        """Verify result_format defaults to unified."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["result_format"] == "unified", "Default result_format should be unified"

    def test_result_format_unified(self) -> None:
        """Test setting result_format to unified."""
        config = ExtractionConfig(result_format="unified")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["result_format"] == "unified"

    def test_result_format_element_based(self) -> None:
        """Test setting result_format to element_based."""
        config = ExtractionConfig(result_format="element_based")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["result_format"] == "element_based"

    def test_result_format_all_variants(self) -> None:
        """Test all valid result_format variants."""
        formats = ["unified", "element_based"]
        for fmt in formats:
            config = ExtractionConfig(result_format=fmt)
            config_json = config_to_json(config)
            parsed = json.loads(config_json)
            assert parsed["result_format"] == fmt, f"Should preserve {fmt} format"

    def test_result_format_serialization_is_lowercase(self) -> None:
        """Verify result_format is serialized as lowercase string."""
        config = ExtractionConfig(result_format="element_based")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert isinstance(parsed["result_format"], str), "result_format should be string"
        assert parsed["result_format"].islower(), "result_format should be lowercase"

    def test_result_format_none_uses_default(self) -> None:
        """Test that result_format=None uses the default."""
        config = ExtractionConfig(result_format=None)
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["result_format"] == "unified", "None should use default unified"

    def test_result_format_type_is_string(self) -> None:
        """Verify result_format is a string in JSON."""
        config = ExtractionConfig(result_format="element_based")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert isinstance(parsed["result_format"], str), "result_format should be string type in JSON"


class TestFormatsCombined:
    """Test output_format and result_format together."""

    def test_both_formats_in_json(self) -> None:
        """Verify both format fields present in JSON serialization."""
        config = ExtractionConfig(output_format="markdown", result_format="element_based")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert "output_format" in parsed, "output_format should be in JSON"
        assert "result_format" in parsed, "result_format should be in JSON"

    def test_formats_roundtrip(self) -> None:
        """Test that formats survive serialization and deserialization."""
        original = ExtractionConfig(output_format="html", result_format="element_based")
        config_json = config_to_json(original)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "html"
        assert parsed["result_format"] == "element_based"

    def test_formats_independent(self) -> None:
        """Test that output_format and result_format are independent."""
        config1 = ExtractionConfig(output_format="markdown", result_format="unified")
        config_json1 = config_to_json(config1)
        parsed1 = json.loads(config_json1)

        config2 = ExtractionConfig(output_format="plain", result_format="element_based")
        config_json2 = config_to_json(config2)
        parsed2 = json.loads(config_json2)

        assert parsed1["output_format"] != parsed2["output_format"]
        assert parsed1["result_format"] != parsed2["result_format"]

    def test_default_formats_together(self) -> None:
        """Test both formats use their defaults when not specified."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "plain"
        assert parsed["result_format"] == "unified"

    def test_mixed_explicit_and_default(self) -> None:
        """Test one format explicit and one default."""
        config = ExtractionConfig(output_format="djot")
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"] == "djot"
        assert parsed["result_format"] == "unified"  # default


class TestFormatFieldPresence:
    """Test that format fields are always present in serialized config."""

    def test_format_fields_always_present(self) -> None:
        """Verify format fields are present in all serialized configs."""
        configs = [
            ExtractionConfig(),
            ExtractionConfig(use_cache=False),
            ExtractionConfig(force_ocr=True),
            ExtractionConfig(output_format="markdown", result_format="element_based"),
        ]

        for config in configs:
            config_json = config_to_json(config)
            parsed = json.loads(config_json)
            assert "output_format" in parsed, f"output_format missing in config: {parsed}"
            assert "result_format" in parsed, f"result_format missing in config: {parsed}"

    def test_format_fields_are_strings(self) -> None:
        """Verify format fields are always strings in JSON."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert isinstance(parsed["output_format"], str), "output_format must be string"
        assert isinstance(parsed["result_format"], str), "result_format must be string"

    def test_format_fields_not_empty(self) -> None:
        """Verify format fields are never empty strings."""
        config = ExtractionConfig()
        config_json = config_to_json(config)
        parsed = json.loads(config_json)
        assert parsed["output_format"], "output_format should not be empty"
        assert parsed["result_format"], "result_format should not be empty"


class TestFormatDocumentation:
    """Test that format fields are properly documented."""

    def test_output_format_variants_documented(self) -> None:
        """Document valid output_format variants."""
        # Valid output_format values: plain, markdown, djot, html
        valid_formats = {
            "plain": "Raw extracted text",
            "markdown": "Markdown formatted output",
            "djot": "Djot markup format",
            "html": "HTML formatted output",
        }

        for fmt in valid_formats:
            config = ExtractionConfig(output_format=fmt)
            config_json = config_to_json(config)
            parsed = json.loads(config_json)
            assert parsed["output_format"] == fmt, f"Should support {fmt} format"

    def test_result_format_variants_documented(self) -> None:
        """Document valid result_format variants."""
        # Valid result_format values: unified, element_based
        valid_formats = {
            "unified": "All content in content field",
            "element_based": "Semantic elements for Unstructured compatibility",
        }

        for fmt in valid_formats:
            config = ExtractionConfig(result_format=fmt)
            config_json = config_to_json(config)
            parsed = json.loads(config_json)
            assert parsed["result_format"] == fmt, f"Should support {fmt} format"
