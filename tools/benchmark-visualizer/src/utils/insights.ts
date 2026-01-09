import { formatFramework } from "@/transformers/chartTransformers";
import type { AggregatedBenchmarkData, FrameworkModeData } from "@/types/benchmark";

export interface FrameworkPerformance {
	frameworkMode: string;
	framework: string;
	mode: string;
	throughput: number;
	memory: number;
	duration: number;
}

export interface InsightResult {
	title: string;
	description: string;
	context: string; // What workload this is for
	value?: string | number;
}

/**
 * Find the fastest framework for a specific workload (file type + OCR mode)
 * Returns the framework-mode combination with highest throughput
 */
export function getFastestFramework(
	data: AggregatedBenchmarkData,
	fileType: string,
	ocrMode: "with_ocr" | "no_ocr",
): InsightResult | null {
	let fastest: FrameworkPerformance | null = null;

	for (const [frameworkModeKey, frameworkData] of Object.entries(data.by_framework_mode)) {
		const fileTypeMetrics = frameworkData.by_file_type[fileType];
		if (!fileTypeMetrics) continue;

		const metrics = ocrMode === "with_ocr" ? fileTypeMetrics.with_ocr : fileTypeMetrics.no_ocr;
		if (!metrics) continue;

		const current: FrameworkPerformance = {
			frameworkMode: frameworkModeKey,
			framework: frameworkData.framework,
			mode: frameworkData.mode,
			throughput: metrics.throughput.p50,
			memory: metrics.memory.p50,
			duration: metrics.duration.p50,
		};

		if (!fastest || current.throughput > fastest.throughput) {
			fastest = current;
		}
	}

	if (!fastest) return null;

	const ocrText = ocrMode === "with_ocr" ? "with OCR" : "without OCR";
	const formattedFramework = formatFramework(fastest.framework);
	return {
		title: `Fastest for ${fileType.toUpperCase()} ${ocrText}`,
		description: `${formattedFramework} (${fastest.mode}) achieves ${fastest.throughput.toFixed(1)} MB/s (p50)`,
		context: `${fileType} ${ocrText}`,
		value: `${fastest.throughput.toFixed(1)} MB/s`,
	};
}

/**
 * Find the most memory-efficient framework for a specific workload
 * Returns the framework-mode combination with lowest memory usage
 */
export function getMostMemoryEfficient(
	data: AggregatedBenchmarkData,
	fileType: string,
	ocrMode: "with_ocr" | "no_ocr",
): InsightResult | null {
	let mostEfficient: FrameworkPerformance | null = null;

	for (const [frameworkModeKey, frameworkData] of Object.entries(data.by_framework_mode)) {
		const fileTypeMetrics = frameworkData.by_file_type[fileType];
		if (!fileTypeMetrics) continue;

		const metrics = ocrMode === "with_ocr" ? fileTypeMetrics.with_ocr : fileTypeMetrics.no_ocr;
		if (!metrics) continue;

		const current: FrameworkPerformance = {
			frameworkMode: frameworkModeKey,
			framework: frameworkData.framework,
			mode: frameworkData.mode,
			throughput: metrics.throughput.p50,
			memory: metrics.memory.p50,
			duration: metrics.duration.p50,
		};

		if (!mostEfficient || current.memory < mostEfficient.memory) {
			mostEfficient = current;
		}
	}

	if (!mostEfficient) return null;

	const ocrText = ocrMode === "with_ocr" ? "with OCR" : "without OCR";
	const formattedFramework = formatFramework(mostEfficient.framework);
	return {
		title: `Most Memory Efficient for ${fileType.toUpperCase()} ${ocrText}`,
		description: `${formattedFramework} (${mostEfficient.mode}) uses only ${mostEfficient.memory.toFixed(1)} MB (p50)`,
		context: `${fileType} ${ocrText}`,
		value: `${mostEfficient.memory.toFixed(1)} MB`,
	};
}

/**
 * Calculate the percentage overhead of OCR on throughput for a specific framework
 * Shows how much OCR reduces throughput compared to no OCR baseline
 */
export function calculateOcrOverhead(
	data: AggregatedBenchmarkData,
	framework: string,
	fileType: string,
): InsightResult | null {
	// Find the framework mode data
	let targetFrameworkData: FrameworkModeData | null = null;

	for (const [, frameworkData] of Object.entries(data.by_framework_mode)) {
		if (frameworkData.framework === framework) {
			targetFrameworkData = frameworkData;
			break;
		}
	}

	if (!targetFrameworkData) return null;

	const fileTypeMetrics = targetFrameworkData.by_file_type[fileType];
	if (!fileTypeMetrics || !fileTypeMetrics.no_ocr || !fileTypeMetrics.with_ocr) {
		return null;
	}

	const noOcrThroughput = fileTypeMetrics.no_ocr.throughput.p50;
	const withOcrThroughput = fileTypeMetrics.with_ocr.throughput.p50;
	const overhead = ((noOcrThroughput - withOcrThroughput) / noOcrThroughput) * 100;
	const formattedFramework = formatFramework(framework);

	return {
		title: `OCR Impact on ${formattedFramework}`,
		description: `OCR reduces ${formattedFramework} throughput by ${overhead.toFixed(0)}% (${noOcrThroughput.toFixed(1)} → ${withOcrThroughput.toFixed(1)} MB/s) for ${fileType}`,
		context: `${fileType}`,
		value: `${overhead.toFixed(0)}% overhead`,
	};
}

/**
 * Calculate efficiency score: throughput / memory ratio for a workload
 * Higher score means better throughput per MB of memory used
 * Useful for finding balanced performance
 */
export function getEfficiencyScore(
	data: AggregatedBenchmarkData,
	framework: string,
	fileType: string,
	ocrMode: "with_ocr" | "no_ocr",
): InsightResult | null {
	let targetFrameworkData: FrameworkModeData | null = null;
	let targetMode: string | null = null;

	for (const [, frameworkData] of Object.entries(data.by_framework_mode)) {
		if (frameworkData.framework === framework) {
			targetFrameworkData = frameworkData;
			targetMode = frameworkData.mode;
			break;
		}
	}

	if (!targetFrameworkData) return null;

	const fileTypeMetrics = targetFrameworkData.by_file_type[fileType];
	if (!fileTypeMetrics) return null;

	const metrics = ocrMode === "with_ocr" ? fileTypeMetrics.with_ocr : fileTypeMetrics.no_ocr;
	if (!metrics) return null;

	const score = metrics.throughput.p50 / metrics.memory.p50;

	const ocrText = ocrMode === "with_ocr" ? "with OCR" : "without OCR";
	const formattedFramework = formatFramework(framework);
	return {
		title: `Efficiency Score: ${formattedFramework}`,
		description: `${formattedFramework} (${targetMode}) achieves ${score.toFixed(2)} MB/s per MB for ${fileType} ${ocrText}`,
		context: `${fileType} ${ocrText}`,
		value: score.toFixed(2),
	};
}

/**
 * Find the framework with fastest cold start time
 */
export function getFastestColdStart(data: AggregatedBenchmarkData): InsightResult | null {
	let fastest: {
		framework: string;
		mode: string;
		time: number;
	} | null = null;

	for (const [, frameworkData] of Object.entries(data.by_framework_mode)) {
		if (!frameworkData.cold_start) continue;

		if (!fastest || frameworkData.cold_start.p50_ms < fastest.time) {
			fastest = {
				framework: frameworkData.framework,
				mode: frameworkData.mode,
				time: frameworkData.cold_start.p50_ms,
			};
		}
	}

	if (!fastest) return null;

	const formattedFramework = formatFramework(fastest.framework);
	return {
		title: "Fastest Cold Start",
		description: `${formattedFramework} (${fastest.mode}) has fastest cold start at ${fastest.time.toFixed(0)}ms (p50)`,
		context: "Cold start performance",
		value: `${fastest.time.toFixed(0)}ms`,
	};
}

/**
 * Get all available workloads from the data
 * Returns array of {fileType, ocrMode} combinations that have data
 */
export function getAvailableWorkloads(
	data: AggregatedBenchmarkData,
): Array<{ fileType: string; ocrMode: "with_ocr" | "no_ocr" }> {
	const workloads = new Set<string>();

	for (const frameworkData of Object.values(data.by_framework_mode)) {
		for (const [fileType, fileTypeMetrics] of Object.entries(frameworkData.by_file_type)) {
			if (fileTypeMetrics.no_ocr) {
				workloads.add(`${fileType}:no_ocr`);
			}
			if (fileTypeMetrics.with_ocr) {
				workloads.add(`${fileType}:with_ocr`);
			}
		}
	}

	return Array.from(workloads).map((w) => {
		const [fileType, ocrMode] = w.split(":");
		return {
			fileType,
			ocrMode: ocrMode as "with_ocr" | "no_ocr",
		};
	});
}

/**
 * Get top N performers for a workload by throughput
 */
export function getTopPerformers(
	data: AggregatedBenchmarkData,
	fileType: string,
	ocrMode: "with_ocr" | "no_ocr",
	limit: number = 3,
): FrameworkPerformance[] {
	const performers: FrameworkPerformance[] = [];

	for (const [frameworkModeKey, frameworkData] of Object.entries(data.by_framework_mode)) {
		const fileTypeMetrics = frameworkData.by_file_type[fileType];
		if (!fileTypeMetrics) continue;

		const metrics = ocrMode === "with_ocr" ? fileTypeMetrics.with_ocr : fileTypeMetrics.no_ocr;
		if (!metrics) continue;

		performers.push({
			frameworkMode: frameworkModeKey,
			framework: frameworkData.framework,
			mode: frameworkData.mode,
			throughput: metrics.throughput.p50,
			memory: metrics.memory.p50,
			duration: metrics.duration.p50,
		});
	}

	return performers.sort((a, b) => b.throughput - a.throughput).slice(0, limit);
}
