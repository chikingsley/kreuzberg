import { createContext, type ReactNode, useContext, useEffect, useState } from "react";

export type Theme = "light" | "dark" | "system";

interface ThemeContextState {
	theme: Theme;
	setTheme: (theme: Theme) => void;
	resolvedTheme: "light" | "dark";
}

const ThemeContext = createContext<ThemeContextState | undefined>(undefined);

const THEME_STORAGE_KEY = "kreuzberg-theme";

/**
 * Get the system theme preference
 */
function getSystemTheme(): "light" | "dark" {
	if (typeof window === "undefined") {
		return "light";
	}
	return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

/**
 * Get the resolved theme (actual theme to apply)
 */
function getResolvedTheme(theme: Theme): "light" | "dark" {
	if (theme === "system") {
		return getSystemTheme();
	}
	return theme;
}

export function ThemeProvider({ children }: { children: ReactNode }) {
	const [theme, setThemeState] = useState<Theme>("system");
	const [resolvedTheme, setResolvedTheme] = useState<"light" | "dark">("light");
	const [mounted, setMounted] = useState(false);

	// Initialize theme from localStorage and system preference
	useEffect(() => {
		const savedTheme = localStorage.getItem(THEME_STORAGE_KEY) as Theme | null;
		const initialTheme = savedTheme || "system";

		setThemeState(initialTheme);
		setResolvedTheme(getResolvedTheme(initialTheme));
		setMounted(true);

		// Apply theme to document
		applyTheme(getResolvedTheme(initialTheme));
	}, []);

	// Update resolved theme when system preference changes
	useEffect(() => {
		if (!mounted) return;

		const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

		const handleChange = () => {
			if (theme === "system") {
				const newResolved = getResolvedTheme("system");
				setResolvedTheme(newResolved);
				applyTheme(newResolved);
			}
		};

		mediaQuery.addEventListener("change", handleChange);
		return () => mediaQuery.removeEventListener("change", handleChange);
	}, [theme, mounted]);

	const setTheme = (newTheme: Theme) => {
		setThemeState(newTheme);
		localStorage.setItem(THEME_STORAGE_KEY, newTheme);

		const resolved = getResolvedTheme(newTheme);
		setResolvedTheme(resolved);
		applyTheme(resolved);
	};

	// Prevent flash of unstyled content
	if (!mounted) {
		return <>{children}</>;
	}

	return <ThemeContext.Provider value={{ theme, setTheme, resolvedTheme }}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
	const context = useContext(ThemeContext);
	if (!context) {
		throw new Error("useTheme must be used within ThemeProvider");
	}
	return context;
}

/**
 * Apply theme to the document
 */
function applyTheme(theme: "light" | "dark") {
	if (typeof document === "undefined") return;

	const htmlElement = document.documentElement;

	if (theme === "dark") {
		htmlElement.classList.add("dark");
		htmlElement.style.colorScheme = "dark";
	} else {
		htmlElement.classList.remove("dark");
		htmlElement.style.colorScheme = "light";
	}
}
