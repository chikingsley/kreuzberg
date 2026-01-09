import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "@/App";

/**
 * Application Entry Point
 * Renders the app with necessary providers:
 * - StrictMode: Highlights potential problems in the application
 * - BenchmarkProvider: Provided in App component
 * - ThemeProvider: Provided in App component
 * - RouterProvider: Handled in App component
 */
const rootElement = document.getElementById("root");

if (!rootElement) {
	throw new Error("Root element not found");
}

createRoot(rootElement).render(
	<StrictMode>
		<App />
	</StrictMode>,
);
