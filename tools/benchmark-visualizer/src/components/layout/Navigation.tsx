import { Link } from "@tanstack/react-router";
import type React from "react";
import { Button } from "@/components/ui/button";

/**
 * Navigation link configuration
 * Defines the routes and labels for the main navigation
 */
interface NavLink {
	label: string;
	href: string;
	testId: string;
	description?: string;
}

const navLinks: NavLink[] = [
	{
		label: "Overview",
		href: "/",
		testId: "nav-link-landing",
		description: "Benchmark overview and summary statistics",
	},
	{
		label: "Performance Charts",
		href: "/charts",
		testId: "nav-link-charts",
		description: "Interactive performance charts and visualizations",
	},
	{
		label: "Detailed Comparisons",
		href: "/comparisons",
		testId: "nav-link-comparisons",
		description: "Detailed benchmark comparisons in table format",
	},
	{
		label: "Methodology",
		href: "/methodology",
		testId: "nav-link-methodology",
		description: "Testing methodology and how to interpret results",
	},
];

interface NavigationProps {
	className?: string;
}

/**
 * Navigation Component
 *
 * Provides the main navigation for the benchmark visualizer application.
 * Uses TanStack Router for client-side routing with active link highlighting.
 *
 * Features:
 * - TanStack Router Link integration for SPA navigation
 * - Active link highlighting with button variant switching
 * - Responsive design (horizontal on desktop, flex-wrap on mobile)
 * - Accessibility features (ARIA labels, semantic HTML)
 * - Test IDs for automated testing
 */
export const Navigation: React.FC<NavigationProps> = ({ className = "" }) => {
	return (
		<nav
			className={`sticky top-16 z-40 border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 ${className}`}
			aria-label="Main navigation"
		>
			<div className="container mx-auto px-4 py-3">
				<div className="flex flex-wrap items-center gap-1 md:gap-2">
					{navLinks.map((link) => (
						<Link
							key={link.href}
							to={link.href}
							data-testid={link.testId}
							aria-label={link.description}
							activeProps={{
								className: "active",
							}}
						>
							{({ isActive }) => (
								<Button
									variant={isActive ? "default" : "ghost"}
									size="sm"
									className="transition-colors duration-200 whitespace-nowrap"
									aria-current={isActive ? "page" : undefined}
								>
									{link.label}
								</Button>
							)}
						</Link>
					))}
				</div>
			</div>
		</nav>
	);
};
