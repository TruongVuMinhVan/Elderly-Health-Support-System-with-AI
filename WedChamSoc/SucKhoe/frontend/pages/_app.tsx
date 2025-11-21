/**
 * Next.js App component for Elderly Health Support System
 */

import type { AppProps } from "next/app";
import { AuthProvider } from "@/lib/auth";
import { AppSettingsProvider } from "@/contexts/AppSettingsContext";
import { QueryClient, QueryClientProvider } from "react-query";
import { ReactQueryDevtools } from "react-query/devtools";
import { useState } from "react";
import "@/styles/globals.css";

// Create a client
const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: 1,
        refetchOnWindowFocus: false,
        staleTime: 5 * 60 * 1000, // 5 minutes
        cacheTime: 10 * 60 * 1000, // 10 minutes
      },
      mutations: {
        retry: 1,
      },
    },
  });

export default function App({ Component, pageProps }: AppProps) {
  const [queryClient] = useState(() => createQueryClient());

  return (
    <AuthProvider>
      <AppSettingsProvider>
        <QueryClientProvider client={queryClient}>
          <Component {...pageProps} />
          {process.env.NODE_ENV === "development" && (
            <ReactQueryDevtools initialIsOpen={false} />
          )}
        </QueryClientProvider>
      </AppSettingsProvider>
    </AuthProvider>
  );
}
