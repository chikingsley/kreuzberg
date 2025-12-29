<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * OCR configuration.
 */
readonly class OcrConfig
{
    public function __construct(
        public string $backend = 'tesseract',
        public string $language = 'eng',
        public ?TesseractConfig $tesseractConfig = null,
        public ?ImagePreprocessingConfig $imagePreprocessing = null,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var string $backend */
        $backend = $data['backend'] ?? 'tesseract';
        if (!is_string($backend)) {
            /** @var string $backend */
            $backend = (string) $backend;
        }

        /** @var string $language */
        $language = $data['language'] ?? 'eng';
        if (!is_string($language)) {
            /** @var string $language */
            $language = (string) $language;
        }

        /** @var TesseractConfig|null $tesseractConfig */
        $tesseractConfig = null;
        if (isset($data['tesseract_config'])) {
            $configData = $data['tesseract_config'];
            if (!is_array($configData)) {
                /** @var array<string, mixed> $configData */
                $configData = (array) $configData;
            }
            /** @var array<string, mixed> $configData */
            $tesseractConfig = TesseractConfig::fromArray($configData);
        }

        /** @var ImagePreprocessingConfig|null $imagePreprocessing */
        $imagePreprocessing = null;
        if (isset($data['image_preprocessing'])) {
            $configData = $data['image_preprocessing'];
            if (!is_array($configData)) {
                /** @var array<string, mixed> $configData */
                $configData = (array) $configData;
            }
            /** @var array<string, mixed> $configData */
            $imagePreprocessing = ImagePreprocessingConfig::fromArray($configData);
        }

        return new self(
            backend: $backend,
            language: $language,
            tesseractConfig: $tesseractConfig,
            imagePreprocessing: $imagePreprocessing,
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
            'backend' => $this->backend,
            'language' => $this->language,
            'tesseract_config' => $this->tesseractConfig?->toArray(),
            'image_preprocessing' => $this->imagePreprocessing?->toArray(),
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
