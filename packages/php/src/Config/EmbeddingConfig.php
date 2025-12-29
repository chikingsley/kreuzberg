<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Embedding generation configuration.
 */
readonly class EmbeddingConfig
{
    public function __construct(
        public string $model = 'all-MiniLM-L6-v2',
        public bool $normalize = true,
        public ?int $batchSize = null,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var string $model */
        $model = $data['model'] ?? 'all-MiniLM-L6-v2';
        if (!is_string($model)) {
            /** @var string $model */
            $model = (string) $model;
        }

        /** @var bool $normalize */
        $normalize = $data['normalize'] ?? true;
        if (!is_bool($normalize)) {
            /** @var bool $normalize */
            $normalize = (bool) $normalize;
        }

        /** @var int|null $batchSize */
        $batchSize = $data['batch_size'] ?? null;
        if ($batchSize !== null && !is_int($batchSize)) {
            /** @var int $batchSize */
            $batchSize = (int) $batchSize;
        }

        return new self(
            model: $model,
            normalize: $normalize,
            batchSize: $batchSize,
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
            'model' => $this->model,
            'normalize' => $this->normalize,
            'batch_size' => $this->batchSize,
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
