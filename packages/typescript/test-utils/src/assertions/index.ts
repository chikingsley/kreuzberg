/**
 * Assertion adapters and utilities for cross-platform testing
 * @module assertions
 */

// Export only assertion-specific types/functions, not duplicated ones like PlainRecord/isPlainRecord
export type { ExtractionResult, AssertionAdapter } from "./types.js";
export type { MetadataExpectation, ExtractionAssertions } from "./factory.js";
export { createAssertions } from "./factory.js";
export { VitestAdapter } from "./vitest-adapter.js";
export { DenoAdapter } from "./deno-adapter.js";
