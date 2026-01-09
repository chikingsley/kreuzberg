import React from "react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";

interface ErrorBoundaryProps {
	children: React.ReactNode;
}

interface ErrorBoundaryState {
	hasError: boolean;
	error: Error | null;
}

/**
 * ErrorBoundary Component
 *
 * A React class component that catches JavaScript errors anywhere in the child component tree,
 * displays those errors as a user-friendly alert, and provides a recovery option.
 * This prevents the entire app from crashing due to errors in chart components or other children.
 */
class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
	constructor(props: ErrorBoundaryProps) {
		super(props);
		this.state = {
			hasError: false,
			error: null,
		};
	}

	/**
	 * Updates state so the next render will show the fallback UI.
	 * Called after an error has been thrown by a descendant component.
	 */
	static getDerivedStateFromError(error: Error): ErrorBoundaryState {
		return {
			hasError: true,
			error,
		};
	}

	/**
	 * Log the error to an error reporting service.
	 * This method is called after an error has been thrown by a descendant component.
	 */
	componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
		console.error("Error caught by ErrorBoundary:", error);
		console.error("Error Info:", errorInfo);
	}

	/**
	 * Reload the page to recover from the error
	 */
	handleReload = (): void => {
		window.location.reload();
	};

	render(): React.ReactNode {
		if (this.state.hasError) {
			return (
				<div className="flex items-center justify-center min-h-screen bg-background p-4">
					<div className="w-full max-w-md">
						<Alert variant="destructive">
							<AlertTitle>Something went wrong</AlertTitle>
							<AlertDescription className="mt-4 space-y-4">
								<p>An error occurred while rendering the application. Please try reloading the page.</p>
								{this.state.error && (
									<details className="text-xs mt-2 p-2 bg-destructive/10 rounded">
										<summary className="cursor-pointer font-mono font-semibold">Error details</summary>
										<pre className="mt-2 whitespace-pre-wrap break-words font-mono text-xs">
											{this.state.error.toString()}
										</pre>
									</details>
								)}
								<Button onClick={this.handleReload} variant="default" className="w-full mt-4">
									Reload Page
								</Button>
							</AlertDescription>
						</Alert>
					</div>
				</div>
			);
		}

		return this.props.children;
	}
}

export default ErrorBoundary;
