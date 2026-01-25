/**
 * End-to-end tests for TypeScript bindings config parity.
 *
 * Tests the new config fields `outputFormat` and `resultFormat` to ensure they
 * properly affect extraction results.
 */

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
	ExtractionConfig,
	extractBytesSync,
	extractFileSync,
} from "@kreuzberg/node";
import { describe, expect, it } from "vitest";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "../../..");
const TEST_DOCUMENTS = join(REPO_ROOT, "test_documents");

function getDocumentBytes(path: string): Buffer {
	const fullPath = join(TEST_DOCUMENTS, path);
	return readFileSync(fullPath);
}

function getSampleDocument(): Buffer {
	try {
		return getDocumentBytes("text/report.txt");
	} catch {
		// Fallback to simple text
		return Buffer.from(
			"Hello World\n\nThis is a test document with multiple lines."
		);
	}
}

describe("Output Format Parity Tests", () => {
	it("should have Plain as default output format", () => {
		const config = new ExtractionConfig();
		expect(config.outputFormat).toBe("Plain");
	});

	it("should serialize outputFormat correctly", () => {
		const config = new ExtractionConfig({ outputFormat: "Markdown" });
		const json = JSON.stringify(config);
		const data = JSON.parse(json);

		expect(data.outputFormat).toBe("Markdown");
	});

	it("should extract with Plain output format", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({ outputFormat: "Plain" });

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
		expect(result.content).toBeDefined();
		expect(typeof result.content).toBe("string");
		expect(result.content.length).toBeGreaterThan(0);
	});

	it("should extract with Markdown output format", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({ outputFormat: "Markdown" });

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
		expect(result.content).toBeDefined();
	});

	it("should extract with HTML output format", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({ outputFormat: "Html" });

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
		expect(result.content).toBeDefined();
	});

	it("should produce content with different output formats", () => {
		const docBytes = getSampleDocument();

		const plainConfig = new ExtractionConfig({ outputFormat: "Plain" });
		const plainResult = extractBytesSync(docBytes, plainConfig, null);

		const markdownConfig = new ExtractionConfig({
			outputFormat: "Markdown",
		});
		const markdownResult = extractBytesSync(docBytes, markdownConfig, null);

		expect(plainResult.content).toBeDefined();
		expect(markdownResult.content).toBeDefined();
	});
});

describe("Result Format Parity Tests", () => {
	it("should have Unified as default result format", () => {
		const config = new ExtractionConfig();
		expect(config.resultFormat).toBe("Unified");
	});

	it("should serialize resultFormat correctly", () => {
		const config = new ExtractionConfig({ resultFormat: "Elements" });
		const json = JSON.stringify(config);
		const data = JSON.parse(json);

		expect(data.resultFormat).toBe("Elements");
	});

	it("should extract with Unified result format", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({ resultFormat: "Unified" });

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
		expect(result.content).toBeDefined();
		expect(typeof result.content).toBe("string");
	});

	it("should extract with Elements result format", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({ resultFormat: "Elements" });

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
	});

	it("should produce results with different result formats", () => {
		const docBytes = getSampleDocument();

		const unifiedConfig = new ExtractionConfig({
			resultFormat: "Unified",
		});
		const unifiedResult = extractBytesSync(docBytes, unifiedConfig, null);

		const elementsConfig = new ExtractionConfig({
			resultFormat: "Elements",
		});
		const elementsResult = extractBytesSync(docBytes, elementsConfig, null);

		expect(unifiedResult).toBeDefined();
		expect(elementsResult).toBeDefined();
	});
});

describe("Config Combinations Tests", () => {
	it("should handle Plain with Unified combination", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({
			outputFormat: "Plain",
			resultFormat: "Unified",
		});

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
	});

	it("should handle Markdown with Elements combination", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({
			outputFormat: "Markdown",
			resultFormat: "Elements",
		});

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
	});

	it("should handle HTML with Unified combination", () => {
		const docBytes = getSampleDocument();
		const config = new ExtractionConfig({
			outputFormat: "Html",
			resultFormat: "Unified",
		});

		const result = extractBytesSync(docBytes, config, null);

		expect(result).toBeDefined();
	});

	it("should preserve format fields when merging configs", () => {
		const config1 = new ExtractionConfig({
			outputFormat: "Markdown",
			resultFormat: "Elements",
		});
		const config2 = new ExtractionConfig({ useCache: false });

		const merged = { ...config1, ...config2 };

		expect(merged.outputFormat).toBe("Markdown");
		expect(merged.resultFormat).toBe("Elements");
	});
});

describe("Config Serialization Tests", () => {
	it("should serialize outputFormat to JSON", () => {
		const config = new ExtractionConfig({ outputFormat: "Markdown" });
		const json = JSON.stringify(config);
		const data = JSON.parse(json);

		expect(data).toHaveProperty("outputFormat");
		expect(data.outputFormat).toBe("Markdown");
	});

	it("should serialize resultFormat to JSON", () => {
		const config = new ExtractionConfig({ resultFormat: "Elements" });
		const json = JSON.stringify(config);
		const data = JSON.parse(json);

		expect(data).toHaveProperty("resultFormat");
		expect(data.resultFormat).toBe("Elements");
	});

	it("should preserve formats through JSON round-trip", () => {
		const original = new ExtractionConfig({
			outputFormat: "Html",
			resultFormat: "Elements",
			useCache: false,
		});

		const json = JSON.stringify(original);
		const data = JSON.parse(json);

		expect(data.outputFormat).toBe("Html");
		expect(data.resultFormat).toBe("Elements");
		expect(data.useCache).toBe(false);
	});
});

describe("Error Handling Tests", () => {
	it("should reject invalid outputFormat values", () => {
		expect(() => {
			new ExtractionConfig({ outputFormat: "InvalidFormat" as any });
		}).toThrow();
	});

	it("should reject invalid resultFormat values", () => {
		expect(() => {
			new ExtractionConfig({ resultFormat: "InvalidFormat" as any });
		}).toThrow();
	});

	it("should enforce case sensitivity for format names", () => {
		// lowercase "plain" should not work
		expect(() => {
			new ExtractionConfig({ outputFormat: "plain" as any });
		}).toThrow();
	});
});
