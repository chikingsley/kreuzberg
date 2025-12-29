<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Image preprocessing configuration for OCR.
 */
readonly class ImagePreprocessingConfig
{
    public function __construct(
        public ?int $targetDpi = null,
        public bool $autoRotate = false,
        public bool $deskew = false,
        public ?string $binarizationMethod = null,
        public bool $denoise = false,
        public bool $sharpen = false,
        public ?float $contrastAdjustment = null,
        public ?float $brightnessAdjustment = null,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var int|null $targetDpi */
        $targetDpi = $data['target_dpi'] ?? null;
        if ($targetDpi !== null && !is_int($targetDpi)) {
            /** @var int $targetDpi */
            $targetDpi = (int) $targetDpi;
        }

        /** @var bool $autoRotate */
        $autoRotate = $data['auto_rotate'] ?? false;
        if (!is_bool($autoRotate)) {
            /** @var bool $autoRotate */
            $autoRotate = (bool) $autoRotate;
        }

        /** @var bool $deskew */
        $deskew = $data['deskew'] ?? false;
        if (!is_bool($deskew)) {
            /** @var bool $deskew */
            $deskew = (bool) $deskew;
        }

        /** @var string|null $binarizationMethod */
        $binarizationMethod = $data['binarization_method'] ?? null;
        if ($binarizationMethod !== null && !is_string($binarizationMethod)) {
            /** @var string $binarizationMethod */
            $binarizationMethod = (string) $binarizationMethod;
        }

        /** @var bool $denoise */
        $denoise = $data['denoise'] ?? false;
        if (!is_bool($denoise)) {
            /** @var bool $denoise */
            $denoise = (bool) $denoise;
        }

        /** @var bool $sharpen */
        $sharpen = $data['sharpen'] ?? false;
        if (!is_bool($sharpen)) {
            /** @var bool $sharpen */
            $sharpen = (bool) $sharpen;
        }

        /** @var float|null $contrastAdjustment */
        $contrastAdjustment = $data['contrast_adjustment'] ?? null;
        if ($contrastAdjustment !== null && !is_float($contrastAdjustment)) {
            /** @var float $contrastAdjustment */
            $contrastAdjustment = (float) $contrastAdjustment;
        }

        /** @var float|null $brightnessAdjustment */
        $brightnessAdjustment = $data['brightness_adjustment'] ?? null;
        if ($brightnessAdjustment !== null && !is_float($brightnessAdjustment)) {
            /** @var float $brightnessAdjustment */
            $brightnessAdjustment = (float) $brightnessAdjustment;
        }

        return new self(
            targetDpi: $targetDpi,
            autoRotate: $autoRotate,
            deskew: $deskew,
            binarizationMethod: $binarizationMethod,
            denoise: $denoise,
            sharpen: $sharpen,
            contrastAdjustment: $contrastAdjustment,
            brightnessAdjustment: $brightnessAdjustment,
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
            'target_dpi' => $this->targetDpi,
            'auto_rotate' => $this->autoRotate,
            'deskew' => $this->deskew,
            'binarization_method' => $this->binarizationMethod,
            'denoise' => $this->denoise,
            'sharpen' => $this->sharpen,
            'contrast_adjustment' => $this->contrastAdjustment,
            'brightness_adjustment' => $this->brightnessAdjustment,
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
