import type { AggregatedBenchmarkData } from '@/types/benchmark'
import { AggregatedBenchmarkDataSchema } from '@/schemas/benchmarkSchema'
import { ZodError } from 'zod'

export class BenchmarkDataService {
  private static readonly DATA_URL = '/aggregated.json'

  static async fetchData(): Promise<AggregatedBenchmarkData> {
    const response = await fetch(this.DATA_URL)
    if (!response.ok) {
      throw new Error(`Failed to fetch benchmark data: ${response.statusText}`)
    }

    const data = await response.json()

    // Validate the JSON response against the schema
    try {
      const validatedData = AggregatedBenchmarkDataSchema.parse(data)
      return validatedData
    } catch (error) {
      if (error instanceof ZodError) {
        const issues = error.issues
          .map(
            (issue) =>
              `Path: ${issue.path.join('.')} | Code: ${issue.code} | Message: ${issue.message}`
          )
          .join('\n')

        throw new Error(
          `Benchmark data validation failed:\n${issues}`
        )
      }
      throw error
    }
  }
}
