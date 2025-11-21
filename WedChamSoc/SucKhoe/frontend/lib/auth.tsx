/**
 * Simple authentication context and hooks
 *
 * Updated to support 2FA: returns `2fa_required` from login() and provides completeEmail2FA().
 */

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from "react";
import Cookies from "js-cookie";
import { useRouter } from "next/router";
import axios from "axios";

interface User {
  id: number;
  email: string;
  full_name: string;
  phone?: string;
  is_active: boolean;
  email_verified: boolean;
}

type TwoFactorRequiredResponse = {
  status: "2fa_required";
  temp_token: string;
  message?: string;
  method?: "totp" | "email";
};

type LoginSuccessResponse = {
  access_token: string;
  user: User;
};

type LoginResponse = LoginSuccessResponse | TwoFactorRequiredResponse;

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<LoginResponse>;
  register: (
    email: string,
    password: string,
    full_name: string,
    phone?: string
  ) => Promise<void>;
  logout: () => void;
  token: string | null;
  // new: complete email 2FA flow
  completeEmail2FA: (tempToken: string, email: string, otp: string) => Promise<LoginSuccessResponse>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000/api";

export const AuthProvider: React.FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [token, setToken] = useState<string | null>(null);
  const router = useRouter();

  // Helper: when token is set, also set axios default header
  const applyToken = (t: string | null) => {
    if (t) {
      axios.defaults.headers.common["Authorization"] = `Bearer ${t}`;
    } else {
      delete axios.defaults.headers.common["Authorization"];
    }
  };

  // Initialize auth state
  useEffect(() => {
    const initAuth = async () => {
      const savedToken = Cookies.get("auth_token");
      if (savedToken) {
        setToken(savedToken);
        applyToken(savedToken);
        try {
          // Verify token and get user info
          const response = await axios.get(`${API_BASE_URL}/auth/me`);
          setUser(response.data);
        } catch (error) {
          console.error("Token verification failed:", error);
          // Remove invalid token
          Cookies.remove("auth_token");
          setToken(null);
          applyToken(null);
        }
      }
      setIsLoading(false);
    };

    initAuth();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /**
   * login: calls backend /auth/login
   * - If backend returns access_token -> set cookie, set user and redirect
   * - If backend returns { status: '2fa_required' } -> return that object so caller can prompt 2FA
   */
  const login = async (email: string, password: string): Promise<LoginResponse> => {
    try {
      setIsLoading(true);
      const response = await axios.post(`${API_BASE_URL}/auth/login`, {
        email,
        password,
      });

      const data = response.data;

      // If backend indicates 2FA required, return that object to caller
      if (data && data.status === "2fa_required") {
        // Do NOT set cookie or redirect here — caller will handle 2FA step
        return data as TwoFactorRequiredResponse;
      }

      // Normal login: store token & user, set axios header, redirect
      const { access_token, user: userData } = data as LoginSuccessResponse;
      if (access_token) {
        Cookies.set("auth_token", access_token, { expires: 1 }); // 1 day
        setToken(access_token);
        applyToken(access_token);
        setUser(userData);
        // Redirect to dashboard/home
        router.push("/");
        return { access_token, user: userData } as LoginSuccessResponse;
      }

      // Unexpected shape: throw
      throw new Error("Unexpected login response");
    } catch (error: any) {
      console.error("Login failed:", error);
      // Re-throw so UI can show error
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * completeEmail2FA:
   * Called after user inputs OTP received via email.
   * Calls backend /auth/verify-email-2fa which returns access_token + user on success.
   */
  const completeEmail2FA = async (tempToken: string, email: string, otp: string): Promise<LoginSuccessResponse> => {
    try {
      setIsLoading(true);
      const response = await axios.post(`${API_BASE_URL}/auth/verify-email-2fa`, {
        temp_token: tempToken,
        email,
        otp,
      });

      const data = response.data as LoginSuccessResponse;
      if (!data?.access_token) {
        throw new Error("Invalid response from email 2FA verification");
      }

      Cookies.set("auth_token", data.access_token, { expires: 1 });
      setToken(data.access_token);
      applyToken(data.access_token);
      setUser(data.user);

      // Redirect on success
      router.push("/");

      return data;
    } catch (error: any) {
      console.error("Email 2FA verification failed:", error);
      // Re-throw so UI can show error
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (
    email: string,
    password: string,
    full_name: string,
    phone?: string
  ) => {
    try {
      setIsLoading(true);
      const response = await axios.post(`${API_BASE_URL}/auth/register`, {
        email,
        password,
        full_name,
        phone,
      });

      const { access_token, user: userData } = response.data;

      // Save token to cookie
      Cookies.set("auth_token", access_token, { expires: 1 }); // 1 day
      setToken(access_token);
      applyToken(access_token);
      setUser(userData);

      // Redirect to dashboard
      router.push("/");
    } catch (error: any) {
      console.error("Registration failed:", error);
      throw new Error(
        error.response?.data?.detail || "Registration failed. Please try again."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    // Remove token from cookie and axios header
    Cookies.remove("auth_token");
    setToken(null);
    setUser(null);
    applyToken(null);

    // Redirect to home
    router.push("/");
  };

  const value: AuthContextType = {
    user,
    isLoading,
    login,
    register,
    logout,
    token,
    completeEmail2FA,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

// HOC for protected pages (kept as-is)
export const withAuth = <P extends object>(
  Component: React.ComponentType<P>
) => {
  return function AuthenticatedComponent(props: P) {
    const { user, isLoading } = useAuth();
    const router = useRouter();

    useEffect(() => {
      if (!isLoading && !user) {
        router.push("/auth/login");
      }
    }, [user, isLoading, router]);

    if (isLoading) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      );
    }

    if (!user) {
      return null;
    }

    return <Component {...props} />;
  };
};

// Hook for checking if user is authenticated
export const useUser = () => {
  const { user, isLoading } = useAuth();
  return { user, isLoading, error: null };
};
