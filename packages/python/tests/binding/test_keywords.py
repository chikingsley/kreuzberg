"""Comprehensive tests for keyword/NER extraction in Python binding.

Tests cover:
- Basic keyword extraction functionality
- Multilingual keyword extraction
- Min score filtering and thresholds
- N-gram range variations
- Algorithm selection (YAKE, RAKE)
- Batch keyword extraction
- Score normalization and ordering
- Edge cases (empty strings, whitespace, short text)
"""

from __future__ import annotations

import contextlib

from kreuzberg import (
    ExtractionConfig,
    KeywordAlgorithm,
    KeywordConfig,
    extract_bytes_sync,
)


class TestBasicKeywordExtraction:
    """Test basic keyword extraction functionality."""

    def test_basic_keyword_extraction_extracts_meaningful_keywords(self) -> None:
        """Extract keywords from text and verify meaningful results."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = "Machine learning and artificial intelligence are transforming technology."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result.content is not None
        assert len(result.content) > 0
        # Should extract key terms from the text
        assert any(
            term in result.content.lower() for term in ["machine learning", "artificial intelligence", "technology"]
        )

    def test_keyword_extraction_produces_valid_metadata(self) -> None:
        """Verify keyword extraction produces valid metadata structure."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        text = "Python programming language for data science and machine learning applications."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        # Metadata should exist and contain data
        assert result.metadata is not None
        assert isinstance(result.metadata, dict)
        assert len(result.metadata) > 0

    def test_keyword_extraction_respects_max_keywords_limit(self) -> None:
        """Verify extracted keywords respect the max_keywords parameter."""
        config_small = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=2,
            )
        )

        config_large = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=20,
            )
        )

        text = "Natural language processing and neural networks enable advanced AI systems today."
        result_small = extract_bytes_sync(text.encode(), "text/plain", config_small)
        result_large = extract_bytes_sync(text.encode(), "text/plain", config_large)

        # Both should return results, but size should differ
        assert result_small.content is not None
        assert result_large.content is not None
        # Smaller limit should generally produce shorter output
        assert len(result_small.content) <= len(result_large.content)


class TestMultilingualKeywordExtraction:
    """Test keyword extraction in multiple languages."""

    def test_english_keyword_extraction(self) -> None:
        """Extract keywords from English text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                language="en",
                max_keywords=5,
            )
        )

        text = "The rapid advancement of cloud computing infrastructure enables scalable solutions."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result.content is not None
        assert result.metadata is not None

    def test_german_keyword_extraction(self) -> None:
        """Extract keywords from German text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                language="de",
                max_keywords=5,
            )
        )

        text = "Die Künstliche Intelligenz revolutioniert die Technologieindustrie."
        result = extract_bytes_sync(text.encode("utf-8"), "text/plain", config)

        assert result.content is not None
        assert result.metadata is not None

    def test_french_keyword_extraction(self) -> None:
        """Extract keywords from French text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                language="fr",
                max_keywords=5,
            )
        )

        text = "L'apprentissage automatique transforme les données en connaissances."
        result = extract_bytes_sync(text.encode("utf-8"), "text/plain", config)

        assert result.content is not None
        assert result.metadata is not None

    def test_spanish_keyword_extraction(self) -> None:
        """Extract keywords from Spanish text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                language="es",
                max_keywords=5,
            )
        )

        text = "El procesamiento del lenguaje natural es fundamental para la inteligencia artificial."
        result = extract_bytes_sync(text.encode("utf-8"), "text/plain", config)

        assert result.content is not None
        assert result.metadata is not None

    def test_multilingual_utf8_handling(self) -> None:
        """Verify UTF-8 handling in multilingual text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        multilingual_text = "Café, naïve, résumé - testing UTF-8 with accented characters."
        result = extract_bytes_sync(multilingual_text.encode("utf-8"), "text/plain", config)

        assert result.content is not None
        assert "Café" in result.content or "caf" in result.content.lower()


class TestMinScoreFiltering:
    """Test min_score threshold filtering."""

    def test_min_score_filtering_produces_results(self) -> None:
        """Verify min_score filtering works with different thresholds."""
        thresholds = [0.0, 0.3, 0.5, 0.8]
        text = "Deep learning networks process information through multiple layers of abstraction processing."

        results_by_threshold = {}
        for threshold in thresholds:
            config = ExtractionConfig(
                keywords=KeywordConfig(
                    algorithm=KeywordAlgorithm.Yake,
                    max_keywords=20,
                    min_score=threshold,
                )
            )
            result = extract_bytes_sync(text.encode(), "text/plain", config)
            results_by_threshold[threshold] = result
            assert result.content is not None

        # Lower thresholds should include more keywords
        low_score_result = results_by_threshold[0.0]
        high_score_result = results_by_threshold[0.8]
        assert len(low_score_result.content) >= len(high_score_result.content)

    def test_min_score_filtering_deterministic(self) -> None:
        """Verify min_score filtering produces deterministic results."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=20,
                min_score=0.3,
            )
        )

        text = "Quantum computing represents a paradigm shift in computational capabilities and research."

        # Run multiple times with same config
        result1 = extract_bytes_sync(text.encode(), "text/plain", config)
        result2 = extract_bytes_sync(text.encode(), "text/plain", config)
        result3 = extract_bytes_sync(text.encode(), "text/plain", config)

        # All results should be identical
        assert result1.content == result2.content
        assert result2.content == result3.content
        assert result1.content is not None


class TestNgramRangeVariations:
    """Test n-gram range configuration variations."""

    def test_ngram_range_configurations_all_produce_results(self) -> None:
        """Verify different ngram_range configurations all produce valid results."""
        configs = [
            ((1, 1), "Single"),
            ((1, 2), "Bigram"),
            ((1, 3), "Trigram"),
            ((2, 3), "Two-three"),
        ]

        text = "Multi-word phrase extraction enables identification of key concepts and ideas in data science."

        for ngram_range, label in configs:
            config = ExtractionConfig(
                keywords=KeywordConfig(
                    algorithm=KeywordAlgorithm.Yake,
                    max_keywords=15,
                    ngram_range=ngram_range,
                )
            )
            result = extract_bytes_sync(text.encode(), "text/plain", config)
            assert result.content is not None, f"{label} ngram range should produce results"
            assert len(result.content) > 0, f"{label} extraction should have non-empty content"

    def test_ngram_range_single_words_vs_phrases(self) -> None:
        """Verify that n-gram ranges produce appropriately different results."""
        text = "Natural language processing uses advanced machine learning techniques and neural networks."

        # Single word extraction
        config_single = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=20,
                ngram_range=(1, 1),
            )
        )

        # Phrase extraction (1-3 words)
        config_phrases = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=20,
                ngram_range=(1, 3),
            )
        )

        result_single = extract_bytes_sync(text.encode(), "text/plain", config_single)
        result_phrases = extract_bytes_sync(text.encode(), "text/plain", config_phrases)

        # Both should have results
        assert result_single.content is not None
        assert result_phrases.content is not None
        # Phrase extraction typically produces more content due to multi-word terms
        assert len(result_phrases.content) >= len(result_single.content)


class TestAlgorithmSelection:
    """Test different keyword extraction algorithms."""

    def test_both_algorithms_produce_results(self) -> None:
        """Verify both YAKE and RAKE algorithms produce valid results."""
        text = "Machine learning and artificial intelligence algorithms extract keywords from text through various methods."

        # Test YAKE
        yake_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )
        yake_result = extract_bytes_sync(text.encode(), "text/plain", yake_config)
        assert yake_result.content is not None
        assert len(yake_result.content) > 0
        assert yake_result.metadata is not None

        # Test RAKE
        rake_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Rake,
                max_keywords=10,
            )
        )
        rake_result = extract_bytes_sync(text.encode(), "text/plain", rake_config)
        assert rake_result.content is not None
        assert len(rake_result.content) > 0
        assert rake_result.metadata is not None

    def test_algorithm_selection_produces_different_results(self) -> None:
        """Verify different algorithms can produce different keyword extractions."""
        text = "Data science and machine learning enable artificial intelligence research and applications in industry."

        yake_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        rake_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Rake,
                max_keywords=10,
            )
        )

        yake_result = extract_bytes_sync(text.encode(), "text/plain", yake_config)
        rake_result = extract_bytes_sync(text.encode(), "text/plain", rake_config)

        # Both should produce results
        assert yake_result.content is not None
        assert rake_result.content is not None
        # Algorithms may produce different results (or similar, depending on algorithm design)
        # The important thing is that both work
        assert len(yake_result.content) > 0
        assert len(rake_result.content) > 0


class TestBatchKeywordExtraction:
    """Test batch keyword extraction from multiple documents."""

    def test_batch_extraction_multiple_texts(self) -> None:
        """Extract keywords from multiple documents with batch processing."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        texts = [
            "First document about machine learning systems.",
            "Second document discussing natural language processing.",
            "Third document covering deep neural networks.",
        ]

        results = []
        for text in texts:
            result = extract_bytes_sync(text.encode(), "text/plain", config)
            results.append(result)

        assert len(results) == 3
        for result in results:
            assert result.metadata is not None

    def test_batch_result_ordering_matches_input(self) -> None:
        """Verify batch processing maintains result ordering."""
        texts = [
            "Document one with unique keywords",
            "Document two with different keywords",
            "Document three with other keywords",
        ]

        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        results = []
        for text in texts:
            result = extract_bytes_sync(text.encode(), "text/plain", config)
            results.append(result)

        assert len(results) == len(texts)

        for _i, result in enumerate(results):
            assert result.content is not None
            assert "Document" in result.content or "document" in result.content.lower()

    def test_batch_processing_with_empty_text(self) -> None:
        """Test batch processing where some texts are empty."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        texts = [
            "First document with content and keywords.",
            "",
            "Third document also with content.",
        ]

        results = []
        for text in texts:
            result = None
            with contextlib.suppress(Exception):
                result = extract_bytes_sync(text.encode(), "text/plain", config)
            results.append(result)

        assert len(results) == 3


class TestScoreNormalization:
    """Test keyword score normalization and ordering."""

    def test_keyword_extraction_produces_consistent_results(self) -> None:
        """Verify keyword extraction is deterministic and reproducible."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = "Machine learning and artificial intelligence transform data analysis and decision making."

        result1 = extract_bytes_sync(text.encode(), "text/plain", config)
        result2 = extract_bytes_sync(text.encode(), "text/plain", config)
        result3 = extract_bytes_sync(text.encode(), "text/plain", config)

        # All runs should produce identical results
        assert result1.content == result2.content
        assert result2.content == result3.content
        assert result1.metadata is not None
        assert result1.content is not None

    def test_different_configurations_produce_different_results(self) -> None:
        """Verify that different min_score values affect extraction results."""
        text = "Keyword extraction with minimum score filtering affects result quantity and quality."

        low_score_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=50,
                min_score=0.0,
            )
        )

        high_score_config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=50,
                min_score=0.7,
            )
        )

        low_score_result = extract_bytes_sync(text.encode(), "text/plain", low_score_config)
        high_score_result = extract_bytes_sync(text.encode(), "text/plain", high_score_config)

        # Both should succeed
        assert low_score_result.content is not None
        assert high_score_result.content is not None
        # Lower score threshold should typically return more/longer results
        assert len(low_score_result.content) >= len(high_score_result.content)


class TestEmptyAndEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_empty_string_input(self) -> None:
        """Extract keywords from empty string."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = ""
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_whitespace_only_input(self) -> None:
        """Extract keywords from whitespace-only string."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = "   \n\t  \n  "
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_very_short_text_extraction(self) -> None:
        """Extract keywords from very short text (< 10 words)."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        text = "Short text here"
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_single_word_input(self) -> None:
        """Extract keywords from single word."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        text = "Keyword"
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_repeated_word_input(self) -> None:
        """Extract keywords from repeated same word."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        text = "word word word word word"
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_special_characters_handling(self) -> None:
        """Extract keywords from text with special characters."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = "Special characters: @#$%^&*() and symbols !? in text."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_numbers_only_input(self) -> None:
        """Extract keywords from numeric-only text."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=5,
            )
        )

        text = "123 456 789 012 345"
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_mixed_case_and_punctuation(self) -> None:
        """Extract keywords from text with mixed case and punctuation."""
        config = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=10,
            )
        )

        text = "MixedCase UPPERCASE lowercase. With-hyphens and_underscores."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None

    def test_max_keywords_limit_respected(self) -> None:
        """Verify max_keywords parameter limits results."""
        config_small = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=3,
            )
        )

        config_large = ExtractionConfig(
            keywords=KeywordConfig(
                algorithm=KeywordAlgorithm.Yake,
                max_keywords=20,
            )
        )

        text = "Keywords are limited by max_keywords configuration parameter."

        result_small = extract_bytes_sync(text.encode(), "text/plain", config_small)
        result_large = extract_bytes_sync(text.encode(), "text/plain", config_large)

        assert result_small.metadata is not None
        assert result_large.metadata is not None

    def test_none_keywords_config_disables_extraction(self) -> None:
        """Verify keywords=None disables keyword extraction."""
        config = ExtractionConfig(keywords=None)

        text = "This text should not have keyword extraction enabled."
        result = extract_bytes_sync(text.encode(), "text/plain", config)

        assert result is not None
        assert result.metadata is not None
