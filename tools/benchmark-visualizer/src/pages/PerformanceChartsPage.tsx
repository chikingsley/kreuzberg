import { useState } from 'react'
import { useBenchmark } from '@/context/BenchmarkContext'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { FrameworkFilter } from '@/components/filters/FrameworkFilter'
import { FileTypeFilter } from '@/components/filters/FileTypeFilter'
import { OCRModeFilter } from '@/components/filters/OCRModeFilter'
import { ThroughputChart } from '@/components/charts/ThroughputChart'
import { MemoryChart } from '@/components/charts/MemoryChart'
import { DurationChart } from '@/components/charts/DurationChart'
import { ColdStartChart } from '@/components/charts/ColdStartChart'
import { DiskSizeChart } from '@/components/charts/DiskSizeChart'

export function PerformanceChartsPage() {
  const { data, loading, error } = useBenchmark()
  const [selectedFrameworks, setSelectedFrameworks] = useState<string[]>([])
  const [selectedFileTypes, setSelectedFileTypes] = useState<string[]>(['pdf']) // Default to PDF
  const [ocrMode, setOcrMode] = useState<'' | 'no_ocr' | 'with_ocr'>('no_ocr') // Default to no OCR

  if (loading) {
    return (
      <div className="container mx-auto p-4">
        <Skeleton className="h-12 w-64 mb-6" data-testid="skeleton-charts" />
        <Skeleton className="h-96" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="container mx-auto p-4">
        <Alert variant="destructive" data-testid="error-message">
          <AlertDescription>Error: {error.message}</AlertDescription>
        </Alert>
      </div>
    )
  }

  if (!data) {
    return null
  }

  // Get the first selected framework and file type for charts
  const selectedFramework = selectedFrameworks[0]
  const selectedFileType = selectedFileTypes[0]

  // Check if minimum required filters are selected
  const hasRequiredFilters = selectedFileType && ocrMode

  return (
    <div data-testid="page-charts" className="container mx-auto p-4">
      <h1 className="text-4xl font-bold mb-6">Performance Charts</h1>

      <div className="mb-6 flex gap-4">
        <FrameworkFilter
          selectedFrameworks={selectedFrameworks}
          onFrameworksChange={setSelectedFrameworks}
          data-testid="filters-framework"
        />
        <FileTypeFilter
          selectedFileTypes={selectedFileTypes}
          onFileTypesChange={setSelectedFileTypes}
          data-testid="filters-file-type"
        />
        <OCRModeFilter
          selectedOCRMode={ocrMode}
          onOCRModeChange={setOcrMode}
          data-testid="filter-ocr"
        />
      </div>

      {!hasRequiredFilters ? (
        <Alert data-testid="validation-message">
          <AlertDescription>
            Select a file type and OCR mode to view charts
          </AlertDescription>
        </Alert>
      ) : (
        <div className="space-y-6">
          <ThroughputChart
            framework={selectedFramework}
            fileType={selectedFileType}
            ocrMode={ocrMode}
          />

          <MemoryChart
            framework={selectedFramework}
            fileType={selectedFileType}
            ocrMode={ocrMode}
          />

          <DurationChart
            fileType={selectedFileType}
            ocrMode={ocrMode}
          />

          <ColdStartChart
            framework={selectedFramework}
          />

          <DiskSizeChart />
        </div>
      )}
    </div>
  )
}
