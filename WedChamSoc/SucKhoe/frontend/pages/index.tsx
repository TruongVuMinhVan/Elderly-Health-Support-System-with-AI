/**
 * Home page for Elderly Health Support System
 */

import React from "react";
import { useAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import Dashboard from "@/components/Dashboard/Dashboard";
import LandingPage from "@/components/Landing/LandingPage";

const HomePage: React.FC = () => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout
      title="Trang chủ - Hệ thống hỗ trợ sức khỏe người cao tuổi"
      description="Theo dõi và chăm sóc sức khỏe cho người cao tuổi một cách dễ dàng và hiệu quả"
      showSidebar={!!user}
    >
      {user ? <Dashboard /> : <LandingPage />}
    </Layout>
  );
};

export default HomePage;
