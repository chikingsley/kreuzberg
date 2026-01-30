// Auto-generated tests for email fixtures.
// Designed for Cloudflare Workers with Vitest + Miniflare

import type { ExtractionResult } from "@kreuzberg/wasm";
import { extractBytes } from "@kreuzberg/wasm";
import { describe, expect, it } from "vitest";
import { assertions, buildConfig, getFixture, shouldSkipFixture } from "./helpers.js";

describe("email", () => {
	it("email_sample_eml", async () => {
		const documentBytes = getFixture("email/sample_email.eml");
		if (documentBytes === null) {
			console.warn("[SKIP] Test skipped: fixture not available in Cloudflare Workers environment");
			return;
		}

		const config = buildConfig(undefined);
		let result: ExtractionResult | null = null;
		try {
			result = await extractBytes(documentBytes, "message/rfc822", config);
		} catch (error) {
			if (shouldSkipFixture(error, "email_sample_eml", [], undefined)) {
				return;
			}
			throw error;
		}
		if (result === null) {
			return;
		}
		assertions.assertExpectedMime(result, ["message/rfc822"]);
		assertions.assertMinContentLength(result, 20);
	});
});
