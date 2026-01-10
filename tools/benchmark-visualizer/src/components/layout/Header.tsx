import type React from "react";
import { ThemeToggle } from "@/components/ui/theme-toggle";

export const Header: React.FC = () => {
	// Detect if running in iframe to avoid header conflicts
	const isInIframe = window.self !== window.top;

	return (
		<header className={`border-b border-border bg-background ${isInIframe ? "" : "sticky top-0 z-50"}`}>
			<div className="container mx-auto px-4 py-4 flex items-center justify-between">
				<div className="flex items-center gap-2">
					<h1 className="text-2xl font-bold tracking-tight">Kreuzberg Benchmarks</h1>
				</div>

				<ThemeToggle />
			</div>
		</header>
	);
};
