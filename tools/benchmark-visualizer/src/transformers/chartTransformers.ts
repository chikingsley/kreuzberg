import type { AggregatedBenchmarkData, FileTypeMetrics, PerformanceMetrics } from "@/types/benchmark";

/**
 * Recharts-compatible data point interface
 * All values are strings or numbers for proper chart rendering
 */
export interface ChartDataPoint {
	[key: string]: string | number;
}

/**
 * Percentile-based chart data point
 * Contains p50, p95, p99 percentile values
 * name: Display label with line break (e.g., "Python\n(single)")
 * fullName: Full identifier for tooltips (e.g., "python_single_pdf_no_ocr")
 */
export interface PercentileChartDataPoint {
	name: string;
	fullName: string;
	p50: number;
	p95: number;
	p99: number;
}

/**
 * Filter options for transforming chart data
 */
export interface ChartTransformFilters {
	framework?: string;
	fileType?: string;
	ocrMode?: "no_ocr" | "with_ocr";
}

/**
 * Format framework name to display name
 * Maps framework identifiers to their full display names
 * Examples: 'python' -> 'Kreuzberg (Python)', 'rust' -> 'Kreuzberg (Rust)'
 */
export function formatFramework(framework: string): string {
	const frameworkMap: Record<string, string> = {
		python: "Kreuzberg (Python)",
		node: "Kreuzberg (Node.js)",
		rust: "Kreuzberg (Rust)",
		go: "Kreuzberg (Go)",
		ruby: "Kreuzberg (Ruby)",
		java: "Kreuzberg (Java)",
		csharp: "Kreuzberg (C#)",
		elixir: "Kreuzberg (Elixir)",
		php: "Kreuzberg (PHP)",
	};

	return frameworkMap[framework.toLowerCase()] || framework;
}

/**
 * Format mode to title case
 * Examples: 'single' -> 'single', 'batch' -> 'batch'
 */
function formatMode(mode: string): string {
	return mode.toLowerCase();
}

/**
 * Generate readable display label from framework and mode
 * Examples:
 * - 'python' + 'single' -> 'Python\n(single)'
 * - 'rust' + 'batch' -> 'Rust\n(batch)'
 */
export function generateDisplayLabel(framework: string, mode: string): string {
	return `${formatFramework(framework)}\n(${formatMode(mode)})`;
}

/**
 * Extract framework and mode from full identifier key
 * Examples:
 * - 'python_single_pdf_no_ocr' -> { framework: 'python', mode: 'single', ... }
 */
export function parseFrameworkModeKey(key: string): {
	framework: string;
	mode: string;
} {
	const parts = key.split("_");
	if (parts.length >= 2) {
		const framework = parts[0];
		const mode = parts[1];
		return { framework, mode };
	}
	return { framework: key, mode: "unknown" };
}

/**
 * Transform benchmark data for throughput comparison charts
 * Groups data by framework/mode and file type, using p50 as the primary metric
 *
 * @param data - Aggregated benchmark data
 * @param fileTypes - Optional array of file types to include (e.g., ['no_ocr', 'with_ocr'])
 * @returns Array of objects compatible with Recharts, with string keys and number values
 */
export function transformThroughputData(data: AggregatedBenchmarkData, fileTypes?: string[]): ChartDataPoint[] {
	const chartData: ChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		const dataPoint: ChartDataPoint = {
			name: frameworkModeKey,
		};

		const typesToProcess = fileTypes || Object.keys(frameworkData.by_file_type);

		typesToProcess.forEach((fileType) => {
			const fileTypeMetrics = frameworkData.by_file_type[fileType];
			if (!fileTypeMetrics) return;

			const throughput = extractThroughputMetric(fileTypeMetrics);
			if (throughput !== null) {
				dataPoint[fileType] = Math.round(throughput * 100) / 100; // Round to 2 decimals
			}
		});

		// Only add data point if it has metrics beyond the name
		if (Object.keys(dataPoint).length > 1) {
			chartData.push(dataPoint);
		}
	});

	return chartData;
}

/**
 * Transform benchmark data for memory usage charts
 * Groups data by framework/mode and file type, using p50 as the primary metric
 *
 * @param data - Aggregated benchmark data
 * @param fileTypes - Optional array of file types to include (e.g., ['no_ocr', 'with_ocr'])
 * @returns Array of objects compatible with Recharts, with string keys and number values
 */
export function transformMemoryData(data: AggregatedBenchmarkData, fileTypes?: string[]): ChartDataPoint[] {
	const chartData: ChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		const dataPoint: ChartDataPoint = {
			name: frameworkModeKey,
		};

		const typesToProcess = fileTypes || Object.keys(frameworkData.by_file_type);

		typesToProcess.forEach((fileType) => {
			const fileTypeMetrics = frameworkData.by_file_type[fileType];
			if (!fileTypeMetrics) return;

			const memory = extractMemoryMetric(fileTypeMetrics);
			if (memory !== null) {
				dataPoint[fileType] = Math.round(memory * 100) / 100; // Round to 2 decimals
			}
		});

		// Only add data point if it has metrics beyond the name
		if (Object.keys(dataPoint).length > 1) {
			chartData.push(dataPoint);
		}
	});

	return chartData;
}

/**
 * Transform benchmark data for duration charts
 * Groups data by framework/mode and file type, using p50 as the primary metric
 *
 * @param data - Aggregated benchmark data
 * @param fileTypes - Optional array of file types to include (e.g., ['no_ocr', 'with_ocr'])
 * @returns Array of objects compatible with Recharts, with string keys and number values
 */
export function transformDurationData(data: AggregatedBenchmarkData, fileTypes?: string[]): ChartDataPoint[] {
	const chartData: ChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		const dataPoint: ChartDataPoint = {
			name: frameworkModeKey,
		};

		const typesToProcess = fileTypes || Object.keys(frameworkData.by_file_type);

		typesToProcess.forEach((fileType) => {
			const fileTypeMetrics = frameworkData.by_file_type[fileType];
			if (!fileTypeMetrics) return;

			const duration = extractDurationMetric(fileTypeMetrics);
			if (duration !== null) {
				dataPoint[fileType] = Math.round(duration * 100) / 100; // Round to 2 decimals
			}
		});

		// Only add data point if it has metrics beyond the name
		if (Object.keys(dataPoint).length > 1) {
			chartData.push(dataPoint);
		}
	});

	return chartData;
}

/**
 * Transform benchmark data for cold start comparison charts
 * Filters for frameworks/modes that have cold start data
 *
 * @param data - Aggregated benchmark data
 * @returns Array of objects compatible with Recharts with cold start metrics
 */
export function transformColdStartData(data: AggregatedBenchmarkData): ChartDataPoint[] {
	const chartData: ChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		if (!frameworkData.cold_start) return;

		const coldStart = frameworkData.cold_start;
		const dataPoint: ChartDataPoint = {
			name: frameworkModeKey,
			p50: coldStart.p50_ms !== null ? Math.round(coldStart.p50_ms * 100) / 100 : 0,
			p95: coldStart.p95_ms !== null ? Math.round(coldStart.p95_ms * 100) / 100 : 0,
			p99: coldStart.p99_ms !== null ? Math.round(coldStart.p99_ms * 100) / 100 : 0,
		};

		chartData.push(dataPoint);
	});

	return chartData;
}

/**
 * Extract throughput metric from file type metrics
 * Uses p50 as the primary metric, falls back gracefully on null values
 *
 * @param fileTypeMetrics - Metrics for a specific file type
 * @returns Throughput value in MB/s or null if not available
 */
function extractThroughputMetric(fileTypeMetrics: FileTypeMetrics): number | null {
	const metrics = getValidMetrics(fileTypeMetrics);
	if (!metrics) return null;

	return metrics.throughput.p50 ?? null;
}

/**
 * Extract memory metric from file type metrics
 * Uses p50 as the primary metric, falls back gracefully on null values
 *
 * @param fileTypeMetrics - Metrics for a specific file type
 * @returns Memory value in MB or null if not available
 */
function extractMemoryMetric(fileTypeMetrics: FileTypeMetrics): number | null {
	const metrics = getValidMetrics(fileTypeMetrics);
	if (!metrics) return null;

	return metrics.memory.p50 ?? null;
}

/**
 * Extract duration metric from file type metrics
 * Uses p50 as the primary metric, falls back gracefully on null values
 *
 * @param fileTypeMetrics - Metrics for a specific file type
 * @returns Duration value in milliseconds or null if not available
 */
function extractDurationMetric(fileTypeMetrics: FileTypeMetrics): number | null {
	const metrics = getValidMetrics(fileTypeMetrics);
	if (!metrics) return null;

	return metrics.duration.p50 ?? null;
}

/**
 * Get valid metrics from file type metrics, trying both no_ocr and with_ocr
 * Prioritizes no_ocr if both are available
 *
 * @param fileTypeMetrics - Metrics for a specific file type
 * @returns Valid PerformanceMetrics or null if neither variant has data
 */
function getValidMetrics(fileTypeMetrics: FileTypeMetrics): PerformanceMetrics | null {
	if (fileTypeMetrics.no_ocr) return fileTypeMetrics.no_ocr;
	if (fileTypeMetrics.with_ocr) return fileTypeMetrics.with_ocr;
	return null;
}

/**
 * Transform benchmark data for throughput charts with all percentiles (p50, p95, p99)
 * Groups data by framework/mode and file type
 * Generates readable display labels for chart axes while preserving full identifiers for tooltips
 *
 * @param data - Aggregated benchmark data
 * @param filters - Optional filters to narrow down results by framework, fileType, or ocrMode
 * @returns Array of objects with readable name for display and fullName for tooltips
 *
 * @example
 * const chartData = transformForThroughputChart(data, { framework: 'rust', fileType: 'pdf' })
 * // Returns: [{ name: 'Rust\n(single)', fullName: 'rust_single_pdf_no_ocr', p50: 100, ... }]
 */
export function transformForThroughputChart(
	data: AggregatedBenchmarkData,
	filters?: ChartTransformFilters,
): PercentileChartDataPoint[] {
	return transformPercentileData(data, "throughput", filters);
}

/**
 * Transform benchmark data for memory charts with all percentiles (p50, p95, p99)
 * Groups data by framework/mode and file type
 *
 * @param data - Aggregated benchmark data
 * @param filters - Optional filters to narrow down results by framework, fileType, or ocrMode
 * @returns Array of objects with name, p50, p95, p99 values suitable for Recharts
 *
 * @example
 * const chartData = transformForMemoryChart(data, { framework: 'python', ocrMode: 'with_ocr' })
 */
export function transformForMemoryChart(
	data: AggregatedBenchmarkData,
	filters?: ChartTransformFilters,
): PercentileChartDataPoint[] {
	return transformPercentileData(data, "memory", filters);
}

/**
 * Transform benchmark data for duration charts with all percentiles (p50, p95, p99)
 * Groups data by framework/mode and file type
 *
 * @param data - Aggregated benchmark data
 * @param filters - Optional filters to narrow down results by framework, fileType, or ocrMode
 * @returns Array of objects with name, p50, p95, p99 values suitable for Recharts
 *
 * @example
 * const chartData = transformForDurationChart(data, { fileType: 'image' })
 */
export function transformForDurationChart(
	data: AggregatedBenchmarkData,
	filters?: ChartTransformFilters,
): PercentileChartDataPoint[] {
	return transformPercentileData(data, "duration", filters);
}

/**
 * Transform benchmark data for cold start charts with all percentiles (p50, p95, p99)
 * Filters for frameworks/modes that have cold start data
 * Generates readable display labels for chart axes while preserving full identifiers
 *
 * @param data - Aggregated benchmark data
 * @param filters - Optional filters to narrow down results by framework
 * @returns Array of objects with readable name and fullName for cold start metrics
 *
 * @example
 * const chartData = transformForColdStartChart(data, { framework: 'rust' })
 * // Returns: [{ name: 'Rust\n(single)', fullName: 'rust_single', p50: 100, ... }]
 */
export function transformForColdStartChart(
	data: AggregatedBenchmarkData,
	filters?: ChartTransformFilters,
): PercentileChartDataPoint[] {
	const chartData: PercentileChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		// Apply framework filter if provided
		if (filters?.framework && frameworkData.framework !== filters.framework) {
			return;
		}

		// Cold start data doesn't have file type or OCR mode distinction
		if (!frameworkData.cold_start) return;

		const coldStart = frameworkData.cold_start;

		// Generate readable display label for axis
		const displayLabel = generateDisplayLabel(frameworkData.framework, frameworkData.mode);

		const dataPoint: PercentileChartDataPoint = {
			name: displayLabel,
			fullName: frameworkModeKey,
			p50: roundValue(coldStart.p50_ms),
			p95: roundValue(coldStart.p95_ms),
			p99: roundValue(coldStart.p99_ms),
		};

		chartData.push(dataPoint);
	});

	return chartData;
}

/**
 * Generic percentile data transformer
 * Handles transformation of any metric type with percentile values
 * Generates readable display labels while preserving full identifiers
 *
 * @param data - Aggregated benchmark data
 * @param metricType - The metric to extract: 'throughput', 'memory', or 'duration'
 * @param filters - Optional filters for framework, fileType, or ocrMode
 * @returns Array of percentile chart data points with readable names and full identifiers
 */
function transformPercentileData(
	data: AggregatedBenchmarkData,
	metricType: "throughput" | "memory" | "duration",
	filters?: ChartTransformFilters,
): PercentileChartDataPoint[] {
	const chartData: PercentileChartDataPoint[] = [];

	Object.entries(data.by_framework_mode).forEach(([frameworkModeKey, frameworkData]) => {
		// Apply framework filter if provided
		if (filters?.framework && frameworkData.framework !== filters.framework) {
			return;
		}

		// Get file types to process
		const fileTypeKeys = filters?.fileType ? [filters.fileType] : Object.keys(frameworkData.by_file_type);

		fileTypeKeys.forEach((fileType) => {
			const fileTypeMetrics = frameworkData.by_file_type[fileType];
			if (!fileTypeMetrics) return;

			// Get the appropriate metrics based on OCR mode filter
			let metrics: PerformanceMetrics | null = null;

			if (filters?.ocrMode === "no_ocr") {
				metrics = fileTypeMetrics.no_ocr;
			} else if (filters?.ocrMode === "with_ocr") {
				metrics = fileTypeMetrics.with_ocr;
			} else {
				// If no OCR mode specified, prioritize no_ocr
				metrics = fileTypeMetrics.no_ocr || fileTypeMetrics.with_ocr;
			}

			if (!metrics) return;

			// Extract the appropriate metric type
			const metricValues = metrics[metricType];
			if (!metricValues) return;

			// Generate full identifier for tooltip
			const fullName = `${frameworkModeKey}_${fileType}${filters?.ocrMode ? `_${filters.ocrMode}` : ""}`;

			// Generate readable display label for axis
			const displayLabel = generateDisplayLabel(frameworkData.framework, frameworkData.mode);

			const dataPoint: PercentileChartDataPoint = {
				name: displayLabel,
				fullName: fullName,
				p50: roundValue(metricValues.p50),
				p95: roundValue(metricValues.p95),
				p99: roundValue(metricValues.p99),
			};

			chartData.push(dataPoint);
		});
	});

	return chartData;
}

/**
 * Round a numeric value to 2 decimal places
 * Handles null/undefined values by returning 0
 *
 * @param value - The value to round
 * @returns Rounded value or 0 if value is null/undefined
 */
function roundValue(value: number | null | undefined): number {
	if (value === null || value === undefined) return 0;
	return Math.round(value * 100) / 100;
}
