"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Truck, Mail, Lock, AlertCircle, Eye, EyeOff, Shield } from "lucide-react";
import { authApi } from "@/lib/api";
import { storeAuth, storeAdminSession, getRoleHome, type AuthUser } from "@/lib/auth";
import { useToast } from "@/components/ui/toast";

export default function LoginPage() {
  const { toast } = useToast();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await authApi.login(email, password);
      if (!res.success || !res.data) {
        setError((res as { message?: string }).message || "Sai email hoặc mật khẩu");
        return;
      }
      const { accessToken, user } = res.data as { accessToken: string; user: AuthUser };
      if (user.role === "admin") {
        storeAdminSession(user, accessToken);
        toast(`Chào mừng ${user.full_name}! 👋`, "success");
        window.location.href = getRoleHome("admin");
        return;
      }
      storeAuth(user, accessToken);
      toast(`Chào mừng ${user.full_name}! 👋`, "success");
      window.location.href = getRoleHome(user.role);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Không thể kết nối đến server. Kiểm tra backend đang chạy.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-5 py-10"
      style={{ backgroundColor: "var(--bg)" }}
    >
      {/* Logo */}
      <div className="flex flex-col items-center mb-8">
        <div
          className="w-20 h-20 rounded-3xl flex items-center justify-center mb-4 shadow-2xl"
          style={{ background: "linear-gradient(145deg, #1d4ed8 0%, #3b82f6 60%, #60a5fa 100%)" }}
        >
          <Truck size={38} className="text-white" strokeWidth={1.8} />
        </div>
        <h1 className="text-3xl font-extrabold tracking-tight" style={{ color: "var(--text)" }}>
          UniMove
        </h1>
        <p className="text-sm mt-1.5" style={{ color: "var(--muted)" }}>
          Chuyển trọ thông minh cho sinh viên
        </p>
      </div>

      {/* Role pills */}
      <div className="grid grid-cols-3 gap-2 mb-7 w-full max-w-sm">
        <div
          className="flex flex-col items-center gap-1.5 px-2 py-3 rounded-2xl text-center"
          style={{ backgroundColor: "var(--primary-tint)", border: "1.5px solid var(--primary)" }}
        >
          <div
            className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
            style={{ backgroundColor: "var(--primary)" }}
          >
            <svg width="16" height="16" fill="white" viewBox="0 0 24 24">
              <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z" />
            </svg>
          </div>
          <p className="text-[11px] font-bold leading-tight" style={{ color: "var(--primary)" }}>Khách hàng</p>
        </div>

        <div
          className="flex flex-col items-center gap-1.5 px-2 py-3 rounded-2xl text-center"
          style={{ backgroundColor: "var(--provider-tint)", border: "1.5px solid var(--provider)" }}
        >
          <div
            className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
            style={{ backgroundColor: "var(--provider)" }}
          >
            <Truck size={15} className="text-white" strokeWidth={2} />
          </div>
          <p className="text-[11px] font-bold leading-tight" style={{ color: "var(--provider)" }}>Nhà vận chuyển</p>
        </div>

        <div
          className="flex flex-col items-center gap-1.5 px-2 py-3 rounded-2xl text-center"
          style={{ backgroundColor: "rgba(139, 92, 246, 0.12)", border: "1.5px solid #7c3aed" }}
        >
          <div
            className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
            style={{ backgroundColor: "#7c3aed" }}
          >
            <Shield size={15} className="text-white" strokeWidth={2} />
          </div>
          <p className="text-[11px] font-bold leading-tight" style={{ color: "#7c3aed" }}>Admin</p>
        </div>
      </div>

      {/* Login card */}
      <div
        className="w-full max-w-sm rounded-3xl p-7 shadow-xl"
        style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}
      >
        <h2 className="text-xl font-bold mb-5" style={{ color: "var(--text)" }}>Đăng nhập</h2>

        {/* Error */}
        {error && (
          <div
            className="flex items-start gap-2.5 mb-5 px-4 py-3 rounded-2xl"
            style={{ backgroundColor: "var(--error-tint)", border: "1px solid var(--error)" }}
          >
            <AlertCircle size={16} className="shrink-0 mt-0.5" style={{ color: "var(--error)" }} />
            <p className="text-sm leading-snug" style={{ color: "var(--error)" }}>{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Email */}
          <div>
            <label className="block text-sm font-semibold mb-1.5" style={{ color: "var(--text)" }}>
              Email
            </label>
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: "var(--muted)" }}>
                <Mail size={16} />
              </span>
              <input
                type="email"
                autoComplete="email"
                required
                placeholder="email@example.com"
                value={email}
                onChange={(e) => { setEmail(e.target.value); setError(null); }}
                className="w-full h-12 pl-10 pr-4 rounded-xl border text-sm transition-colors focus:outline-none focus:ring-2 focus:ring-offset-0"
                style={{
                  backgroundColor: "var(--surface)",
                  borderColor: "var(--border)",
                  color: "var(--text)",
                }}
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-sm font-semibold" style={{ color: "var(--text)" }}>Mật khẩu</label>
              <Link
                href="/forgot-password"
                className="text-xs font-medium hover:underline"
                style={{ color: "var(--primary)" }}
              >
                Quên mật khẩu?
              </Link>
            </div>
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: "var(--muted)" }}>
                <Lock size={16} />
              </span>
              <input
                type={showPw ? "text" : "password"}
                autoComplete="current-password"
                required
                placeholder="••••••••"
                value={password}
                onChange={(e) => { setPassword(e.target.value); setError(null); }}
                className="w-full h-12 pl-10 pr-12 rounded-xl border text-sm transition-colors focus:outline-none focus:ring-2 focus:ring-offset-0"
                style={{
                  backgroundColor: "var(--surface)",
                  borderColor: "var(--border)",
                  color: "var(--text)",
                }}
              />
              <button
                type="button"
                onClick={() => setShowPw(!showPw)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1"
                style={{ color: "var(--muted)" }}
              >
                {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full h-13 rounded-2xl text-white font-bold text-base flex items-center justify-center gap-2 mt-2 transition-opacity disabled:opacity-60"
            style={{
              height: "52px",
              background: "linear-gradient(135deg, #1d4ed8, #3b82f6)",
              cursor: loading ? "not-allowed" : "pointer",
            }}
          >
            {loading ? (
              <>
                <span
                  className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white animate-spin"
                  style={{ display: "inline-block" }}
                />
                Đang đăng nhập...
              </>
            ) : (
              "Đăng nhập"
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="flex items-center gap-3 my-5">
          <div className="flex-1 h-px" style={{ backgroundColor: "var(--border)" }} />
          <span className="text-xs" style={{ color: "var(--muted)" }}>Chưa có tài khoản?</span>
          <div className="flex-1 h-px" style={{ backgroundColor: "var(--border)" }} />
        </div>

        <Link href="/register">
          <button
            className="w-full h-12 rounded-2xl text-sm font-semibold border transition-colors"
            style={{
              borderColor: "var(--border)",
              color: "var(--text)",
              backgroundColor: "transparent",
            }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = "var(--surface)"; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent"; }}
          >
            Tạo tài khoản mới
          </button>
        </Link>
      </div>

      {/* Footer hint */}
      <p className="text-center text-xs mt-5 px-4" style={{ color: "var(--muted)" }}>
        Đăng nhập đúng role → tự động chuyển đến giao diện phù hợp (admin → Admin Dashboard)
      </p>
    </div>
  );
}
