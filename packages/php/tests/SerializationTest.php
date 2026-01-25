<?php

namespace Kreuzberg\Tests;

use Kreuzberg\ExtractionConfig;
use Kreuzberg\OcrConfig;
use PHPUnit\Framework\TestCase;

/**
 * Cross-language serialization tests for PHP bindings.
 *
 * Validates that ExtractionConfig serializes consistently with other language bindings.
 */
class SerializationTest extends TestCase
{
    /**
     * Test minimal config serialization.
     */
    public function testMinimalSerialization(): void
    {
        $config = new ExtractionConfig();
        $json = json_encode($config);

        $this->assertIsString($json);

        $parsed = json_decode($json, associative: true);
        $this->assertArrayHasKey('use_cache', $parsed);
        $this->assertArrayHasKey('enable_quality_processing', $parsed);
        $this->assertArrayHasKey('force_ocr', $parsed);
    }

    /**
     * Test config serialization with custom values.
     */
    public function testCustomValuesSerialization(): void
    {
        $config = new ExtractionConfig(
            use_cache: true,
            enable_quality_processing: false,
            force_ocr: true
        );

        $json = json_encode($config);
        $parsed = json_decode($json, associative: true);

        $this->assertEquals(true, $parsed['use_cache']);
        $this->assertEquals(false, $parsed['enable_quality_processing']);
        $this->assertEquals(true, $parsed['force_ocr']);
    }

    /**
     * Test field preservation after serialization.
     */
    public function testFieldPreservation(): void
    {
        $config = new ExtractionConfig(
            use_cache: false,
            enable_quality_processing: true
        );

        $json = json_encode($config);
        $parsed = json_decode($json, associative: true);

        $this->assertEquals(false, $parsed['use_cache']);
        $this->assertEquals(true, $parsed['enable_quality_processing']);
    }

    /**
     * Test round-trip serialization.
     */
    public function testRoundTripSerialization(): void
    {
        $config1 = new ExtractionConfig(
            use_cache: true,
            enable_quality_processing: false
        );

        $json1 = json_encode($config1);
        $array1 = json_decode($json1, associative: true);

        $config2 = new ExtractionConfig(...$array1);
        $json2 = json_encode($config2);

        // Parse both JSONs and compare
        $parsed1 = json_decode($json1, associative: true);
        $parsed2 = json_decode($json2, associative: true);

        $this->assertEquals($parsed1, $parsed2);
    }

    /**
     * Test snake_case field names.
     */
    public function testSnakeCaseFieldNames(): void
    {
        $config = new ExtractionConfig(use_cache: true);
        $json = json_encode($config);

        $this->assertStringContainsString('use_cache', $json);
        $this->assertStringNotContainsString('useCache', $json);
    }

    /**
     * Test nested OCR config serialization.
     */
    public function testNestedOcrConfig(): void
    {
        $ocrConfig = new OcrConfig(
            backend: 'tesseract',
            language: 'eng'
        );

        $config = new ExtractionConfig(ocr: $ocrConfig);
        $json = json_encode($config);
        $parsed = json_decode($json, associative: true);

        $this->assertArrayHasKey('ocr', $parsed);
        $this->assertEquals('tesseract', $parsed['ocr']['backend']);
        $this->assertEquals('eng', $parsed['ocr']['language']);
    }

    /**
     * Test null value handling.
     */
    public function testNullValueHandling(): void
    {
        $config = new ExtractionConfig(
            ocr: null,
            chunking: null
        );

        $json = json_encode($config);
        $parsed = json_decode($json, associative: true);

        // Should handle null values without errors
        $this->assertIsArray($parsed);
    }

    /**
     * Test immutability during serialization.
     */
    public function testImmutabilityDuringSerialization(): void
    {
        $config = new ExtractionConfig(use_cache: true);

        $json1 = json_encode($config);
        $json2 = json_encode($config);
        $json3 = json_encode($config);

        $this->assertEquals($json1, $json2);
        $this->assertEquals($json2, $json3);
    }

    /**
     * Test mandatory fields presence.
     */
    public function testMandatoryFields(): void
    {
        $config = new ExtractionConfig();
        $json = json_encode($config);
        $parsed = json_decode($json, associative: true);

        $mandatoryFields = [
            'use_cache',
            'enable_quality_processing',
            'force_ocr',
        ];

        foreach ($mandatoryFields as $field) {
            $this->assertArrayHasKey($field, $parsed, "Mandatory field '$field' is missing");
        }
    }

    /**
     * Test deserialization from JSON string.
     */
    public function testDeserialization(): void
    {
        $json = '{"use_cache":true,"enable_quality_processing":false,"force_ocr":true}';
        $array = json_decode($json, associative: true);

        $config = new ExtractionConfig(...$array);

        $this->assertTrue($config->use_cache);
        $this->assertFalse($config->enable_quality_processing);
        $this->assertTrue($config->force_ocr);
    }

    /**
     * Test JSON encoding with pretty print.
     */
    public function testPrettyPrint(): void
    {
        $config = new ExtractionConfig(use_cache: true);
        $json = json_encode($config, JSON_PRETTY_PRINT);

        // Should have newlines
        $this->assertStringContainsString("\n", $json);

        // Should still be valid JSON
        $parsed = json_decode($json, associative: true);
        $this->assertIsArray($parsed);
    }
}
