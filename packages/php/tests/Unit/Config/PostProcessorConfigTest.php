<?php

declare(strict_types=1);

namespace Kreuzberg\Tests\Unit\Config;

use Kreuzberg\Config\PostProcessorConfig;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for PostProcessorConfig readonly class.
 *
 * Tests construction, serialization, factory methods, readonly enforcement,
 * and handling of mixed/nested configuration values. Validates that post-processor
 * configuration with generic config objects can be properly created, serialized,
 * and maintained in a readonly state.
 *
 * Test Coverage:
 * - Construction with default values
 * - Construction with custom values (including mixed types)
 * - toArray() serialization with optional field inclusion
 * - fromArray() factory method with various data types
 * - fromJson() factory method with nested JSON structures
 * - toJson() serialization preserving complex nested data
 * - Readonly enforcement (modification prevention)
 * - Edge cases (null values, empty strings, nested arrays)
 * - Invalid JSON handling
 * - Round-trip serialization with complex config objects
 */
#[CoversClass(PostProcessorConfig::class)]
#[Group('unit')]
#[Group('config')]
final class PostProcessorConfigTest extends TestCase
{
    #[Test]
    public function it_creates_with_default_values(): void
    {
        $config = new PostProcessorConfig();

        $this->assertFalse($config->enabled);
        $this->assertNull($config->name);
        $this->assertNull($config->config);
    }

    #[Test]
    public function it_creates_with_custom_values(): void
    {
        $customConfig = ['option' => 'value'];
        $config = new PostProcessorConfig(
            enabled: true,
            name: 'CustomProcessor',
            config: $customConfig,
        );

        $this->assertTrue($config->enabled);
        $this->assertEquals('CustomProcessor', $config->name);
        $this->assertEquals($customConfig, $config->config);
    }

    #[Test]
    public function it_serializes_to_array_with_only_enabled_by_default(): void
    {
        $config = new PostProcessorConfig(enabled: false);
        $array = $config->toArray();

        $this->assertIsArray($array);
        $this->assertFalse($array['enabled']);
        $this->assertArrayNotHasKey('name', $array);
        $this->assertArrayNotHasKey('config', $array);
    }

    #[Test]
    public function it_includes_name_in_array_when_set(): void
    {
        $config = new PostProcessorConfig(
            enabled: true,
            name: 'ProcessorName',
        );
        $array = $config->toArray();

        $this->assertTrue($array['enabled']);
        $this->assertArrayHasKey('name', $array);
        $this->assertEquals('ProcessorName', $array['name']);
        $this->assertArrayNotHasKey('config', $array);
    }

    #[Test]
    public function it_includes_config_in_array_when_set(): void
    {
        $configData = ['setting1' => 'value1', 'setting2' => 123];
        $config = new PostProcessorConfig(
            enabled: true,
            config: $configData,
        );
        $array = $config->toArray();

        $this->assertTrue($array['enabled']);
        $this->assertArrayHasKey('config', $array);
        $this->assertEquals($configData, $array['config']);
        $this->assertArrayNotHasKey('name', $array);
    }

    #[Test]
    public function it_includes_both_name_and_config_when_set(): void
    {
        $configData = ['key' => 'value'];
        $config = new PostProcessorConfig(
            enabled: true,
            name: 'FullProcessor',
            config: $configData,
        );
        $array = $config->toArray();

        $this->assertTrue($array['enabled']);
        $this->assertEquals('FullProcessor', $array['name']);
        $this->assertEquals($configData, $array['config']);
    }

    #[Test]
    public function it_creates_from_array_with_defaults(): void
    {
        $config = PostProcessorConfig::fromArray([]);

        $this->assertFalse($config->enabled);
        $this->assertNull($config->name);
        $this->assertNull($config->config);
    }

    #[Test]
    public function it_creates_from_array_with_all_fields(): void
    {
        $data = [
            'enabled' => true,
            'name' => 'MyProcessor',
            'config' => ['option' => 'value'],
        ];
        $config = PostProcessorConfig::fromArray($data);

        $this->assertTrue($config->enabled);
        $this->assertEquals('MyProcessor', $config->name);
        $this->assertEquals(['option' => 'value'], $config->config);
    }

    #[Test]
    public function it_creates_from_array_with_partial_fields(): void
    {
        $data = ['enabled' => true, 'name' => 'PartialProcessor'];
        $config = PostProcessorConfig::fromArray($data);

        $this->assertTrue($config->enabled);
        $this->assertEquals('PartialProcessor', $config->name);
        $this->assertNull($config->config);
    }

    #[Test]
    public function it_handles_nested_config_arrays(): void
    {
        $nested = [
            'processors' => [
                ['name' => 'first', 'enabled' => true],
                ['name' => 'second', 'enabled' => false],
            ],
            'settings' => ['timeout' => 30],
        ];
        $config = PostProcessorConfig::fromArray([
            'enabled' => true,
            'name' => 'NestedProcessor',
            'config' => $nested,
        ]);

        $this->assertEquals($nested, $config->config);
    }

    #[Test]
    public function it_serializes_to_json(): void
    {
        $config = new PostProcessorConfig(
            enabled: true,
            name: 'JsonProcessor',
            config: ['mode' => 'strict'],
        );
        $json = $config->toJson();

        $this->assertJson($json);
        $decoded = json_decode($json, true);

        $this->assertTrue($decoded['enabled']);
        $this->assertEquals('JsonProcessor', $decoded['name']);
        $this->assertEquals(['mode' => 'strict'], $decoded['config']);
    }

    #[Test]
    public function it_creates_from_json(): void
    {
        $json = json_encode([
            'enabled' => false,
            'name' => 'JsonCreated',
            'config' => ['nested' => ['deep' => 'value']],
        ]);
        $config = PostProcessorConfig::fromJson($json);

        $this->assertFalse($config->enabled);
        $this->assertEquals('JsonCreated', $config->name);
        $this->assertEquals(['nested' => ['deep' => 'value']], $config->config);
    }

    #[Test]
    public function it_creates_from_json_with_minimal_fields(): void
    {
        $json = json_encode(['enabled' => true]);
        $config = PostProcessorConfig::fromJson($json);

        $this->assertTrue($config->enabled);
        $this->assertNull($config->name);
        $this->assertNull($config->config);
    }

    #[Test]
    public function it_round_trips_through_json(): void
    {
        $original = new PostProcessorConfig(
            enabled: true,
            name: 'RoundTripProcessor',
            config: ['value' => 42, 'nested' => ['key' => 'data']],
        );

        $json = $original->toJson();
        $restored = PostProcessorConfig::fromJson($json);

        $this->assertEquals($original->enabled, $restored->enabled);
        $this->assertEquals($original->name, $restored->name);
        $this->assertEquals($original->config, $restored->config);
    }

    #[Test]
    public function it_throws_on_invalid_json(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid JSON');

        PostProcessorConfig::fromJson('{ broken json');
    }

    #[Test]
    public function it_throws_on_empty_json_string(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        PostProcessorConfig::fromJson('');
    }

    #[Test]
    public function it_enforces_readonly_on_enabled_property(): void
    {
        $this->expectException(\Error::class);

        $config = new PostProcessorConfig(enabled: true);
        $config->enabled = false;
    }

    #[Test]
    public function it_enforces_readonly_on_name_property(): void
    {
        $this->expectException(\Error::class);

        $config = new PostProcessorConfig(name: 'Original');
        $config->name = 'Modified';
    }

    #[Test]
    public function it_enforces_readonly_on_config_property(): void
    {
        $this->expectException(\Error::class);

        $config = new PostProcessorConfig(config: ['original' => true]);
        $config->config = ['modified' => false];
    }

    #[Test]
    public function it_handles_empty_string_name(): void
    {
        $config = new PostProcessorConfig(name: '');

        $this->assertEquals('', $config->name);
        $array = $config->toArray();
        $this->assertArrayHasKey('name', $array);
        $this->assertEquals('', $array['name']);
    }

    #[Test]
    public function it_handles_empty_array_config(): void
    {
        $config = new PostProcessorConfig(config: []);

        $this->assertEquals([], $config->config);
        $array = $config->toArray();
        $this->assertArrayHasKey('config', $array);
        $this->assertEquals([], $array['config']);
    }

    #[Test]
    public function it_handles_config_with_various_scalar_types(): void
    {
        $config = new PostProcessorConfig(
            config: [
                'string' => 'value',
                'int' => 42,
                'float' => 3.14,
                'bool' => true,
                'null' => null,
            ],
        );

        $array = $config->toArray();
        $this->assertEquals('value', $array['config']['string']);
        $this->assertEquals(42, $array['config']['int']);
        $this->assertEquals(3.14, $array['config']['float']);
        $this->assertTrue($array['config']['bool']);
        $this->assertNull($array['config']['null']);
    }

    #[Test]
    public function it_handles_deeply_nested_config(): void
    {
        $deepConfig = [
            'level1' => [
                'level2' => [
                    'level3' => [
                        'level4' => 'deep_value',
                    ],
                ],
            ],
        ];
        $config = new PostProcessorConfig(config: $deepConfig);

        $this->assertEquals('deep_value', $config->config['level1']['level2']['level3']['level4']);

        $json = $config->toJson();
        $restored = PostProcessorConfig::fromJson($json);
        $this->assertEquals($deepConfig, $restored->config);
    }

    #[Test]
    public function it_handles_array_with_extra_unknown_keys(): void
    {
        $data = [
            'enabled' => true,
            'unknown_key' => 'ignored',
            'another_field' => 123,
        ];
        $config = PostProcessorConfig::fromArray($data);

        $this->assertTrue($config->enabled);
        $this->assertNull($config->name);
        $this->assertNull($config->config);
    }

    #[Test]
    public function it_handles_json_with_numeric_values(): void
    {
        $json = json_encode([
            'enabled' => true,
            'name' => 'NumericConfig',
            'config' => [
                'timeout' => 5000,
                'retries' => 3,
                'weight' => 0.5,
            ],
        ]);
        $config = PostProcessorConfig::fromJson($json);

        $this->assertEquals(5000, $config->config['timeout']);
        $this->assertEquals(3, $config->config['retries']);
        $this->assertEquals(0.5, $config->config['weight']);
    }

    #[Test]
    public function it_serializes_enabled_false_correctly(): void
    {
        $config = new PostProcessorConfig(enabled: false);
        $array = $config->toArray();
        $json = $config->toJson();

        $this->assertFalse($array['enabled']);
        $decoded = json_decode($json, true);
        $this->assertFalse($decoded['enabled']);
    }

    #[Test]
    public function it_json_output_is_prettified(): void
    {
        $config = new PostProcessorConfig(
            enabled: true,
            name: 'PrettyProcessor',
            config: ['key' => 'value'],
        );
        $json = $config->toJson();

        // Pretty-printed JSON should contain newlines and indentation
        $this->assertStringContainsString("\n", $json);
        $this->assertStringContainsString('  ', $json);
    }

    #[Test]
    public function it_handles_config_with_boolean_values(): void
    {
        $config = new PostProcessorConfig(
            config: [
                'enabled_feature' => true,
                'disabled_feature' => false,
            ],
        );

        $array = $config->toArray();
        $this->assertTrue($array['config']['enabled_feature']);
        $this->assertFalse($array['config']['disabled_feature']);

        $json = $config->toJson();
        $restored = PostProcessorConfig::fromJson($json);
        $this->assertTrue($restored->config['enabled_feature']);
        $this->assertFalse($restored->config['disabled_feature']);
    }

    #[Test]
    public function it_can_be_used_with_mixed_type_config_objects(): void
    {
        // Test with object-like config (could be stdClass or array)
        $objectLikeConfig = [
            'module' => 'advanced',
            'parameters' => ['a' => 1, 'b' => 2],
        ];

        $config = new PostProcessorConfig(
            enabled: true,
            name: 'ObjectLikeProcessor',
            config: $objectLikeConfig,
        );

        $this->assertEquals('advanced', $config->config['module']);
        $this->assertEquals(['a' => 1, 'b' => 2], $config->config['parameters']);
    }
}
