/**
 * Cross-language serialization tests for TypeScript bindings.
 *
 * Validates that ExtractionConfig serializes consistently with other language bindings.
 */

import { describe, it, expect } from 'vitest';
import { ExtractionConfig } from '../src/index';

describe('ExtractionConfig Serialization', () => {
  it('should serialize minimal config to JSON', () => {
    const config = new ExtractionConfig();
    const json = JSON.stringify(config);
    const parsed = JSON.parse(json);

    expect(parsed).toBeDefined();
    expect(parsed).toHaveProperty('useCache');
    expect(parsed).toHaveProperty('enableQualityProcessing');
    expect(parsed).toHaveProperty('forceOcr');
  });

  it('should serialize config with all fields', () => {
    const config = new ExtractionConfig({
      useCache: true,
      enableQualityProcessing: true,
      forceOcr: false,
    });

    const json = JSON.stringify(config);
    const parsed = JSON.parse(json);

    expect(parsed.useCache).toBe(true);
    expect(parsed.enableQualityProcessing).toBe(true);
    expect(parsed.forceOcr).toBe(false);
  });

  it('should preserve field values after serialization', () => {
    const original = new ExtractionConfig({
      useCache: false,
      enableQualityProcessing: true,
    });

    const json = JSON.stringify(original);
    const parsed = JSON.parse(json);

    expect(parsed.useCache).toBe(false);
    expect(parsed.enableQualityProcessing).toBe(true);
  });

  it('should handle serialization round-trip', () => {
    const config1 = new ExtractionConfig({
      useCache: true,
      enableQualityProcessing: false,
    });

    const json1 = JSON.stringify(config1);
    const parsed1 = JSON.parse(json1);

    const config2 = new ExtractionConfig(parsed1);
    const json2 = JSON.stringify(config2);

    expect(json1).toEqual(json2);
  });

  it('should use camelCase field names', () => {
    const config = new ExtractionConfig({
      useCache: true,
    });

    const json = JSON.stringify(config);
    expect(json).toContain('useCache');
    expect(json).not.toContain('use_cache');
  });

  it('should serialize with nested ocr config', () => {
    const config = new ExtractionConfig({
      ocr: {
        backend: 'tesseract',
        language: 'eng',
      },
    });

    const json = JSON.stringify(config);
    const parsed = JSON.parse(json);

    expect(parsed.ocr).toBeDefined();
    expect(parsed.ocr.backend).toBe('tesseract');
    expect(parsed.ocr.language).toBe('eng');
  });

  it('should handle null/undefined values correctly', () => {
    const config = new ExtractionConfig({
      ocr: undefined,
      chunking: null,
    });

    const json = JSON.stringify(config);
    const parsed = JSON.parse(json);

    // Should be valid JSON without errors
    expect(parsed).toBeDefined();
  });

  it('should maintain immutability during serialization', () => {
    const config = new ExtractionConfig({
      useCache: true,
    });

    const original = JSON.stringify(config);

    // Serialize multiple times
    JSON.stringify(config);
    JSON.stringify(config);

    const final = JSON.stringify(config);
    expect(original).toEqual(final);
  });

  it('should serialize all mandatory fields', () => {
    const config = new ExtractionConfig();
    const json = JSON.stringify(config);
    const parsed = JSON.parse(json);

    const mandatoryFields = [
      'useCache',
      'enableQualityProcessing',
      'forceOcr',
    ];

    mandatoryFields.forEach(field => {
      expect(parsed).toHaveProperty(field);
    });
  });
});
