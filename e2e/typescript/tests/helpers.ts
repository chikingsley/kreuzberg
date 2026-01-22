/**
 * E2E test helpers - Thin adapter using @kreuzberg/test-utils
 * This file re-exports and adapts utilities from the shared test-utils package
 */

import {
	buildConfig,
	type ExtractionConfig,
} from "@kreuzberg/test-utils/config-mapping";
import {
	createAssertions,
	type ExtractionAssertions,
	VitestAdapter,
} from "@kreuzberg/test-utils/assertions";
import { resolveDocument } from "@kreuzberg/test-utils/paths";
import { shouldSkipFixture } from "@kreuzberg/test-utils/fixtures";
import type { ExtractionResult } from "@kreuzberg/node";

// Re-export core utilities
export { buildConfig, resolveDocument, shouldSkipFixture };

// Create and export assertions instance using VitestAdapter
export const assertions: ExtractionAssertions<ExtractionResult> =
	createAssertions<ExtractionResult>(new VitestAdapter());
