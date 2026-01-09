import { useCallback, useEffect, useMemo, useState } from "react";
import { Select } from "@/components/ui/select";
import { useBenchmark } from "@/context/BenchmarkContext";

export interface FileTypeFilterProps {
	selectedFileTypes: string[];
	onFileTypesChange: (fileTypes: string[]) => void;
	"data-testid"?: string;
}

/**
 * FileTypeFilter component for filtering benchmark data by file type.
 * Supports multi-select functionality with an "All File Types" option.
 * Automatically extracts unique file types from benchmark data
 * and sorts them alphabetically.
 */
export function FileTypeFilter({
	selectedFileTypes,
	onFileTypesChange,
	"data-testid": testId = "filter-file-type",
}: FileTypeFilterProps) {
	const { data, loading, error } = useBenchmark();
	const [isDisabled, setIsDisabled] = useState(false);

	const fileTypes = useMemo((): string[] => {
		if (!data?.by_framework_mode) {
			return [];
		}
		const types = new Set<string>();
		Object.values(data.by_framework_mode).forEach((frameworkData) => {
			Object.keys(frameworkData.by_file_type).forEach((fileType) => {
				types.add(fileType);
			});
		});
		return Array.from(types).sort();
	}, [data]);

	// Update disabled state based on loading/error
	useEffect(() => {
		setIsDisabled(loading || !!error || fileTypes.length === 0);
	}, [loading, error, fileTypes.length]);

	/**
	 * Handle selection changes for multi-select.
	 * When "All File Types" is selected, clears all individual selections.
	 * When individual file types are selected/deselected, updates the selection list.
	 */
	const handleChange = useCallback(
		(e: React.ChangeEvent<HTMLSelectElement>) => {
			const selectedOptions = Array.from(e.target.selectedOptions);
			const selectedValues = selectedOptions.map((option) => option.value);

			// Handle "All File Types" selection
			if (selectedValues.includes("")) {
				if (selectedValues.length === 1) {
					// Only "All File Types" is selected
					onFileTypesChange([]);
				} else {
					// User selected both "All File Types" and specific file types
					// Remove the "All File Types" option and keep only specific file types
					onFileTypesChange(selectedValues.filter((v) => v !== ""));
				}
			} else {
				onFileTypesChange(selectedValues);
			}
		},
		[onFileTypesChange],
	);

	/**
	 * Determine which options should be marked as selected.
	 * When no file types are selected, "All File Types" is conceptually active.
	 */
	const selectedValues = selectedFileTypes.length === 0 ? [""] : selectedFileTypes;

	// Show loading state
	if (loading) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="file-type-filter" className="text-sm font-medium text-muted-foreground">
					File Type
				</label>
				<div className="h-9 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground">
					Loading file types...
				</div>
			</div>
		);
	}

	// Show error state
	if (error) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="file-type-filter" className="text-sm font-medium">
					File Type
				</label>
				<div className="h-9 rounded-md border border-destructive bg-background px-3 py-2 text-sm text-destructive flex items-center">
					Error loading file types
				</div>
			</div>
		);
	}

	// Show empty state
	if (fileTypes.length === 0) {
		return (
			<div className="flex flex-col gap-2">
				<label htmlFor="file-type-filter" className="text-sm font-medium">
					File Type
				</label>
				<div className="h-9 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground">
					No file types available
				</div>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-2">
			<label htmlFor="file-type-filter" className="text-sm font-medium">
				File Type
			</label>
			<Select
				id="file-type-filter"
				data-testid={testId}
				value={selectedValues}
				onChange={handleChange}
				multiple
				disabled={isDisabled}
				className="min-h-[9rem]"
			>
				<option value="">All File Types</option>
				{fileTypes.map((fileType) => (
					<option key={fileType} value={fileType}>
						{fileType}
					</option>
				))}
			</Select>
			{fileTypes.length > 0 && (
				<p className="text-xs text-muted-foreground">
					{selectedFileTypes.length === 0
						? "All file types selected"
						: `${selectedFileTypes.length} file type${selectedFileTypes.length === 1 ? "" : "s"} selected`}
				</p>
			)}
		</div>
	);
}
