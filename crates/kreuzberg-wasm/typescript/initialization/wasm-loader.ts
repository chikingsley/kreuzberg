/**
 * WASM Module Loader
 *
 * Handles WASM module loading, initialization, and state management.
 * Provides a clean interface for loading the Kreuzberg WASM module
 * with support for concurrent initialization calls.
 */

import { wrapWasmError } from "../adapters/wasm-adapter.js";
import { hasWasm, isBrowser } from "../runtime.js";
import { initializePdfiumAsync } from "./pdfium-loader.js";
import {
	getInitializationError,
	getInitializationPromise,
	getWasmModule,
	isInitialized,
	type ModuleInfo,
	setInitializationError,
	setInitializationPromise,
	setInitialized,
	setWasmModule,
	type WasmModule,
} from "./state.js";

export type { WasmModule, ModuleInfo };

/**
 * Get the loaded WASM module
 *
 * @returns The WASM module instance or null if not loaded
 * @internal
 */
export { getWasmModule };

/**
 * Check if WASM module is initialized
 *
 * @returns True if WASM module is initialized, false otherwise
 */
export { isInitialized };

/**
 * Get initialization error if module failed to load
 *
 * @returns The error that occurred during initialization, or null if no error
 * @internal
 */
export { getInitializationError };

/**
 * Get WASM module version
 *
 * @throws {Error} If WASM module is not initialized
 * @returns The version string of the WASM module
 */
export function getVersion(): string {
	if (!isInitialized()) {
		throw new Error("WASM module not initialized. Call initWasm() first.");
	}

	const wasmModule = getWasmModule();
	if (!wasmModule) {
		throw new Error("WASM module not loaded. Call initWasm() first.");
	}

	return wasmModule.version();
}

/**
 * Initialize the WASM module
 *
 * This function must be called once before using any extraction functions.
 * It loads and initializes the WASM module in the current runtime environment,
 * automatically selecting the appropriate WASM variant for the detected runtime.
 *
 * Multiple calls to initWasm() are safe and will return immediately if already initialized.
 *
 * @throws {Error} If WASM module fails to load or is not supported in the current environment
 *
 * @example Basic Usage
 * ```typescript
 * import { initWasm } from '@kreuzberg/wasm';
 *
 * async function main() {
 *   await initWasm();
 *   // Now you can use extraction functions
 * }
 *
 * main().catch(console.error);
 * ```
 *
 * @example With Error Handling
 * ```typescript
 * import { initWasm, getWasmCapabilities } from '@kreuzberg/wasm';
 *
 * async function initializeKreuzberg() {
 *   const caps = getWasmCapabilities();
 *   if (!caps.hasWasm) {
 *     throw new Error('WebAssembly is not supported in this environment');
 *   }
 *
 *   try {
 *     await initWasm();
 *     console.log('Kreuzberg initialized successfully');
 *   } catch (error) {
 *     console.error('Failed to initialize Kreuzberg:', error);
 *     throw error;
 *   }
 * }
 * ```
 */
export async function initWasm(): Promise<void> {
	if (isInitialized()) {
		return;
	}

	let currentPromise = getInitializationPromise();
	if (currentPromise) {
		return currentPromise;
	}

	currentPromise = (async () => {
		try {
			if (!hasWasm()) {
				throw new Error("WebAssembly is not supported in this environment");
			}

			let wasmModule: unknown;
			// Use const variables to make imports dynamic and bypass TypeScript's static module resolution.
			// This allows typecheck to pass when the WASM module hasn't been built yet (e.g., in CI).
			const pkgPath = "../pkg/kreuzberg_wasm.js";
			const fallbackPath = "./kreuzberg_wasm.js";
			try {
				wasmModule = await import(/* @vite-ignore */ pkgPath);
			} catch {
				wasmModule = await import(/* @vite-ignore */ fallbackPath);
			}
			const loadedModule = wasmModule as unknown as WasmModule;
			setWasmModule(loadedModule);

			if (loadedModule && typeof loadedModule.default === "function") {
				await loadedModule.default();
			}

			if (isBrowser() && loadedModule && typeof loadedModule.initialize_pdfium_render === "function") {
				initializePdfiumAsync(loadedModule).catch((error) => {
					console.warn("PDFium auto-initialization failed (PDF extraction disabled):", error);
				});
			}

			setInitialized(true);
			setInitializationError(null);
		} catch (error) {
			setInitializationError(error instanceof Error ? error : new Error(String(error)));
			throw wrapWasmError(error, "initializing Kreuzberg WASM module");
		}
	})();

	setInitializationPromise(currentPromise);
	return currentPromise;
}
