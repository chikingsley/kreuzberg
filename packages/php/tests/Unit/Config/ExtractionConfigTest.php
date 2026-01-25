<?php

declare(strict_types=1);

namespace Kreuzberg\Tests\Unit\Config;

use Kreuzberg\Config\ChunkingConfig;
use Kreuzberg\Config\EmbeddingConfig;
use Kreuzberg\Config\ExtractionConfig;
use Kreuzberg\Config\ImageExtractionConfig;
use Kreuzberg\Config\KeywordConfig;
use Kreuzberg\Config\LanguageDetectionConfig;
use Kreuzberg\Config\OcrConfig;
use Kreuzberg\Config\PageConfig;
use Kreuzberg\Config\PdfConfig;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for ExtractionConfig readonly class.
 *
 * Tests construction, serialization, factory methods, readonly enforcement,
 * and handling of complex nested configuration objects and boolean properties.
 * This is the main configuration class that aggregates all extraction settings.
 *
 * Test Coverage:
 * - Construction with default values
 * - Construction with custom values
 * - toArray() serialization with optional field inclusion
 * - fromArray() factory method with nested structures
 * - fromJson() factory method
 * - toJson() serialization
 * - Readonly enforcement
 * - Nested configuration handling
 * - Builder pattern
 * - Invalid JSON handling
 * - Round-trip serialization
 * - New fields: useCache, enableQualityProcessing, forceOcr, maxConcurrentExtractions, resultFormat, outputEncoding
 */
#[CoversClass(ExtractionConfig::class)]
#[Group('unit')]
#[Group('config')]
final class ExtractionConfigTest extends TestCase
{
    #[Test]
    public function it_creates_with_default_values(): void
    {
        $config = new ExtractionConfig();

        $this->assertNull($config->ocr);
        $this->assertNull($config->pdf);
        $this->assertNull($config->chunking);
        $this->assertNull($config->embedding);
        $this->assertNull($config->imageExtraction);
        $this->assertNull($config->page);
        $this->assertNull($config->languageDetection);
        $this->assertNull($config->keywords);
        $this->assertFalse($config->extractImages);
        $this->assertTrue($config->extractTables);
        $this->assertFalse($config->preserveFormatting);
        $this->assertNull($config->outputFormat);
        $this->assertFalse($config->useCache);
        $this->assertFalse($config->enableQualityProcessing);
        $this->assertFalse($config->forceOcr);
        $this->assertSame(4, $config->maxConcurrentExtractions);
        $this->assertSame('unified', $config->resultFormat);
        $this->assertSame('plain', $config->outputEncoding);
    }

    #[Test]
    public function it_creates_with_custom_values(): void
    {
        $ocrConfig = new OcrConfig(backend: 'tesseract');
        $pdfConfig = new PdfConfig(extractImages: true);
        $chunkingConfig = new ChunkingConfig(maxChars: 1024);

        $config = new ExtractionConfig(
            ocr: $ocrConfig,
            pdf: $pdfConfig,
            chunking: $chunkingConfig,
            extractImages: true,
            extractTables: true,
            preserveFormatting: true,
            outputFormat: 'markdown',
            useCache: true,
            enableQualityProcessing: true,
            forceOcr: true,
            maxConcurrentExtractions: 8,
            resultFormat: 'split',
            outputEncoding: 'json',
        );

        $this->assertSame($ocrConfig, $config->ocr);
        $this->assertSame($pdfConfig, $config->pdf);
        $this->assertSame($chunkingConfig, $config->chunking);
        $this->assertTrue($config->extractImages);
        $this->assertTrue($config->extractTables);
        $this->assertTrue($config->preserveFormatting);
        $this->assertSame('markdown', $config->outputFormat);
        $this->assertTrue($config->useCache);
        $this->assertTrue($config->enableQualityProcessing);
        $this->assertTrue($config->forceOcr);
        $this->assertSame(8, $config->maxConcurrentExtractions);
        $this->assertSame('split', $config->resultFormat);
        $this->assertSame('json', $config->outputEncoding);
    }

    #[Test]
    public function it_serializes_to_array_with_only_non_null_values(): void
    {
        $config = new ExtractionConfig(
            extractImages: true,
            extractTables: false,
            preserveFormatting: true,
        );
        $array = $config->toArray();

        $this->assertIsArray($array);
        $this->assertTrue($array['extract_images']);
        $this->assertFalse($array['extract_tables']);
        $this->assertTrue($array['preserve_formatting']);
        $this->assertArrayNotHasKey('ocr', $array);
        $this->assertArrayNotHasKey('pdf', $array);
    }

    #[Test]
    public function it_includes_nested_configs_in_array_when_set(): void
    {
        $ocr = new OcrConfig();
        $pdf = new PdfConfig();
        $chunking = new ChunkingConfig();

        $config = new ExtractionConfig(
            ocr: $ocr,
            pdf: $pdf,
            chunking: $chunking,
        );
        $array = $config->toArray();

        $this->assertArrayHasKey('ocr', $array);
        $this->assertArrayHasKey('pdf', $array);
        $this->assertArrayHasKey('chunking', $array);
        $this->assertIsArray($array['ocr']);
        $this->assertIsArray($array['pdf']);
        $this->assertIsArray($array['chunking']);
    }

    #[Test]
    public function it_creates_from_array_with_defaults(): void
    {
        $config = ExtractionConfig::fromArray([]);

        $this->assertNull($config->ocr);
        $this->assertFalse($config->extractImages);
        $this->assertTrue($config->extractTables);
        $this->assertFalse($config->useCache);
        $this->assertFalse($config->enableQualityProcessing);
        $this->assertFalse($config->forceOcr);
        $this->assertSame(4, $config->maxConcurrentExtractions);
        $this->assertSame('unified', $config->resultFormat);
        $this->assertSame('plain', $config->outputEncoding);
    }

    #[Test]
    public function it_creates_from_array_with_all_fields(): void
    {
        $data = [
            'ocr' => ['backend' => 'tesseract', 'language' => 'eng'],
            'pdf' => ['extract_images' => true],
            'chunking' => ['max_chunk_size' => 512],
            'embedding' => ['model' => 'bert-base'],
            'image_extraction' => ['extract_images' => true],
            'page' => ['extract_pages' => true],
            'language_detection' => ['enabled' => true],
            'keywords' => ['max_keywords' => 10],
            'extract_images' => true,
            'extract_tables' => false,
            'preserve_formatting' => true,
            'output_format' => 'json',
            'use_cache' => true,
            'enable_quality_processing' => true,
            'force_ocr' => true,
            'max_concurrent_extractions' => 16,
            'result_format' => 'nested',
            'output_encoding' => 'base64',
        ];
        $config = ExtractionConfig::fromArray($data);

        $this->assertNotNull($config->ocr);
        $this->assertNotNull($config->pdf);
        $this->assertNotNull($config->chunking);
        $this->assertNotNull($config->embedding);
        $this->assertNotNull($config->imageExtraction);
        $this->assertNotNull($config->page);
        $this->assertNotNull($config->languageDetection);
        $this->assertNotNull($config->keywords);
        $this->assertTrue($config->extractImages);
        $this->assertFalse($config->extractTables);
        $this->assertTrue($config->preserveFormatting);
        $this->assertSame('json', $config->outputFormat);
        $this->assertTrue($config->useCache);
        $this->assertTrue($config->enableQualityProcessing);
        $this->assertTrue($config->forceOcr);
        $this->assertSame(16, $config->maxConcurrentExtractions);
        $this->assertSame('nested', $config->resultFormat);
        $this->assertSame('base64', $config->outputEncoding);
    }

    #[Test]
    public function it_serializes_to_json(): void
    {
        $config = new ExtractionConfig(
            ocr: new OcrConfig(backend: 'tesseract'),
            extractImages: true,
            outputFormat: 'xml',
            useCache: true,
            maxConcurrentExtractions: 6,
        );
        $json = $config->toJson();

        $this->assertJson($json);
        $decoded = json_decode($json, true);

        $this->assertArrayHasKey('ocr', $decoded);
        $this->assertTrue($decoded['extract_images']);
        $this->assertSame('xml', $decoded['output_format']);
        $this->assertTrue($decoded['use_cache']);
        $this->assertSame(6, $decoded['max_concurrent_extractions']);
    }

    #[Test]
    public function it_creates_from_json(): void
    {
        $json = json_encode([
            'ocr' => ['backend' => 'easyocr'],
            'extract_images' => true,
            'extract_tables' => true,
            'use_cache' => true,
            'force_ocr' => false,
            'max_concurrent_extractions' => 12,
            'result_format' => 'split',
        ]);
        $config = ExtractionConfig::fromJson($json);

        $this->assertNotNull($config->ocr);
        $this->assertTrue($config->extractImages);
        $this->assertTrue($config->extractTables);
        $this->assertTrue($config->useCache);
        $this->assertFalse($config->forceOcr);
        $this->assertSame(12, $config->maxConcurrentExtractions);
        $this->assertSame('split', $config->resultFormat);
    }

    #[Test]
    public function it_round_trips_through_json(): void
    {
        $original = new ExtractionConfig(
            ocr: new OcrConfig(backend: 'tesseract', language: 'eng'),
            pdf: new PdfConfig(extractImages: true),
            chunking: new ChunkingConfig(maxChars: 1024),
            extractImages: true,
            extractTables: false,
            preserveFormatting: true,
            outputFormat: 'markdown',
            useCache: true,
            enableQualityProcessing: true,
            forceOcr: false,
            maxConcurrentExtractions: 8,
            resultFormat: 'split',
            outputEncoding: 'json',
        );

        $json = $original->toJson();
        $restored = ExtractionConfig::fromJson($json);

        $this->assertNotNull($restored->ocr);
        $this->assertNotNull($restored->pdf);
        $this->assertNotNull($restored->chunking);
        $this->assertSame($original->extractImages, $restored->extractImages);
        $this->assertSame($original->extractTables, $restored->extractTables);
        $this->assertSame($original->preserveFormatting, $restored->preserveFormatting);
        $this->assertSame($original->outputFormat, $restored->outputFormat);
        $this->assertSame($original->useCache, $restored->useCache);
        $this->assertSame($original->enableQualityProcessing, $restored->enableQualityProcessing);
        $this->assertSame($original->forceOcr, $restored->forceOcr);
        $this->assertSame($original->maxConcurrentExtractions, $restored->maxConcurrentExtractions);
        $this->assertSame($original->resultFormat, $restored->resultFormat);
        $this->assertSame($original->outputEncoding, $restored->outputEncoding);
    }

    #[Test]
    public function it_throws_on_invalid_json(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid JSON');

        ExtractionConfig::fromJson('{ invalid }');
    }

    #[Test]
    public function it_enforces_readonly_on_extract_images_property(): void
    {
        $this->expectException(\Error::class);

        $config = new ExtractionConfig(extractImages: true);
        $config->extractImages = false;
    }

    #[Test]
    public function it_enforces_readonly_on_output_format_property(): void
    {
        $this->expectException(\Error::class);

        $config = new ExtractionConfig(outputFormat: 'json');
        $config->outputFormat = 'xml';
    }

    #[Test]
    public function it_enforces_readonly_on_ocr_property(): void
    {
        $this->expectException(\Error::class);

        $config = new ExtractionConfig(ocr: new OcrConfig());
        $config->ocr = new OcrConfig(backend: 'easyocr');
    }

    #[Test]
    public function it_enforces_readonly_on_use_cache_property(): void
    {
        $this->expectException(\Error::class);

        $config = new ExtractionConfig(useCache: true);
        $config->useCache = false;
    }

    #[Test]
    public function it_enforces_readonly_on_max_concurrent_extractions_property(): void
    {
        $this->expectException(\Error::class);

        $config = new ExtractionConfig(maxConcurrentExtractions: 8);
        $config->maxConcurrentExtractions = 4;
    }

    #[Test]
    public function it_creates_from_file(): void
    {
        $tempFile = tempnam(sys_get_temp_dir(), 'extract_');
        if ($tempFile === false) {
            $this->markTestSkipped('Unable to create temporary file');
        }

        try {
            file_put_contents($tempFile, json_encode([
                'extract_images' => true,
                'extract_tables' => false,
                'ocr' => ['backend' => 'tesseract'],
                'use_cache' => true,
                'max_concurrent_extractions' => 10,
            ]));

            $config = ExtractionConfig::fromFile($tempFile);

            $this->assertTrue($config->extractImages);
            $this->assertFalse($config->extractTables);
            $this->assertNotNull($config->ocr);
            $this->assertTrue($config->useCache);
            $this->assertSame(10, $config->maxConcurrentExtractions);
        } finally {
            if (file_exists($tempFile)) {
                unlink($tempFile);
            }
        }
    }

    #[Test]
    public function it_throws_when_file_not_found(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('File not found');

        ExtractionConfig::fromFile('/nonexistent/path/config.json');
    }

    #[Test]
    public function it_handles_type_coercion_for_extract_images(): void
    {
        $data = ['extract_images' => 1];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsBool($config->extractImages);
        $this->assertTrue($config->extractImages);
    }

    #[Test]
    public function it_handles_type_coercion_for_extract_tables(): void
    {
        $data = ['extract_tables' => 0];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsBool($config->extractTables);
        $this->assertFalse($config->extractTables);
    }

    #[Test]
    public function it_handles_type_coercion_for_use_cache(): void
    {
        $data = ['use_cache' => 1];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsBool($config->useCache);
        $this->assertTrue($config->useCache);
    }

    #[Test]
    public function it_handles_type_coercion_for_enable_quality_processing(): void
    {
        $data = ['enable_quality_processing' => 0];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsBool($config->enableQualityProcessing);
        $this->assertFalse($config->enableQualityProcessing);
    }

    #[Test]
    public function it_handles_type_coercion_for_force_ocr(): void
    {
        $data = ['force_ocr' => 'true'];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsBool($config->forceOcr);
        $this->assertTrue($config->forceOcr);
    }

    #[Test]
    public function it_handles_type_coercion_for_max_concurrent_extractions(): void
    {
        $data = ['max_concurrent_extractions' => '8'];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsInt($config->maxConcurrentExtractions);
        $this->assertSame(8, $config->maxConcurrentExtractions);
    }

    #[Test]
    public function it_handles_type_coercion_for_result_format(): void
    {
        $data = ['result_format' => 123];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsString($config->resultFormat);
        $this->assertSame('123', $config->resultFormat);
    }

    #[Test]
    public function it_handles_type_coercion_for_output_encoding(): void
    {
        $data = ['output_encoding' => 456];
        $config = ExtractionConfig::fromArray($data);

        $this->assertIsString($config->outputEncoding);
        $this->assertSame('456', $config->outputEncoding);
    }

    #[Test]
    public function it_has_builder_method(): void
    {
        $this->assertTrue(method_exists(ExtractionConfig::class, 'builder'));
    }

    #[Test]
    public function it_supports_builder_with_new_fields(): void
    {
        $config = ExtractionConfig::builder()
            ->withExtractImages(true)
            ->withUseCache(true)
            ->withEnableQualityProcessing(true)
            ->withForceOcr(true)
            ->withMaxConcurrentExtractions(12)
            ->withResultFormat('split')
            ->withOutputEncoding('json')
            ->build();

        $this->assertTrue($config->extractImages);
        $this->assertTrue($config->useCache);
        $this->assertTrue($config->enableQualityProcessing);
        $this->assertTrue($config->forceOcr);
        $this->assertSame(12, $config->maxConcurrentExtractions);
        $this->assertSame('split', $config->resultFormat);
        $this->assertSame('json', $config->outputEncoding);
    }

    #[Test]
    public function it_supports_all_nested_configs_together(): void
    {
        $config = new ExtractionConfig(
            ocr: new OcrConfig(),
            pdf: new PdfConfig(),
            chunking: new ChunkingConfig(),
            embedding: new EmbeddingConfig(),
            imageExtraction: new ImageExtractionConfig(),
            page: new PageConfig(),
            languageDetection: new LanguageDetectionConfig(),
            keywords: new KeywordConfig(),
        );

        $array = $config->toArray();

        $this->assertArrayHasKey('ocr', $array);
        $this->assertArrayHasKey('pdf', $array);
        $this->assertArrayHasKey('chunking', $array);
        $this->assertArrayHasKey('embedding', $array);
        $this->assertArrayHasKey('images', $array);
        $this->assertArrayHasKey('pages', $array);
        $this->assertArrayHasKey('language_detection', $array);
        $this->assertArrayHasKey('keywords', $array);
    }

    #[Test]
    public function it_json_output_is_prettified(): void
    {
        $config = new ExtractionConfig(
            ocr: new OcrConfig(),
            extractImages: true,
        );
        $json = $config->toJson();

        $this->assertStringContainsString("\n", $json);
        $this->assertStringContainsString('  ', $json);
    }

    #[Test]
    public function it_serializes_non_default_values_for_new_fields(): void
    {
        $config = new ExtractionConfig(
            useCache: true,
            enableQualityProcessing: true,
            forceOcr: true,
            maxConcurrentExtractions: 10,
            resultFormat: 'nested',
            outputEncoding: 'base64',
        );
        $array = $config->toArray();

        $this->assertTrue($array['use_cache']);
        $this->assertTrue($array['enable_quality_processing']);
        $this->assertTrue($array['force_ocr']);
        $this->assertSame(10, $array['max_concurrent_extractions']);
        $this->assertSame('nested', $array['result_format']);
        $this->assertSame('base64', $array['output_encoding']);
    }

    #[Test]
    public function it_omits_default_values_for_new_fields_in_serialization(): void
    {
        $config = new ExtractionConfig(
            useCache: false,
            enableQualityProcessing: false,
            forceOcr: false,
            maxConcurrentExtractions: 4,
            resultFormat: 'unified',
            outputEncoding: 'plain',
        );
        $array = $config->toArray();

        $this->assertArrayNotHasKey('use_cache', $array);
        $this->assertArrayNotHasKey('enable_quality_processing', $array);
        $this->assertArrayNotHasKey('force_ocr', $array);
        $this->assertArrayNotHasKey('max_concurrent_extractions', $array);
        $this->assertArrayNotHasKey('result_format', $array);
        $this->assertArrayNotHasKey('output_encoding', $array);
    }

    #[Test]
    public function it_allows_various_max_concurrent_extractions_values(): void
    {
        $values = [1, 2, 4, 8, 16, 32, 100];

        foreach ($values as $value) {
            $config = new ExtractionConfig(maxConcurrentExtractions: $value);
            $this->assertSame($value, $config->maxConcurrentExtractions);
        }
    }

    #[Test]
    public function it_allows_various_result_formats(): void
    {
        $formats = ['unified', 'split', 'nested', 'custom'];

        foreach ($formats as $format) {
            $config = new ExtractionConfig(resultFormat: $format);
            $this->assertSame($format, $config->resultFormat);
        }
    }

    #[Test]
    public function it_allows_various_output_encodings(): void
    {
        $encodings = ['plain', 'json', 'base64', 'xml'];

        foreach ($encodings as $encoding) {
            $config = new ExtractionConfig(outputEncoding: $encoding);
            $this->assertSame($encoding, $config->outputEncoding);
        }
    }

    #[Test]
    public function it_provides_complete_builder_chain_with_all_new_fields(): void
    {
        $config = ExtractionConfig::builder()
            ->withOcr(new OcrConfig())
            ->withExtractImages(true)
            ->withExtractTables(false)
            ->withPreserveFormatting(true)
            ->withOutputFormat('markdown')
            ->withUseCache(true)
            ->withEnableQualityProcessing(true)
            ->withForceOcr(true)
            ->withMaxConcurrentExtractions(16)
            ->withResultFormat('split')
            ->withOutputEncoding('json')
            ->build();

        $this->assertNotNull($config->ocr);
        $this->assertTrue($config->extractImages);
        $this->assertFalse($config->extractTables);
        $this->assertTrue($config->preserveFormatting);
        $this->assertSame('markdown', $config->outputFormat);
        $this->assertTrue($config->useCache);
        $this->assertTrue($config->enableQualityProcessing);
        $this->assertTrue($config->forceOcr);
        $this->assertSame(16, $config->maxConcurrentExtractions);
        $this->assertSame('split', $config->resultFormat);
        $this->assertSame('json', $config->outputEncoding);
    }
}
