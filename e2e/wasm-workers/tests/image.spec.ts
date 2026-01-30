// Auto-generated tests for image fixtures.
// Designed for Cloudflare Workers with Vitest + Miniflare

import type { ExtractionResult } from "@kreuzberg/wasm";
import { extractBytes } from "@kreuzberg/wasm";
import { describe, expect, it } from "vitest";
import { assertions, buildConfig, getFixture, shouldSkipFixture } from "./helpers.js";

describe("image", () => {
	it("image_metadata_only", async () => {
		const documentBytes = getFixture("images/example.jpg");
		if (documentBytes === null) {
			console.warn("[SKIP] Test skipped: fixture not available in Cloudflare Workers environment");
			return;
		}

		const config = buildConfig({ ocr: null });
		let result: ExtractionResult | null = null;
		try {
			result = await extractBytes(documentBytes, "image/jpeg", config);
		} catch (error) {
			if (shouldSkipFixture(error, "image_metadata_only", [], undefined)) {
				return;
			}
			throw error;
		}
		if (result === null) {
			return;
		}
		assertions.assertExpectedMime(result, ["image/jpeg"]);
		assertions.assertMaxContentLength(result, 100);
	});
});
