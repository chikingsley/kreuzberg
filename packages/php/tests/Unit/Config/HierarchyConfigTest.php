<?php

declare(strict_types=1);

namespace Kreuzberg\Tests\Unit\Config;

use Kreuzberg\Config\HierarchyConfig;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for HierarchyConfig readonly class.
 *
 * Tests construction, serialization, factory methods, readonly enforcement,
 * and integration with the configuration system. Validates that the hierarchy
 * detection configuration can be created, modified via immutable properties,
 * and properly serialized for use in document extraction.
 *
 * Test Coverage:
 * - Construction with default values
 * - Construction with custom values
 * - toArray() serialization with selective field inclusion
 * - fromArray() factory method with snake_case conversion
 * - fromJson() factory method with JSON parsing
 * - toJson() serialization to JSON string
 * - Readonly enforcement (modification prevention)
 * - Edge cases (null values, type validation)
 * - Invalid JSON handling
 */
#[CoversClass(HierarchyConfig::class)]
#[Group('unit')]
#[Group('config')]
final class HierarchyConfigTest extends TestCase
{
    #[Test]
    public function it_creates_with_default_values(): void
    {
        $config = new HierarchyConfig();

        $this->assertTrue($config->enabled);
        $this->assertEquals(6, $config->kClusters);
        $this->assertTrue($config->includeBbox);
        $this->assertNull($config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_creates_with_custom_values(): void
    {
        $config = new HierarchyConfig(
            enabled: false,
            kClusters: 10,
            includeBbox: false,
            ocrCoverageThreshold: 0.75,
        );

        $this->assertFalse($config->enabled);
        $this->assertEquals(10, $config->kClusters);
        $this->assertFalse($config->includeBbox);
        $this->assertEquals(0.75, $config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_serializes_to_array(): void
    {
        $config = new HierarchyConfig(
            enabled: true,
            kClusters: 8,
            includeBbox: true,
        );
        $array = $config->toArray();

        $this->assertIsArray($array);
        $this->assertTrue($array['enabled']);
        $this->assertEquals(8, $array['k_clusters']);
        $this->assertTrue($array['include_bbox']);
        $this->assertArrayNotHasKey('ocr_coverage_threshold', $array);
    }

    #[Test]
    public function it_includes_optional_fields_in_array_when_set(): void
    {
        $config = new HierarchyConfig(ocrCoverageThreshold: 0.85);
        $array = $config->toArray();

        $this->assertArrayHasKey('ocr_coverage_threshold', $array);
        $this->assertEquals(0.85, $array['ocr_coverage_threshold']);
    }

    #[Test]
    public function it_creates_from_array_with_snake_case_keys(): void
    {
        $data = [
            'enabled' => false,
            'k_clusters' => 12,
            'include_bbox' => false,
            'ocr_coverage_threshold' => 0.5,
        ];
        $config = HierarchyConfig::fromArray($data);

        $this->assertFalse($config->enabled);
        $this->assertEquals(12, $config->kClusters);
        $this->assertFalse($config->includeBbox);
        $this->assertEquals(0.5, $config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_creates_from_array_with_missing_keys_using_defaults(): void
    {
        $data = ['enabled' => false];
        $config = HierarchyConfig::fromArray($data);

        $this->assertFalse($config->enabled);
        $this->assertEquals(6, $config->kClusters);
        $this->assertTrue($config->includeBbox);
        $this->assertNull($config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_serializes_to_json(): void
    {
        $config = new HierarchyConfig(
            enabled: true,
            kClusters: 5,
            includeBbox: false,
            ocrCoverageThreshold: 0.9,
        );
        $json = $config->toJson();

        $this->assertJson($json);
        $decoded = json_decode($json, true);

        $this->assertTrue($decoded['enabled']);
        $this->assertEquals(5, $decoded['k_clusters']);
        $this->assertFalse($decoded['include_bbox']);
        $this->assertEquals(0.9, $decoded['ocr_coverage_threshold']);
    }

    #[Test]
    public function it_creates_from_json(): void
    {
        $json = json_encode([
            'enabled' => false,
            'k_clusters' => 15,
            'include_bbox' => true,
            'ocr_coverage_threshold' => 0.65,
        ]);
        $config = HierarchyConfig::fromJson($json);

        $this->assertFalse($config->enabled);
        $this->assertEquals(15, $config->kClusters);
        $this->assertTrue($config->includeBbox);
        $this->assertEquals(0.65, $config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_round_trips_through_json(): void
    {
        $original = new HierarchyConfig(
            enabled: false,
            kClusters: 20,
            includeBbox: false,
            ocrCoverageThreshold: 0.42,
        );

        $json = $original->toJson();
        $restored = HierarchyConfig::fromJson($json);

        $this->assertEquals($original->enabled, $restored->enabled);
        $this->assertEquals($original->kClusters, $restored->kClusters);
        $this->assertEquals($original->includeBbox, $restored->includeBbox);
        $this->assertEquals($original->ocrCoverageThreshold, $restored->ocrCoverageThreshold);
    }

    #[Test]
    public function it_throws_on_invalid_json(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid JSON');

        HierarchyConfig::fromJson('{ invalid json }');
    }

    #[Test]
    public function it_enforces_readonly_on_enabled_property(): void
    {
        $this->expectException(\Error::class);

        $config = new HierarchyConfig(enabled: true);
        $config->enabled = false;
    }

    #[Test]
    public function it_enforces_readonly_on_k_clusters_property(): void
    {
        $this->expectException(\Error::class);

        $config = new HierarchyConfig(kClusters: 6);
        $config->kClusters = 10;
    }

    #[Test]
    public function it_enforces_readonly_on_include_bbox_property(): void
    {
        $this->expectException(\Error::class);

        $config = new HierarchyConfig(includeBbox: true);
        $config->includeBbox = false;
    }

    #[Test]
    public function it_enforces_readonly_on_ocr_coverage_threshold_property(): void
    {
        $this->expectException(\Error::class);

        $config = new HierarchyConfig(ocrCoverageThreshold: 0.5);
        $config->ocrCoverageThreshold = 0.8;
    }

    #[Test]
    public function it_handles_edge_case_zero_k_clusters(): void
    {
        $config = new HierarchyConfig(kClusters: 0);

        $this->assertEquals(0, $config->kClusters);
        $array = $config->toArray();
        $this->assertEquals(0, $array['k_clusters']);
    }

    #[Test]
    public function it_handles_edge_case_zero_ocr_coverage_threshold(): void
    {
        $config = new HierarchyConfig(ocrCoverageThreshold: 0.0);

        $this->assertEquals(0.0, $config->ocrCoverageThreshold);
        $array = $config->toArray();
        $this->assertEquals(0.0, $array['ocr_coverage_threshold']);
    }

    #[Test]
    public function it_handles_edge_case_max_ocr_coverage_threshold(): void
    {
        $config = new HierarchyConfig(ocrCoverageThreshold: 1.0);

        $this->assertEquals(1.0, $config->ocrCoverageThreshold);
        $array = $config->toArray();
        $this->assertEquals(1.0, $array['ocr_coverage_threshold']);
    }

    #[Test]
    public function it_creates_from_empty_array(): void
    {
        $config = HierarchyConfig::fromArray([]);

        $this->assertTrue($config->enabled);
        $this->assertEquals(6, $config->kClusters);
        $this->assertTrue($config->includeBbox);
        $this->assertNull($config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_creates_from_json_with_missing_optional_fields(): void
    {
        $json = json_encode(['enabled' => false]);
        $config = HierarchyConfig::fromJson($json);

        $this->assertFalse($config->enabled);
        $this->assertEquals(6, $config->kClusters);
        $this->assertTrue($config->includeBbox);
        $this->assertNull($config->ocrCoverageThreshold);
    }

    #[Test]
    public function it_handles_array_with_extra_unknown_keys(): void
    {
        $data = [
            'enabled' => true,
            'unknown_key' => 'unknown_value',
            'another_key' => 123,
        ];
        $config = HierarchyConfig::fromArray($data);

        $this->assertTrue($config->enabled);
        $this->assertEquals(6, $config->kClusters);
    }

    #[Test]
    public function it_serializes_boolean_false_values_correctly(): void
    {
        $config = new HierarchyConfig(enabled: false, includeBbox: false);
        $array = $config->toArray();

        $this->assertFalse($array['enabled']);
        $this->assertFalse($array['include_bbox']);
        $this->assertArrayHasKey('enabled', $array);
        $this->assertArrayHasKey('include_bbox', $array);
    }
}
