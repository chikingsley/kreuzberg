<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Hierarchy detection configuration.
 */
readonly class HierarchyConfig
{
    public function __construct(
        public bool $enabled = true,
        public int $kClusters = 6,
        public bool $includeBbox = true,
        public ?float $ocrCoverageThreshold = null,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var bool $enabled */
        $enabled = $data['enabled'] ?? true;
        if (!is_bool($enabled)) {
            /** @var bool $enabled */
            $enabled = (bool) $enabled;
        }

        /** @var int $kClusters */
        $kClusters = $data['k_clusters'] ?? 6;
        if (!is_int($kClusters)) {
            /** @var int $kClusters */
            $kClusters = (int) $kClusters;
        }

        /** @var bool $includeBbox */
        $includeBbox = $data['include_bbox'] ?? true;
        if (!is_bool($includeBbox)) {
            /** @var bool $includeBbox */
            $includeBbox = (bool) $includeBbox;
        }

        /** @var float|null $ocrCoverageThreshold */
        $ocrCoverageThreshold = $data['ocr_coverage_threshold'] ?? null;
        if ($ocrCoverageThreshold !== null && !is_float($ocrCoverageThreshold)) {
            /** @var float $ocrCoverageThreshold */
            $ocrCoverageThreshold = (float) $ocrCoverageThreshold;
        }

        return new self(
            enabled: $enabled,
            kClusters: $kClusters,
            includeBbox: $includeBbox,
            ocrCoverageThreshold: $ocrCoverageThreshold,
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
        $array = [
            'enabled' => $this->enabled,
            'k_clusters' => $this->kClusters,
            'include_bbox' => $this->includeBbox,
        ];

        if ($this->ocrCoverageThreshold !== null) {
            $array['ocr_coverage_threshold'] = $this->ocrCoverageThreshold;
        }

        return $array;
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
