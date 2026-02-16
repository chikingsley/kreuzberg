#!/usr/bin/env node
/**
 * PDF.js extraction wrapper for benchmark harness.
 *
 * Supports three modes:
 * - sync: extract text page-by-page (sequential)
 * - batch: process multiple files (simulated batch using loop)
 * - server: persistent mode reading paths from stdin
 */

import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import * as pdfjsLib from "pdfjs-dist/legacy/build/pdf.mjs";

const DEFAULT_TIMEOUT_MS = 150000;

async function extractSync(filePath) {
	const start = performance.now();
	const absolutePath = path.resolve(filePath);
	const fileData = new Uint8Array(fs.readFileSync(absolutePath));
	const task = pdfjsLib.getDocument({
		data: fileData,
		disableWorker: true,
		verbosity: 0,
	});

	const doc = await task.promise;
	const textParts = [];

	try {
		for (let pageNum = 1; pageNum <= doc.numPages; pageNum += 1) {
			const page = await doc.getPage(pageNum);
			const textContent = await page.getTextContent();
			const pageText = textContent.items
				.map((item) => item.str || "")
				.join(" ")
				.replace(/\s+/g, " ")
				.trim();
			if (pageText.length > 0) {
				textParts.push(pageText);
			}
		}
	} finally {
		await doc.destroy();
	}

	const durationMs = performance.now() - start;
	return {
		content: textParts.join("\n\n"),
		metadata: { framework: "pdfjs" },
		_extraction_time_ms: durationMs,
	};
}

async function extractBatch(filePaths) {
	const start = performance.now();
	const results = [];

	for (const filePath of filePaths) {
		try {
			results.push(await extractSync(filePath));
		} catch (error) {
			results.push({
				content: "",
				metadata: {
					framework: "pdfjs",
					error: String(error?.message ?? error),
				},
			});
		}
	}

	const totalDurationMs = performance.now() - start;
	const perFileDurationMs = filePaths.length > 0 ? totalDurationMs / filePaths.length : 0;

	for (const result of results) {
		result._extraction_time_ms = perFileDurationMs;
		result._batch_total_ms = totalDurationMs;
	}

	return results;
}

function withTimeout(promise, timeoutMs) {
	return Promise.race([
		promise,
		new Promise((_, reject) => {
			setTimeout(() => reject(new Error(`extraction timed out after ${timeoutMs}ms`)), timeoutMs);
		}),
	]);
}

async function runServer(timeoutMs) {
	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
		terminal: false,
	});

	console.log("READY");

	for await (const line of rl) {
		const filePath = line.trim();
		if (!filePath) {
			continue;
		}

		try {
			const payload = await withTimeout(extractSync(filePath), timeoutMs);
			console.log(JSON.stringify(payload));
		} catch (error) {
			console.log(JSON.stringify({ error: String(error?.message ?? error), _extraction_time_ms: timeoutMs }));
		}
	}
}

async function main() {
	let timeoutMs = DEFAULT_TIMEOUT_MS;
	const args = [];

	for (const arg of process.argv.slice(2)) {
		if (arg === "--ocr" || arg === "--no-ocr") {
			// Accepted but ignored - PDF.js doesn't provide built-in OCR.
			continue;
		}
		if (arg.startsWith("--timeout=")) {
			const timeoutSecs = Number.parseInt(arg.split("=", 2)[1], 10);
			if (!Number.isNaN(timeoutSecs) && timeoutSecs > 0) {
				timeoutMs = timeoutSecs * 1000;
			}
			continue;
		}
		args.push(arg);
	}

	if (args.length < 1) {
		console.error("Usage: pdfjs_extract.mjs [--ocr|--no-ocr] [--timeout=SECS] <mode> <file_path> [additional_files...]");
		console.error("Modes: sync, batch, server");
		process.exit(1);
	}

	const mode = args[0];
	const filePaths = args.slice(1);

	try {
		if (mode === "server") {
			await runServer(timeoutMs);
			return;
		}

		if (mode === "sync") {
			if (filePaths.length !== 1) {
				console.error("Error: sync mode requires exactly one file");
				process.exit(1);
			}
			const payload = await withTimeout(extractSync(filePaths[0]), timeoutMs);
			process.stdout.write(JSON.stringify(payload));
			return;
		}

		if (mode === "batch") {
			if (filePaths.length < 1) {
				console.error("Error: batch mode requires at least one file");
				process.exit(1);
			}
			const results = await withTimeout(extractBatch(filePaths), timeoutMs);
			if (filePaths.length === 1) {
				process.stdout.write(JSON.stringify(results[0]));
			} else {
				process.stdout.write(JSON.stringify(results));
			}
			return;
		}

		console.error(`Error: Unknown mode '${mode}'. Use sync, batch, or server`);
		process.exit(1);
	} catch (error) {
		console.error(`Error extracting with pdfjs: ${String(error?.message ?? error)}`);
		process.exit(1);
	}
}

main();
