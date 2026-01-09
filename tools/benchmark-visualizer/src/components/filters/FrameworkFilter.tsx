import { useCallback, useEffect, useMemo, useState } from "react";
import { Select } from "@/components/ui/select";
import { useBenchmark } from "@/context/BenchmarkContext";

export interface FrameworkFilterProps {
	selectedFrameworks: string[];
	onFrameworksChange: (frameworks: string[]) => void;
	"data-testid"?: string;
}

/**
 * FrameworkFilter component for filtering benchmark data by framework.
 * Supports multi-select functionality with an "All Frameworks" option.
 * Automatically extracts unique framework names from benchmark data
 * and sorts them alphabetically.
 */
export function FrameworkFilter({
	selectedFrameworks,
	onFrameworksChange,
	"data-testid": testId = "filter-framework",
}: FrameworkFilterProps) {
	const { data, loading, error } = useBenchmark();
	const [isDisabled, setIsDisabled] = useState(false);

	const frameworks = useMemo((): string[] => {
		if (!data?.by_framework_mode) {
			return [];
		}
		return Array.from(new Set(Object.values(data.by_framework_mode).map((item) => item.framework))).sort();
	}, [data]);

	// Update disabled state based on loading/error
	useEffect(() => {
		setIsDisabled(loading || !!error || frameworks.length === 0);
	}, [loading, error, frameworks.length]);

	/**
	 * Handle selection changes for multi-select.
	 * When "All Frameworks" is selected, clears all individual selections.
	 * When individual frameworks are selected/deselected, updates the selection list.
	 */
	const handleChange = useCallback(
		(e: React.ChangeEvent<HTMLSelectElement>) => {
			const selectedOptions = Array.from(e.target.selectedOptions);
			const selectedValues = selectedOptions.map((option) => option.value);

			// Handle "All Frameworks" selection
			if (selectedValues.includes("")) {
				if (selectedValues.length === 1) {
					// Only "All Frameworks" is selected
					onFrameworksChange([]);
				} else {
					// User selected both "All Frameworks" and specific frameworks
					// Remove the "All Frameworks" option and keep only specific frameworks
					onFrameworksChange(selectedValues.filter((v) => v !== ""));
				}
			} else {
				onFrameworksChange(selectedValues);
			}
		},
		[onFrameworksChange],
	);

	/**
	 * Determine which options should be marked as selected.
	 * When no frameworks are selected, "All Frameworks" is conceptually active.
	 */
	const selectedValues = selectedFrameworks.length === 0 ? [""] : selectedFrameworks;

	// Show loading state
	if (loading) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="framework-filter" className="text-sm font-medium text-muted-foreground">
					Framework
				</label>
				<div className="h-9 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground">
					Loading frameworks...
				</div>
			</div>
		);
	}

	// Show error state
	if (error) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="framework-filter" className="text-sm font-medium">
					Framework
				</label>
				<div className="h-9 rounded-md border border-destructive bg-background px-3 py-2 text-sm text-destructive flex items-center">
					Error loading frameworks
				</div>
			</div>
		);
	}

	// Show empty state
	if (frameworks.length === 0) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="framework-filter" className="text-sm font-medium">
					Framework
				</label>
				<div className="h-9 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground">
					No frameworks available
				</div>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-2">
			<label htmlFor="framework-filter" className="text-sm font-medium">
				Framework
			</label>
			<Select
				id="framework-filter"
				data-testid={testId}
				value={selectedValues}
				onChange={handleChange}
				multiple
				disabled={isDisabled}
				className="min-h-[9rem]"
			>
				<option value="">All Frameworks</option>
				{frameworks.map((framework) => (
					<option key={framework} value={framework}>
						{framework}
					</option>
				))}
			</Select>
			{frameworks.length > 0 && (
				<p className="text-xs text-muted-foreground">
					{selectedFrameworks.length === 0
						? "All frameworks selected"
						: `${selectedFrameworks.length} framework${selectedFrameworks.length === 1 ? "" : "s"} selected`}
				</p>
			)}
		</div>
	);
}
