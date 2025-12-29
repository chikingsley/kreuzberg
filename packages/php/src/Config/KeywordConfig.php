<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Keyword extraction configuration.
 */
readonly class KeywordConfig
{
    public function __construct(
        public int $maxKeywords = 10,
        public float $minScore = 0.0,
        public ?string $language = 'en',
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var int $maxKeywords */
        $maxKeywords = $data['max_keywords'] ?? 10;
        if (!is_int($maxKeywords)) {
            /** @var int $maxKeywords */
            $maxKeywords = (int) $maxKeywords;
        }

        /** @var float $minScore */
        $minScore = $data['min_score'] ?? 0.0;
        if (!is_float($minScore) && !is_int($minScore)) {
            /** @var float $minScore */
            $minScore = (float) $minScore;
        }

        /** @var string|null $language */
        $language = $data['language'] ?? 'en';
        if (!is_string($language)) {
            /** @var string $language */
            $language = (string) $language;
        }

        return new self(
            maxKeywords: $maxKeywords,
            minScore: (float) $minScore,
            language: $language,
        );
    }

    /**
     * Create configuration from JSON string.
     */
    public static function fromJson(string $json): self
    {
        $data = json_decode($json, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \InvalidArgumentException('Invalid JSON: ' . json_last_error_msg());
        }
        if (!is_array($data)) {
            throw new \InvalidArgumentException('JSON must decode to an object/array');
        }
        /** @var array<string, mixed> $data */
        return self::fromArray($data);
    }

    /**
     * Create configuration from JSON file.
     */
    public static function fromFile(string $path): self
    {
        if (!file_exists($path)) {
            throw new \InvalidArgumentException("File not found: {$path}");
        }
        $contents = file_get_contents($path);
        if ($contents === false) {
            throw new \InvalidArgumentException("Unable to read file: {$path}");
        }
        return self::fromJson($contents);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return array_filter([
            'max_keywords' => $this->maxKeywords,
            'min_score' => $this->minScore,
            'language' => $this->language,
        ], static fn ($value): bool => $value !== null);
    }

    /**
     * Convert configuration to JSON string.
     */
    public function toJson(): string
    {
        $json = json_encode($this->toArray(), JSON_PRETTY_PRINT);
        if ($json === false) {
            throw new \RuntimeException('Failed to encode configuration to JSON');
        }
        return $json;
    }
}
