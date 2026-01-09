import { useMemo, useState } from "react";
import { WorkloadSelector } from "@/components/filters/WorkloadSelector";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useBenchmark } from "@/context/BenchmarkContext";
import type { AggregatedBenchmarkData } from "@/types/benchmark";
import {
	calculateOcrOverhead,
	getFastestColdStart,
	getFastestFramework,
	getMostMemoryEfficient,
	type InsightResult,
} from "@/utils/insights";

interface MetricsData {
	frameworkModeCount: number;
	ocrCoverage: { withOCR: number; noOCR: number };
}

function calculateMetrics(data: AggregatedBenchmarkData): MetricsData {
	const metrics: MetricsData = {
		frameworkModeCount: 0,
		ocrCoverage: { withOCR: 0, noOCR: 0 },
	};

	for (const [_, frameworkData] of Object.entries(data.by_framework_mode)) {
		metrics.frameworkModeCount++;

		// Process file type metrics
		for (const [_, fileTypeMetrics] of Object.entries(frameworkData.by_file_type)) {
			// Check OCR coverage
			if (fileTypeMetrics.with_ocr) {
				metrics.ocrCoverage.withOCR++;
			}
			if (fileTypeMetrics.no_ocr) {
				metrics.ocrCoverage.noOCR++;
			}
		}
	}

	return metrics;
}

interface ContextualInsightsProps {
	data: AggregatedBenchmarkData;
	selectedFileType?: string;
	selectedOcrMode?: "with_ocr" | "no_ocr";
}

function ContextualInsights({ data, selectedFileType, selectedOcrMode }: ContextualInsightsProps) {
	const insights = useMemo(() => {
		const results: InsightResult[] = [];

		// Always show cold start insight
		const coldStart = getFastestColdStart(data);
		if (coldStart) {
			results.push(coldStart);
		}

		// If workload is selected, show contextual insights
		if (selectedFileType && selectedOcrMode) {
			const fastest = getFastestFramework(data, selectedFileType, selectedOcrMode);
			if (fastest) {
				results.push(fastest);
			}

			const efficient = getMostMemoryEfficient(data, selectedFileType, selectedOcrMode);
			if (efficient) {
				results.push(efficient);
			}

			// Show OCR impact for each framework
			const frameworks = new Set<string>();
			for (const fw of Object.values(data.by_framework_mode)) {
				frameworks.add(fw.framework);
			}

			for (const framework of Array.from(frameworks).slice(0, 2)) {
				const ocrImpact = calculateOcrOverhead(data, framework, selectedFileType);
				if (ocrImpact) {
					results.push(ocrImpact);
				}
			}
		} else if (selectedFileType) {
			// Show insights for both OCR modes if only file type is selected
			const fastestWithOcr = getFastestFramework(data, selectedFileType, "with_ocr");
			const fastestNoOcr = getFastestFramework(data, selectedFileType, "no_ocr");

			if (fastestNoOcr) {
				results.push(fastestNoOcr);
			}
			if (fastestWithOcr) {
				results.push(fastestWithOcr);
			}
		}

		return results;
	}, [data, selectedFileType, selectedOcrMode]);

	if (insights.length === 0) {
		return (
			<Card className="bg-blue-50 border-blue-200 dark:bg-blue-950 dark:border-blue-800">
				<CardHeader>
					<CardTitle className="text-sm">Contextual Insights</CardTitle>
				</CardHeader>
				<CardContent>
					<p className="text-muted-foreground text-sm">
						Select a workload (file type + OCR mode) to view performance insights. Aggregated metrics across different
						workloads are not meaningful - context matters!
					</p>
				</CardContent>
			</Card>
		);
	}

	return (
		<Card>
			<CardHeader>
				<CardTitle className="text-sm">Contextual Insights</CardTitle>
				{selectedFileType && (
					<p className="text-xs text-muted-foreground mt-2">
						For {selectedFileType.toUpperCase()}
						{selectedOcrMode === "with_ocr" ? " with OCR" : " without OCR"}
					</p>
				)}
			</CardHeader>
			<CardContent>
				<div className="space-y-4">
					{insights.map((insight) => (
						<div key={insight.context} className="border-l-4 border-blue-500 pl-4 py-2">
							<p className="font-semibold text-sm">{insight.title}</p>
							<p className="text-sm text-gray-700 dark:text-gray-300">{insight.description}</p>
							{insight.value && <p className="text-xs text-muted-foreground mt-1">Value: {insight.value}</p>}
						</div>
					))}
				</div>
			</CardContent>
		</Card>
	);
}

function SummarySection({ data, metrics }: { data: AggregatedBenchmarkData; metrics: MetricsData }) {
	return (
		<Card>
			<CardHeader>
				<CardTitle className="text-sm">Benchmark Summary</CardTitle>
			</CardHeader>
			<CardContent>
				<div className="grid grid-cols-2 gap-4 text-sm">
					<div>
						<p className="text-muted-foreground text-xs">Timestamp</p>
						<p className="font-medium text-sm">{new Date(data.metadata.timestamp).toLocaleDateString()}</p>
						<p className="text-xs text-muted-foreground">{new Date(data.metadata.timestamp).toLocaleTimeString()}</p>
					</div>
					<div>
						<p className="text-muted-foreground text-xs">Framework Modes</p>
						<p className="font-medium text-sm">{metrics.frameworkModeCount} tested</p>
					</div>
					<div>
						<p className="text-muted-foreground text-xs">OCR Coverage</p>
						<p className="font-medium text-sm">
							{metrics.ocrCoverage.withOCR} with / {metrics.ocrCoverage.noOCR} without
						</p>
					</div>
					<div>
						<p className="text-muted-foreground text-xs">Total Results</p>
						<p className="font-medium text-sm">{data.metadata.total_results}</p>
					</div>
				</div>
			</CardContent>
		</Card>
	);
}

export function LandingPage() {
	const { data, loading, error } = useBenchmark();
	const [selectedFileType, setSelectedFileType] = useState<string>();
	const [selectedOcrMode, setSelectedOcrMode] = useState<"with_ocr" | "no_ocr" | undefined>();

	const metrics = useMemo(() => {
		return data ? calculateMetrics(data) : null;
	}, [data]);

	if (loading) {
		return (
			<div className="container mx-auto p-4">
				<Skeleton className="h-12 w-64 mb-6" data-testid="skeleton-landing" />
				<div className="grid gap-4 md:grid-cols-3">
					<Skeleton className="h-32" />
					<Skeleton className="h-32" />
					<Skeleton className="h-32" />
				</div>
			</div>
		);
	}

	if (error) {
		return (
			<div className="container mx-auto p-4">
				<Alert variant="destructive" data-testid="error-message">
					<AlertDescription>Error: {error.message}</AlertDescription>
				</Alert>
			</div>
		);
	}

	if (!data || !metrics) {
		return (
			<div className="container mx-auto p-4">
				<Alert data-testid="empty-state">
					<AlertDescription>No benchmark data available</AlertDescription>
				</Alert>
			</div>
		);
	}

	return (
		<div data-testid="page-landing" className="container mx-auto p-4">
			<div className="mb-8">
				<h1 className="text-4xl font-bold mb-2">Benchmark Results</h1>
				<p className="text-muted-foreground">Comprehensive performance analysis across frameworks and file types</p>
			</div>

			{/* Primary Metrics - 3 cards */}
			<div className="grid gap-4 md:grid-cols-3 mb-8">
				<Card data-testid="metric-card-frameworks">
					<CardHeader>
						<CardTitle>Frameworks</CardTitle>
					</CardHeader>
					<CardContent>
						<div className="text-3xl font-bold">{data.metadata.framework_count}</div>
					</CardContent>
				</Card>

				<Card data-testid="metric-card-file-types">
					<CardHeader>
						<CardTitle>File Types</CardTitle>
					</CardHeader>
					<CardContent>
						<div className="text-3xl font-bold">{data.metadata.file_type_count}</div>
					</CardContent>
				</Card>

				<Card data-testid="metric-card-total-results">
					<CardHeader>
						<CardTitle>Total Results</CardTitle>
					</CardHeader>
					<CardContent>
						<div className="text-3xl font-bold">{data.metadata.total_results}</div>
					</CardContent>
				</Card>
			</div>

			{/* Workload Selection Section */}
			<div className="grid gap-4 mb-8">
				<WorkloadSelector
					data-testid="workload-selector-landing"
					onFileTypeChange={setSelectedFileType}
					onOcrModeChange={(mode) => {
						setSelectedOcrMode(mode === "" ? undefined : (mode as "with_ocr" | "no_ocr"));
					}}
				/>
			</div>

			{/* Contextual Insights Section */}
			<div className="grid gap-4 mb-8">
				<ContextualInsights data={data} selectedFileType={selectedFileType} selectedOcrMode={selectedOcrMode} />
			</div>

			{/* Summary Section */}
			<div className="grid gap-4 lg:grid-cols-1 mb-8">
				<SummarySection data={data} metrics={metrics} />
			</div>
		</div>
	);
}
