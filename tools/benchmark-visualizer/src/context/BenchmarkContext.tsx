import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from "react";
import { fetchData } from "@/services/benchmarkService";
import type { AggregatedBenchmarkData } from "@/types/benchmark";

interface BenchmarkContextState {
	data: AggregatedBenchmarkData | null;
	loading: boolean;
	error: Error | null;
}

const BenchmarkContext = createContext<BenchmarkContextState | undefined>(undefined);

export function BenchmarkProvider({ children }: { children: ReactNode }) {
	const [data, setData] = useState<AggregatedBenchmarkData | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<Error | null>(null);

	useEffect(() => {
		fetchData()
			.then((data) => {
				setData(data);
				setLoading(false);
				setError(null);
			})
			.catch((error) => {
				setData(null);
				setLoading(false);
				setError(error);
			});
	}, []);

	const value = useMemo(() => ({ data, loading, error }), [data, loading, error]);

	return <BenchmarkContext.Provider value={value}>{children}</BenchmarkContext.Provider>;
}

export function useBenchmark() {
	const context = useContext(BenchmarkContext);
	if (!context) {
		throw new Error("useBenchmark must be used within BenchmarkProvider");
	}
	return context;
}
