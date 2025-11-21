/**
 * Main Layout component for Elderly Health Support System
 */

import React, { ReactNode } from "react";
import { useAuth } from "@/lib/auth";
import Head from "next/head";
import { Toaster } from "react-hot-toast";
import Header from "./Header";
import Sidebar from "./Sidebar";
import Footer from "./Footer";
import LoadingSpinner from "../UI/LoadingSpinner";

interface LayoutProps {
  children: ReactNode;
  title?: string;
  description?: string;
  showSidebar?: boolean;
  className?: string;
}

const Layout: React.FC<LayoutProps> = ({
  children,
  title = "Hệ thống hỗ trợ sức khỏe người cao tuổi",
  description = "Theo dõi và chăm sóc sức khỏe cho người cao tuổi",
  showSidebar = true,
  className = "",
}) => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-elderly-bg">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <>
      <Head>
        <title>{title}</title>
        <meta name="description" content={description} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#0ea5e9" />
        <link rel="icon" href="/favicon.ico" />

        {/* Open Graph tags */}
        <meta property="og:title" content={title} />
        <meta property="og:description" content={description} />
        <meta property="og:type" content="website" />
        <meta property="og:image" content="/og-image.png" />

        {/* Twitter Card tags */}
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content={title} />
        <meta name="twitter:description" content={description} />
        <meta name="twitter:image" content="/og-image.png" />

        {/* Preload critical fonts */}
        <link
          rel="preload"
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
          as="style"
        />
      </Head>

      <div className="min-h-screen bg-elderly-bg dark:bg-dark-bg transition-colors">
        {/* Skip to main content link for accessibility */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-primary-600 text-white px-4 py-2 rounded-lg z-50"
        >
          Chuyển đến nội dung chính
        </a>

        {/* Header */}
        <Header />

        <div className="flex">
          {/* Sidebar */}
          {showSidebar && user && (
            <aside className="hidden lg:block w-64 bg-white dark:bg-dark-card-bg shadow-sm border-r border-elderly-border dark:border-dark-border transition-colors">
              <Sidebar />
            </aside>
          )}

          {/* Main Content */}
          <main
            id="main-content"
            className={`flex-1 ${
              showSidebar && user ? "lg:ml-0" : ""
            } ${className}`}
            role="main"
          >
            <div className="min-h-screen">{children}</div>
          </main>
        </div>

        {/* Footer */}
        <Footer />

        {/* Toast notifications */}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 5000,
            style: {
              fontSize: "16px",
              padding: "16px",
              borderRadius: "12px",
            },
            success: {
              iconTheme: {
                primary: "#10b981",
                secondary: "#ffffff",
              },
            },
            error: {
              iconTheme: {
                primary: "#ef4444",
                secondary: "#ffffff",
              },
            },
          }}
        />
      </div>
    </>
  );
};

export default Layout;
