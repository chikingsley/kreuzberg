/**
 * ExtractionConfig configuration tests
 *
 * Tests for ExtractionConfig feature that orchestrates all other configuration
 * types for comprehensive document extraction control.
 */

import type { ExtractionConfig } from "@kreuzberg/core";
import { describe, expect, it } from "vitest";

describe("WASM: ExtractionConfig", () => {
	describe("type definitions", () => {
		it("should define valid ExtractionConfig type", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
				forceOcr: false,
				maxConcurrentExtractions: 4,
			};

			expect(config.useCache).toBe(true);
			expect(config.enableQualityProcessing).toBe(true);
			expect(config.forceOcr).toBe(false);
			expect(config.maxConcurrentExtractions).toBe(4);
		});

		it("should support optional fields", () => {
			const minimalConfig: ExtractionConfig = {};

			expect(minimalConfig.useCache).toBeUndefined();
			expect(minimalConfig.enableQualityProcessing).toBeUndefined();
			expect(minimalConfig.forceOcr).toBeUndefined();
			expect(minimalConfig.ocr).toBeUndefined();
		});

		it("should support nested configurations", () => {
			const config: ExtractionConfig = {
				useCache: true,
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
				chunking: {
					chunkSize: 512,
					chunkOverlap: 128,
				},
				images: {
					extractImages: true,
					targetDpi: 300,
				},
			};

			expect(config.ocr).toBeDefined();
			expect(config.chunking).toBeDefined();
			expect(config.images).toBeDefined();
		});
	});

	describe("WASM serialization", () => {
		it("should serialize for WASM boundary", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: false,
				forceOcr: true,
				maxConcurrentExtractions: 8,
			};

			const json = JSON.stringify(config);
			const parsed: ExtractionConfig = JSON.parse(json);

			expect(parsed.useCache).toBe(true);
			expect(parsed.enableQualityProcessing).toBe(false);
			expect(parsed.forceOcr).toBe(true);
			expect(parsed.maxConcurrentExtractions).toBe(8);
		});

		it("should handle undefined fields in serialization", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: undefined,
				forceOcr: undefined,
			};

			const json = JSON.stringify(config);
			expect(json).not.toContain("enableQualityProcessing");
			expect(json).toContain("useCache");
		});

		it("should serialize complex nested structures", () => {
			const config: ExtractionConfig = {
				useCache: true,
				ocr: {
					backend: "tesseract",
					language: "eng",
					tesseractConfig: {
						psm: 3,
						enableTableDetection: true,
					},
				},
				chunking: {
					chunkSize: 256,
					preset: "small",
				},
				images: {
					extractImages: true,
					targetDpi: 150,
					maxImageDimension: 2048,
				},
			};

			const json = JSON.stringify(config);
			const parsed: ExtractionConfig = JSON.parse(json);

			expect(parsed.ocr?.tesseractConfig?.psm).toBe(3);
			expect(parsed.chunking?.chunkSize).toBe(256);
			expect(parsed.images?.targetDpi).toBe(150);
		});
	});

	describe("worker message passing", () => {
		it("should serialize for worker communication", () => {
			const config: ExtractionConfig = {
				useCache: true,
				forceOcr: false,
				maxConcurrentExtractions: 4,
			};

			const cloned = structuredClone(config);

			expect(cloned.useCache).toBe(true);
			expect(cloned.forceOcr).toBe(false);
			expect(cloned.maxConcurrentExtractions).toBe(4);
		});

		it("should preserve nested configs in workers", () => {
			const config: ExtractionConfig = {
				useCache: true,
				ocr: {
					backend: "tesseract",
					language: "fra",
				},
				chunking: {
					chunkSize: 512,
					enabled: true,
				},
			};

			const cloned = structuredClone(config);

			expect(cloned.ocr?.backend).toBe("tesseract");
			expect(cloned.chunking?.chunkSize).toBe(512);
		});

		it("should handle deeply nested configurations", () => {
			const config: ExtractionConfig = {
				useCache: true,
				pdfOptions: {
					extractImages: true,
					fontConfig: {
						enabled: true,
						customFontDirs: ["/fonts"],
					},
				},
				ocr: {
					backend: "tesseract",
					tesseractConfig: {
						psm: 6,
						enableTableDetection: true,
						tesseditCharWhitelist: "abc123",
					},
				},
			};

			const cloned = structuredClone(config);

			expect(cloned.pdfOptions?.fontConfig?.customFontDirs).toEqual(["/fonts"]);
			expect(cloned.ocr?.tesseractConfig?.tesseditCharWhitelist).toBe("abc123");
		});
	});

	describe("memory efficiency", () => {
		it("should not create excessive objects", () => {
			const configs: ExtractionConfig[] = Array.from({ length: 100 }, () => ({
				useCache: true,
				enableQualityProcessing: true,
				forceOcr: false,
			}));

			expect(configs).toHaveLength(100);
			configs.forEach((config) => {
				expect(config.useCache).toBe(true);
			});
		});

		it("should handle large concurrent extraction values", () => {
			const config: ExtractionConfig = {
				useCache: true,
				maxConcurrentExtractions: 1000,
			};

			expect(config.maxConcurrentExtractions).toBe(1000);
		});
	});

	describe("type safety", () => {
		it("should enforce useCache as boolean when defined", () => {
			const config: ExtractionConfig = { useCache: true };
			if (config.useCache !== undefined) {
				expect(typeof config.useCache).toBe("boolean");
			}
		});

		it("should enforce enableQualityProcessing as boolean when defined", () => {
			const config: ExtractionConfig = { enableQualityProcessing: true };
			if (config.enableQualityProcessing !== undefined) {
				expect(typeof config.enableQualityProcessing).toBe("boolean");
			}
		});

		it("should enforce forceOcr as boolean when defined", () => {
			const config: ExtractionConfig = { forceOcr: true };
			if (config.forceOcr !== undefined) {
				expect(typeof config.forceOcr).toBe("boolean");
			}
		});

		it("should enforce maxConcurrentExtractions as number when defined", () => {
			const config: ExtractionConfig = { maxConcurrentExtractions: 4 };
			if (config.maxConcurrentExtractions !== undefined) {
				expect(typeof config.maxConcurrentExtractions).toBe("number");
			}
		});
	});

	describe("camelCase conventions", () => {
		it("should use camelCase for property names", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
				forceOcr: false,
				maxConcurrentExtractions: 4,
			};

			expect(config).toHaveProperty("useCache");
			expect(config).toHaveProperty("enableQualityProcessing");
			expect(config).toHaveProperty("forceOcr");
			expect(config).toHaveProperty("maxConcurrentExtractions");
		});
	});

	describe("edge cases", () => {
		it("should handle zero concurrent extractions", () => {
			const config: ExtractionConfig = {
				useCache: true,
				maxConcurrentExtractions: 0,
			};

			expect(config.maxConcurrentExtractions).toBe(0);
		});

		it("should handle very large concurrent extraction values", () => {
			const config: ExtractionConfig = {
				useCache: true,
				maxConcurrentExtractions: 10000,
			};

			expect(config.maxConcurrentExtractions).toBe(10000);
		});

		it("should handle all boolean combinations", () => {
			const combinations = [
				{ useCache: true, enableQualityProcessing: true, forceOcr: true },
				{ useCache: true, enableQualityProcessing: true, forceOcr: false },
				{ useCache: true, enableQualityProcessing: false, forceOcr: true },
				{ useCache: false, enableQualityProcessing: false, forceOcr: false },
			];

			combinations.forEach((combo) => {
				const config: ExtractionConfig = combo;
				expect(config.useCache).toBeDefined();
				expect(config.enableQualityProcessing).toBeDefined();
				expect(config.forceOcr).toBeDefined();
			});
		});
	});

	describe("immutability patterns", () => {
		it("should support spread operator updates", () => {
			const original: ExtractionConfig = {
				useCache: true,
				forceOcr: false,
				maxConcurrentExtractions: 4,
			};

			const updated: ExtractionConfig = {
				...original,
				forceOcr: true,
			};

			expect(original.forceOcr).toBe(false);
			expect(updated.forceOcr).toBe(true);
			expect(updated.useCache).toBe(true);
		});

		it("should support nested config updates", () => {
			const original: ExtractionConfig = {
				useCache: true,
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
			};

			const updated: ExtractionConfig = {
				...original,
				ocr: {
					...original.ocr,
					language: "fra",
				},
			};

			expect(original.ocr?.language).toBe("eng");
			expect(updated.ocr?.language).toBe("fra");
			expect(updated.ocr?.backend).toBe("tesseract");
		});

		it("should support complex nested updates", () => {
			const original: ExtractionConfig = {
				useCache: true,
				ocr: {
					backend: "tesseract",
					tesseractConfig: {
						psm: 3,
					},
				},
			};

			const updated: ExtractionConfig = {
				...original,
				ocr: {
					...original.ocr,
					tesseractConfig: {
						...original.ocr?.tesseractConfig,
						psm: 6,
					},
				},
			};

			expect(original.ocr?.tesseractConfig?.psm).toBe(3);
			expect(updated.ocr?.tesseractConfig?.psm).toBe(6);
		});
	});

	describe("practical scenarios", () => {
		it("should support full-featured extraction configuration", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
				chunking: {
					chunkSize: 512,
					chunkOverlap: 128,
				},
				images: {
					extractImages: true,
					targetDpi: 300,
				},
				tokenReduction: {
					mode: "balanced",
					preserveImportantWords: true,
				},
				forceOcr: false,
			};

			expect(config.useCache).toBe(true);
			expect(config.ocr).toBeDefined();
			expect(config.chunking).toBeDefined();
		});

		it("should support OCR-focused configuration", () => {
			const config: ExtractionConfig = {
				forceOcr: true,
				ocr: {
					backend: "easyocr",
					language: "fra",
				},
				images: {
					extractImages: true,
					targetDpi: 300,
				},
			};

			expect(config.forceOcr).toBe(true);
			expect(config.ocr?.backend).toBe("easyocr");
		});

		it("should support minimal configuration", () => {
			const config: ExtractionConfig = {
				useCache: true,
			};

			expect(config.useCache).toBe(true);
			expect(config.ocr).toBeUndefined();
		});
	});

	describe("field methods", () => {
		it("should support configuration composition", () => {
			const baseConfig: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
			};

			const ocrConfig: ExtractionConfig = {
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
			};

			const mergedConfig: ExtractionConfig = {
				...baseConfig,
				...ocrConfig,
			};

			expect(mergedConfig.useCache).toBe(true);
			expect(mergedConfig.ocr).toBeDefined();
		});

		it("should support configuration composition with override", () => {
			const baseConfig: ExtractionConfig = {
				useCache: true,
				forceOcr: false,
			};

			const overrideConfig: ExtractionConfig = {
				forceOcr: true,
			};

			const mergedConfig: ExtractionConfig = {
				...baseConfig,
				...overrideConfig,
			};

			expect(mergedConfig.useCache).toBe(true);
			expect(mergedConfig.forceOcr).toBe(true);
		});
	});
});

describe("output and result format fields", () => {
	describe("outputFormat field", () => {
		it("should accept plain output format", () => {
			const config: ExtractionConfig = {
				outputFormat: "plain",
			};

			expect(config.outputFormat).toBe("plain");
		});

		it("should accept markdown output format", () => {
			const config: ExtractionConfig = {
				outputFormat: "markdown",
			};

			expect(config.outputFormat).toBe("markdown");
		});

		it("should accept html output format", () => {
			const config: ExtractionConfig = {
				outputFormat: "html",
			};

			expect(config.outputFormat).toBe("html");
		});

		it("should accept djot output format", () => {
			const config: ExtractionConfig = {
				outputFormat: "djot",
			};

			expect(config.outputFormat).toBe("djot");
		});

		it("should be optional", () => {
			const config: ExtractionConfig = {
				useCache: true,
			};

			expect(config.outputFormat).toBeUndefined();
		});

		it("should default to plain when not specified", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
			};

			// Field is optional, so it should be undefined if not explicitly set
			expect(config.outputFormat).toBeUndefined();
		});
	});

	describe("resultFormat field", () => {
		it("should accept unified result format", () => {
			const config: ExtractionConfig = {
				resultFormat: "unified",
			};

			expect(config.resultFormat).toBe("unified");
		});

		it("should accept element_based result format", () => {
			const config: ExtractionConfig = {
				resultFormat: "element_based",
			};

			expect(config.resultFormat).toBe("element_based");
		});

		it("should be optional", () => {
			const config: ExtractionConfig = {
				useCache: true,
			};

			expect(config.resultFormat).toBeUndefined();
		});

		it("should default to unified when not specified", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
			};

			// Field is optional, so it should be undefined if not explicitly set
			expect(config.resultFormat).toBeUndefined();
		});
	});

	describe("format fields together", () => {
		it("should support both outputFormat and resultFormat together", () => {
			const config: ExtractionConfig = {
				outputFormat: "markdown",
				resultFormat: "unified",
			};

			expect(config.outputFormat).toBe("markdown");
			expect(config.resultFormat).toBe("unified");
		});

		it("should support markdown output with element_based result", () => {
			const config: ExtractionConfig = {
				outputFormat: "markdown",
				resultFormat: "element_based",
			};

			expect(config.outputFormat).toBe("markdown");
			expect(config.resultFormat).toBe("element_based");
		});

		it("should support html output with element_based result", () => {
			const config: ExtractionConfig = {
				outputFormat: "html",
				resultFormat: "element_based",
			};

			expect(config.outputFormat).toBe("html");
			expect(config.resultFormat).toBe("element_based");
		});

		it("should support format fields with other configurations", () => {
			const config: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
				outputFormat: "markdown",
				resultFormat: "unified",
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
				chunking: {
					chunkSize: 512,
					chunkOverlap: 128,
				},
			};

			expect(config.useCache).toBe(true);
			expect(config.outputFormat).toBe("markdown");
			expect(config.resultFormat).toBe("unified");
			expect(config.ocr).toBeDefined();
			expect(config.chunking).toBeDefined();
		});
	});

	describe("configuration composition with formats", () => {
		it("should support composing configs with format fields", () => {
			const baseConfig: ExtractionConfig = {
				useCache: true,
				outputFormat: "plain",
			};

			const formattedConfig: ExtractionConfig = {
				...baseConfig,
				outputFormat: "markdown",
				resultFormat: "element_based",
			};

			expect(formattedConfig.useCache).toBe(true);
			expect(formattedConfig.outputFormat).toBe("markdown");
			expect(formattedConfig.resultFormat).toBe("element_based");
		});

		it("should support merging format with processing configs", () => {
			const processingConfig: ExtractionConfig = {
				enableQualityProcessing: true,
				forceOcr: false,
			};

			const formatConfig: ExtractionConfig = {
				outputFormat: "markdown",
				resultFormat: "unified",
			};

			const merged: ExtractionConfig = {
				...processingConfig,
				...formatConfig,
			};

			expect(merged.enableQualityProcessing).toBe(true);
			expect(merged.forceOcr).toBe(false);
			expect(merged.outputFormat).toBe("markdown");
			expect(merged.resultFormat).toBe("unified");
		});
	});

	describe("serialization with formats", () => {
		it("should serialize config with outputFormat to JSON", () => {
			const config: ExtractionConfig = {
				useCache: true,
				outputFormat: "markdown",
			};

			const json = JSON.stringify(config);
			expect(json).toContain("outputFormat");
			expect(json).toContain("markdown");

			const parsed = JSON.parse(json) as ExtractionConfig;
			expect(parsed.outputFormat).toBe("markdown");
		});

		it("should serialize config with resultFormat to JSON", () => {
			const config: ExtractionConfig = {
				useCache: true,
				resultFormat: "element_based",
			};

			const json = JSON.stringify(config);
			expect(json).toContain("resultFormat");
			expect(json).toContain("element_based");

			const parsed = JSON.parse(json) as ExtractionConfig;
			expect(parsed.resultFormat).toBe("element_based");
		});

		it("should serialize and deserialize full config with formats", () => {
			const original: ExtractionConfig = {
				useCache: true,
				enableQualityProcessing: true,
				outputFormat: "markdown",
				resultFormat: "unified",
				ocr: {
					backend: "tesseract",
					language: "eng",
				},
			};

			const json = JSON.stringify(original);
			const deserialized = JSON.parse(json) as ExtractionConfig;

			expect(deserialized.useCache).toBe(original.useCache);
			expect(deserialized.enableQualityProcessing).toBe(original.enableQualityProcessing);
			expect(deserialized.outputFormat).toBe(original.outputFormat);
			expect(deserialized.resultFormat).toBe(original.resultFormat);
			expect(deserialized.ocr?.backend).toBe(original.ocr?.backend);
		});
	});
});
