import '@/App.css'
import { RouterProvider } from '@tanstack/react-router'
import { router } from '@/router'
import { BenchmarkProvider } from '@/context/BenchmarkContext'
import { ThemeProvider } from '@/context/ThemeContext'
import ErrorBoundary from '@/components/ErrorBoundary'

/**
 * Main Application Component
 * Provides both the benchmark data context and router to the entire application.
 * Wrapped in ErrorBoundary to catch and gracefully handle any React component errors.
 * Also provides theme context for light/dark mode support.
 */
function App(): React.ReactElement {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <BenchmarkProvider>
          <RouterProvider router={router} />
        </BenchmarkProvider>
      </ThemeProvider>
    </ErrorBoundary>
  )
}

export default App
