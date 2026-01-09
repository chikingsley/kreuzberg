import { useCallback } from "react";

export interface OCRModeFilterProps {
	selectedOCRMode: "" | "no_ocr" | "with_ocr";
	onOCRModeChange: (mode: "" | "no_ocr" | "with_ocr") => void;
	"data-testid"?: string;
}

/**
 * OCRModeFilter component for filtering benchmark data by OCR mode.
 * Supports single-select functionality with an "All" option.
 * Options: "All", "No OCR", "With OCR"
 */
export function OCRModeFilter({
	selectedOCRMode,
	onOCRModeChange,
	"data-testid": testId = "filter-ocr",
}: OCRModeFilterProps) {
	/**
	 * Handle selection changes for OCR mode.
	 */
	const handleChange = useCallback(
		(e: React.ChangeEvent<HTMLSelectElement>) => {
			const value = e.target.value as "" | "no_ocr" | "with_ocr";
			onOCRModeChange(value);
		},
		[onOCRModeChange],
	);

	return (
		<div className="flex flex-col gap-2">
			<label htmlFor="ocr-mode-filter" className="text-sm font-medium">
				OCR Mode
			</label>
			<select
				id="ocr-mode-filter"
				data-testid={testId}
				value={selectedOCRMode}
				onChange={handleChange}
				className="rounded-md border border-input bg-background px-3 py-2 text-sm"
			>
				<option value="">All</option>
				<option value="no_ocr">No OCR</option>
				<option value="with_ocr">With OCR</option>
			</select>
		</div>
	);
}
