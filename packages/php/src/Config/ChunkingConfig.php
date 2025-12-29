<?php

declare(strict_types=1);

namespace Kreuzberg\Config;

/**
 * Text chunking configuration.
 */
readonly class ChunkingConfig
{
    public function __construct(
        public int $maxChunkSize = 512,
        public int $chunkOverlap = 50,
        public bool $respectSentences = true,
        public bool $respectParagraphs = true,
    ) {
    }

    /**
     * Create configuration from array data.
     *
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        /** @var int $maxChunkSize */
        $maxChunkSize = $data['max_chunk_size'] ?? 512;
        if (!is_int($maxChunkSize)) {
            /** @var int $maxChunkSize */
            $maxChunkSize = (int) $maxChunkSize;
        }

        /** @var int $chunkOverlap */
        $chunkOverlap = $data['chunk_overlap'] ?? 50;
        if (!is_int($chunkOverlap)) {
            /** @var int $chunkOverlap */
            $chunkOverlap = (int) $chunkOverlap;
        }

        /** @var bool $respectSentences */
        $respectSentences = $data['respect_sentences'] ?? true;
        if (!is_bool($respectSentences)) {
            /** @var bool $respectSentences */
            $respectSentences = (bool) $respectSentences;
        }

        /** @var bool $respectParagraphs */
        $respectParagraphs = $data['respect_paragraphs'] ?? true;
        if (!is_bool($respectParagraphs)) {
            /** @var bool $respectParagraphs */
            $respectParagraphs = (bool) $respectParagraphs;
        }

        return new self(
            maxChunkSize: $maxChunkSize,
            chunkOverlap: $chunkOverlap,
            respectSentences: $respectSentences,
            respectParagraphs: $respectParagraphs,
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
        return [
            'max_chunk_size' => $this->maxChunkSize,
            'chunk_overlap' => $this->chunkOverlap,
            'respect_sentences' => $this->respectSentences,
            'respect_paragraphs' => $this->respectParagraphs,
        ];
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
