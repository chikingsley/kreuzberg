import * as React from "react";
import { Button } from "@/components/ui/button";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuLabel,
	DropdownMenuRadioGroup,
	DropdownMenuRadioItem,
	DropdownMenuSeparator,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { type Theme, useTheme } from "@/context/ThemeContext";

/**
 * Sun Icon
 */
function SunIcon(props: React.SVGProps<SVGSVGElement>) {
	return (
		<svg className="h-[1.2rem] w-[1.2rem]" fill="none" stroke="currentColor" viewBox="0 0 24 24" {...props}>
			<path
				strokeLinecap="round"
				strokeLinejoin="round"
				strokeWidth={2}
				d="M12 3v1m6.364 1.636l-.707-.707M21 12h-1m-1.636 6.364l-.707.707M12 21v1m-6.364-1.636l.707.707M3 12h1m1.636-6.364l.707-.707"
			/>
		</svg>
	);
}

/**
 * Moon Icon
 */
function MoonIcon(props: React.SVGProps<SVGSVGElement>) {
	return (
		<svg className="h-[1.2rem] w-[1.2rem]" fill="currentColor" viewBox="0 0 24 24" {...props}>
			<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
		</svg>
	);
}

/**
 * System Icon
 */
function SystemIcon(props: React.SVGProps<SVGSVGElement>) {
	return (
		<svg className="h-[1.2rem] w-[1.2rem]" fill="none" stroke="currentColor" viewBox="0 0 24 24" {...props}>
			<path
				strokeLinecap="round"
				strokeLinejoin="round"
				strokeWidth={2}
				d="M9.75 17L9 20m0 0l-.75 3M9 20a3 3 0 015.64 1.051A5.001 5.001 0 0119 11H3a5 5 0 014.75 9M9 20l.75 3M9 20l-.75-3m9.75-3L15 20m0 0l.75 3M15 20a3 3 0 01-5.64 1.051A5 5 0 015 11h14a5 5 0 01-4.75 9M15 20l-.75 3m0-3l.75-3"
			/>
		</svg>
	);
}

export const ThemeToggle = React.forwardRef<HTMLButtonElement, React.ButtonHTMLAttributes<HTMLButtonElement>>(
	(props, ref) => {
		const { theme, setTheme } = useTheme();

		const handleThemeChange = (newTheme: string) => {
			setTheme(newTheme as Theme);
		};

		return (
			<DropdownMenu>
				<DropdownMenuTrigger asChild>
					<Button
						ref={ref}
						variant="ghost"
						size="icon"
						aria-label="Toggle theme"
						data-testid="theme-toggle"
						className="h-9 w-9"
						{...props}
					>
						<SunIcon className="rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
						<MoonIcon className="absolute rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
						<span className="sr-only">Toggle theme</span>
					</Button>
				</DropdownMenuTrigger>
				<DropdownMenuContent align="end">
					<DropdownMenuLabel className="text-xs font-semibold">Theme</DropdownMenuLabel>
					<DropdownMenuSeparator />
					<DropdownMenuRadioGroup value={theme} onValueChange={handleThemeChange}>
						<DropdownMenuRadioItem value="light">
							<SunIcon className="mr-2 h-4 w-4" />
							<span>Light</span>
						</DropdownMenuRadioItem>
						<DropdownMenuRadioItem value="dark">
							<MoonIcon className="mr-2 h-4 w-4" />
							<span>Dark</span>
						</DropdownMenuRadioItem>
						<DropdownMenuRadioItem value="system">
							<SystemIcon className="mr-2 h-4 w-4" />
							<span>System</span>
						</DropdownMenuRadioItem>
					</DropdownMenuRadioGroup>
				</DropdownMenuContent>
			</DropdownMenu>
		);
	},
);

ThemeToggle.displayName = "ThemeToggle";
