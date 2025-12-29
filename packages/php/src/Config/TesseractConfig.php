<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Tesseract OCR configuration.
 */
readonly class TesseractConfig
{
    public function __construct(
        public ?int $psm = null,
        public ?int $oem = null,
        public bool $enableTableDetection = false,
        public ?string $tesseditCharWhitelist = null,
        public ?string $tesseditCharBlacklist = null,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var int|null $psm */
        $psm = $data['psm'] ?? null;
        if ($psm !== null && !is_int($psm)) {
            /** @var int $psm */
            $psm = (int) $psm;
        }

        /** @var int|null $oem */
        $oem = $data['oem'] ?? null;
        if ($oem !== null && !is_int($oem)) {
            /** @var int $oem */
            $oem = (int) $oem;
        }

        /** @var bool $enableTableDetection */
        $enableTableDetection = $data['enable_table_detection'] ?? false;
        if (!is_bool($enableTableDetection)) {
            /** @var bool $enableTableDetection */
            $enableTableDetection = (bool) $enableTableDetection;
        }

        /** @var string|null $tesseditCharWhitelist */
        $tesseditCharWhitelist = $data['tessedit_char_whitelist'] ?? null;
        if ($tesseditCharWhitelist !== null && !is_string($tesseditCharWhitelist)) {
            /** @var string $tesseditCharWhitelist */
            $tesseditCharWhitelist = (string) $tesseditCharWhitelist;
        }

        /** @var string|null $tesseditCharBlacklist */
        $tesseditCharBlacklist = $data['tessedit_char_blacklist'] ?? null;
        if ($tesseditCharBlacklist !== null && !is_string($tesseditCharBlacklist)) {
            /** @var string $tesseditCharBlacklist */
            $tesseditCharBlacklist = (string) $tesseditCharBlacklist;
        }

        return new self(
            psm: $psm,
            oem: $oem,
            enableTableDetection: $enableTableDetection,
            tesseditCharWhitelist: $tesseditCharWhitelist,
            tesseditCharBlacklist: $tesseditCharBlacklist,
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
            'psm' => $this->psm,
            'oem' => $this->oem,
            'enable_table_detection' => $this->enableTableDetection,
            'tessedit_char_whitelist' => $this->tesseditCharWhitelist,
            'tessedit_char_blacklist' => $this->tesseditCharBlacklist,
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
