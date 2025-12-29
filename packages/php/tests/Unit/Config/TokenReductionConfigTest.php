<?php

declare(strict_types=1);

namespace Kreuzberg\Tests\Unit\Config;

use Kreuzberg\Config\TokenReductionConfig;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * Unit tests for TokenReductionConfig readonly class.
 *
 * Tests construction, serialization, factory methods, readonly enforcement,
 * and integration with the configuration system. Validates that the token
 * reduction configuration can be created, serialized, and properly enforced
 * as readonly to prevent accidental modifications.
 *
 * Test Coverage:
 * - Construction with default values
 * - Construction with custom values
 * - toArray() serialization with proper snake_case conversion
 * - fromArray() factory method with defaults
 * - fromJson() factory method with JSON parsing
 * - toJson() serialization to JSON string
 * - Readonly enforcement (modification prevention)
 * - Edge cases (empty strings, boolean values)
 * - Invalid JSON handling
 * - Round-trip serialization/deserialization
 */
#[CoversClass(TokenReductionConfig::class)]
#[Group('unit')]
#[Group('config')]
final class TokenReductionConfigTest extends TestCase
{
    #[Test]
    public function it_creates_with_default_values(): void
    {
        $config = new TokenReductionConfig();

        $this->assertEquals('off', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_creates_with_custom_values(): void
    {
        $config = new TokenReductionConfig(
            mode: 'aggressive',
            preserveImportantWords: false,
        );

        $this->assertEquals('aggressive', $config->mode);
        $this->assertFalse($config->preserveImportantWords);
    }

    #[Test]
    public function it_serializes_to_array(): void
    {
        $config = new TokenReductionConfig(
            mode: 'moderate',
            preserveImportantWords: true,
        );
        $array = $config->toArray();

        $this->assertIsArray($array);
        $this->assertEquals('moderate', $array['mode']);
        $this->assertTrue($array['preserve_important_words']);
    }

    #[Test]
    public function it_serializes_mode_in_array(): void
    {
        $modes = ['off', 'aggressive', 'moderate', 'custom'];

        foreach ($modes as $mode) {
            $config = new TokenReductionConfig(mode: $mode);
            $array = $config->toArray();

            $this->assertEquals($mode, $array['mode']);
        }
    }

    #[Test]
    public function it_serializes_preserve_important_words_in_array(): void
    {
        $config1 = new TokenReductionConfig(preserveImportantWords: true);
        $array1 = $config1->toArray();
        $this->assertTrue($array1['preserve_important_words']);

        $config2 = new TokenReductionConfig(preserveImportantWords: false);
        $array2 = $config2->toArray();
        $this->assertFalse($array2['preserve_important_words']);
    }

    #[Test]
    public function it_creates_from_array_with_snake_case_keys(): void
    {
        $data = [
            'mode' => 'aggressive',
            'preserve_important_words' => false,
        ];
        $config = TokenReductionConfig::fromArray($data);

        $this->assertEquals('aggressive', $config->mode);
        $this->assertFalse($config->preserveImportantWords);
    }

    #[Test]
    public function it_creates_from_array_with_missing_keys_using_defaults(): void
    {
        $data = ['mode' => 'moderate'];
        $config = TokenReductionConfig::fromArray($data);

        $this->assertEquals('moderate', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_creates_from_array_with_all_defaults(): void
    {
        $config = TokenReductionConfig::fromArray([]);

        $this->assertEquals('off', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_serializes_to_json(): void
    {
        $config = new TokenReductionConfig(
            mode: 'aggressive',
            preserveImportantWords: false,
        );
        $json = $config->toJson();

        $this->assertJson($json);
        $decoded = json_decode($json, true);

        $this->assertEquals('aggressive', $decoded['mode']);
        $this->assertFalse($decoded['preserve_important_words']);
    }

    #[Test]
    public function it_creates_from_json(): void
    {
        $json = json_encode([
            'mode' => 'moderate',
            'preserve_important_words' => true,
        ]);
        $config = TokenReductionConfig::fromJson($json);

        $this->assertEquals('moderate', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_creates_from_json_with_missing_fields(): void
    {
        $json = json_encode(['mode' => 'custom']);
        $config = TokenReductionConfig::fromJson($json);

        $this->assertEquals('custom', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_round_trips_through_json(): void
    {
        $original = new TokenReductionConfig(
            mode: 'moderate',
            preserveImportantWords: false,
        );

        $json = $original->toJson();
        $restored = TokenReductionConfig::fromJson($json);

        $this->assertEquals($original->mode, $restored->mode);
        $this->assertEquals($original->preserveImportantWords, $restored->preserveImportantWords);
    }

    #[Test]
    public function it_throws_on_invalid_json(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid JSON');

        TokenReductionConfig::fromJson('{ not valid json ]');
    }

    #[Test]
    public function it_throws_on_empty_json_string(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Invalid JSON');

        TokenReductionConfig::fromJson('');
    }

    #[Test]
    public function it_enforces_readonly_on_mode_property(): void
    {
        $this->expectException(\Error::class);

        $config = new TokenReductionConfig(mode: 'off');
        $config->mode = 'aggressive';
    }

    #[Test]
    public function it_enforces_readonly_on_preserve_important_words_property(): void
    {
        $this->expectException(\Error::class);

        $config = new TokenReductionConfig(preserveImportantWords: true);
        $config->preserveImportantWords = false;
    }

    #[Test]
    public function it_handles_various_mode_values(): void
    {
        $modes = [
            'off',
            'aggressive',
            'moderate',
            'light',
            'custom',
            'advanced',
        ];

        foreach ($modes as $mode) {
            $config = new TokenReductionConfig(mode: $mode);
            $this->assertEquals($mode, $config->mode);

            $array = $config->toArray();
            $this->assertEquals($mode, $array['mode']);
        }
    }

    #[Test]
    public function it_handles_empty_mode_string(): void
    {
        $config = new TokenReductionConfig(mode: '');

        $this->assertEquals('', $config->mode);
        $array = $config->toArray();
        $this->assertEquals('', $array['mode']);
    }

    #[Test]
    public function it_handles_array_with_extra_unknown_keys(): void
    {
        $data = [
            'mode' => 'moderate',
            'unknown_key' => 'ignored',
            'another_field' => 999,
        ];
        $config = TokenReductionConfig::fromArray($data);

        $this->assertEquals('moderate', $config->mode);
        $this->assertTrue($config->preserveImportantWords);
    }

    #[Test]
    public function it_creates_from_json_with_extra_fields(): void
    {
        $json = json_encode([
            'mode' => 'aggressive',
            'preserve_important_words' => false,
            'extra_field' => 'should be ignored',
            'nested' => ['structure' => 'also ignored'],
        ]);
        $config = TokenReductionConfig::fromJson($json);

        $this->assertEquals('aggressive', $config->mode);
        $this->assertFalse($config->preserveImportantWords);
    }

    #[Test]
    public function it_serializes_boolean_true_correctly(): void
    {
        $config = new TokenReductionConfig(preserveImportantWords: true);
        $array = $config->toArray();
        $json = $config->toJson();

        $this->assertTrue($array['preserve_important_words']);
        $decoded = json_decode($json, true);
        $this->assertTrue($decoded['preserve_important_words']);
    }

    #[Test]
    public function it_serializes_boolean_false_correctly(): void
    {
        $config = new TokenReductionConfig(preserveImportantWords: false);
        $array = $config->toArray();
        $json = $config->toJson();

        $this->assertFalse($array['preserve_important_words']);
        $decoded = json_decode($json, true);
        $this->assertFalse($decoded['preserve_important_words']);
    }

    #[Test]
    public function it_json_output_is_prettified(): void
    {
        $config = new TokenReductionConfig(mode: 'moderate');
        $json = $config->toJson();

        // Pretty-printed JSON should contain newlines and indentation
        $this->assertStringContainsString("\n", $json);
        $this->assertStringContainsString('  ', $json);
    }

    #[Test]
    public function it_handles_json_with_boolean_strings(): void
    {
        $json = json_encode([
            'mode' => 'custom',
            'preserve_important_words' => true,
        ]);
        $config = TokenReductionConfig::fromJson($json);

        $this->assertTrue($config->preserveImportantWords);
    }
}
