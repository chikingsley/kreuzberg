/**
 * E2E test helpers for WASM workers - Thin adapter using @kreuzberg/test-utils
 * This file re-exports and adapts utilities from the shared test-utils package
 */

import type { ExtractionResult } from "@kreuzberg/wasm";
import {
	buildConfig,
	type ExtractionConfig,
} from "@kreuzberg/test-utils/config-mapping";
import {
	createAssertions,
	type ExtractionAssertions,
	type ExtractionResult as TestUtilsExtractionResult,
	VitestAdapter,
} from "@kreuzberg/test-utils/assertions";
import { shouldSkipFixture } from "@kreuzberg/test-utils/fixtures";

// Re-export core utilities
export { buildConfig, shouldSkipFixture };

// Create base assertions instance using VitestAdapter
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const baseAssertions = createAssertions<any>(new VitestAdapter());

// Wrapper that casts WASM ExtractionResult to test-utils compatible type
// The WASM ExtractionResult is structurally compatible with test-utils but lacks the [key: string]: unknown index signature
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const assertions: ExtractionAssertions<any> = {
	assertExpectedMime: (result, expected) =>
		baseAssertions.assertExpectedMime(result, expected),
	assertMinContentLength: (result, minimum) =>
		baseAssertions.assertMinContentLength(result, minimum),
	assertMaxContentLength: (result, maximum) =>
		baseAssertions.assertMaxContentLength(result, maximum),
	assertContentContainsAny: (result, snippets) =>
		baseAssertions.assertContentContainsAny(result, snippets),
	assertContentContainsAll: (result, snippets) =>
		baseAssertions.assertContentContainsAll(result, snippets),
	assertTableCount: (result, minimum, maximum) =>
		baseAssertions.assertTableCount(result, minimum, maximum),
	assertDetectedLanguages: (result, expected, minConfidence) =>
		baseAssertions.assertDetectedLanguages(result, expected, minConfidence),
	assertMetadataExpectation: (result, path, expectation) =>
		baseAssertions.assertMetadataExpectation(result, path, expectation),
};

/**
 * Get fixture for WASM workers environment
 * Note: Cloudflare Workers cannot access the filesystem, so this always returns null
 */
export function getFixture(fixturePath: string): Uint8Array | null {
	console.warn(`[SKIP] Cloudflare Workers cannot load fixtures from disk. Fixture: ${fixturePath}`);
	console.warn("[SKIP] These tests require filesystem access which is not available in the Workers sandbox.");
	return null;
}
