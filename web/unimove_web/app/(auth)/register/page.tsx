"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Truck, Mail, Lock, User, Phone, Building2, Eye, EyeOff, AlertCircle, ChevronLeft, CheckCircle } from "lucide-react";
import { authApi } from "@/lib/api";
import { storeAuth, getRoleHome, type AuthUser, type UserRole } from "@/lib/auth";
import { useToast } from "@/components/ui/toast";

type Step = "role" | "form";

const VEHICLES = [
  ["motorbike", "Xe máy (≤ 100kg)"],
  ["pickup", "Bán tải"],
  ["van", "Xe van 5 tạ – 1 tấn"],
  ["truck_1t", "Xe tải 1 tấn"],
  ["truck_2t", "Xe tải 2 tấn"],
  ["truck_5t", "Xe tải 5 tấn+"],
];

export default function RegisterPage() {
  const { toast } = useToast();
  const [step, setStep] = useState<Step>("role");
  const [role, setRole] = useState<UserRole>("customer");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState({
    full_name: "", email: "", phone: "", password: "",
    business_name: "", vehicle_type: "van",
  });
  const set = (k: string, v: string) => setForm((p) => ({ ...p, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (form.password.length < 8) { setError("Mật khẩu tối thiểu 8 ký tự"); return; }
    if (role === "customer" && !form.phone.trim()) { setError("Vui lòng nhập số điện thoại"); return; }
    if (role === "provider" && !form.business_name.trim()) { setError("Vui lòng nhập tên doanh nghiệp"); return; }
    setLoading(true); setError(null);
    try {
      const body: Record<string, unknown> = {
        full_name: form.full_name, email: form.email, password: form.password, role,
        phone: form.phone || undefined,
      };
      if (role === "provider") {
        body.business_name = form.business_name || undefined;
        body.vehicle_type = form.vehicle_type;
      }
      const res = await authApi.register(body);
      if (!res.success || !res.data) { setError((res as { message?: string }).message || "Đăng ký thất bại"); return; }
      const { accessToken, user } = res.data as { accessToken: string; user: AuthUser };
      storeAuth(user, accessToken);
      toast("Đăng ký thành công! Chào mừng đến với UniMove 🎉", "success");
      window.location.href = getRoleHome(user.role);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Lỗi kết nối");
    } finally { setLoading(false); }
  };

  const isProvider = role === "provider";
  const accent = isProvider ? "var(--provider)" : "var(--primary)";
  const gradient = isProvider
    ? "linear-gradient(135deg, #15803d, #22c55e)"
    : "linear-gradient(135deg, #1d4ed8, #3b82f6)";

  /* ─── STEP 1: Chọn role ─── */
  if (step === "role") {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center px-5 py-10" style={{ backgroundColor: "var(--bg)" }}>
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-20 h-20 rounded-3xl flex items-center justify-center mb-4 shadow-2xl"
            style={{ background: "linear-gradient(145deg, #1d4ed8, #3b82f6, #60a5fa)" }}>
            <Truck size={38} className="text-white" strokeWidth={1.8} />
          </div>
          <h1 className="text-3xl font-extrabold" style={{ color: "var(--text)" }}>Tạo tài khoản</h1>
          <p className="text-sm mt-1.5" style={{ color: "var(--muted)" }}>Bạn muốn dùng UniMove với tư cách?</p>
        </div>

        <div className="w-full max-w-sm space-y-4">
          {/* Customer */}
          <button
            onClick={() => { setRole("customer"); setStep("form"); }}
            className="w-full p-5 rounded-3xl text-left transition-all hover:shadow-lg active:scale-[0.98]"
            style={{ backgroundColor: "var(--card)", border: "2px solid var(--primary)" }}
          >
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center text-white shrink-0"
                style={{ background: "linear-gradient(135deg, #1d4ed8, #3b82f6)" }}>
                <User size={26} strokeWidth={1.8} />
              </div>
              <div className="flex-1">
                <p className="text-lg font-bold" style={{ color: "var(--text)" }}>Khách hàng</p>
                <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>Đặt dịch vụ chuyển trọ, mua bán đồ cũ</p>
                <div className="flex gap-2 mt-2 flex-wrap">
                  {["Chuyển trọ", "Khuân vác", "Chợ SV"].map((t) => (
                    <span key={t} className="text-[11px] px-2 py-0.5 rounded-full font-medium"
                      style={{ backgroundColor: "var(--primary-tint)", color: "var(--primary)" }}>{t}</span>
                  ))}
                </div>
              </div>
              <div className="w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0"
                style={{ borderColor: "var(--primary)", backgroundColor: "var(--primary)" }}>
                <CheckCircle size={14} className="text-white" />
              </div>
            </div>
          </button>

          {/* Provider */}
          <button
            onClick={() => { setRole("provider"); setStep("form"); }}
            className="w-full p-5 rounded-3xl text-left transition-all hover:shadow-lg active:scale-[0.98]"
            style={{ backgroundColor: "var(--card)", border: "2px solid var(--provider)" }}
          >
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center text-white shrink-0"
                style={{ background: "linear-gradient(135deg, #15803d, #22c55e)" }}>
                <Building2 size={26} strokeWidth={1.8} />
              </div>
              <div className="flex-1">
                <p className="text-lg font-bold" style={{ color: "var(--text)" }}>Nhà vận chuyển</p>
                <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>Nhận đơn hàng, thu nhập linh hoạt</p>
                <div className="flex gap-2 mt-2 flex-wrap">
                  {["Nhận đơn", "Thu nhập", "Linh hoạt"].map((t) => (
                    <span key={t} className="text-[11px] px-2 py-0.5 rounded-full font-medium"
                      style={{ backgroundColor: "var(--provider-tint)", color: "var(--provider)" }}>{t}</span>
                  ))}
                </div>
              </div>
            </div>
          </button>
        </div>

        <p className="mt-7 text-sm" style={{ color: "var(--muted)" }}>
          Đã có tài khoản?{" "}
          <Link href="/login" className="font-bold hover:underline" style={{ color: "var(--primary)" }}>
            Đăng nhập
          </Link>
        </p>
      </div>
    );
  }

  /* ─── STEP 2: Điền form ─── */
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-5 py-10" style={{ backgroundColor: "var(--bg)" }}>
      {/* Header */}
      <div className="flex items-center gap-3 w-full max-w-sm mb-6">
        <button
          onClick={() => setStep("role")}
          className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
          style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}
        >
          <ChevronLeft size={20} style={{ color: "var(--text)" }} />
        </button>
        <div>
          <h1 className="text-xl font-extrabold" style={{ color: "var(--text)" }}>
            {isProvider ? "Đăng ký đối tác" : "Tạo tài khoản"}
          </h1>
          <div className="flex items-center gap-1.5 mt-0.5">
            <div className="w-4 h-4 rounded flex items-center justify-center" style={{ backgroundColor: accent }}>
              {isProvider ? <Building2 size={10} className="text-white" /> : <User size={10} className="text-white" />}
            </div>
            <span className="text-xs font-semibold" style={{ color: accent }}>
              {isProvider ? "Nhà vận chuyển" : "Khách hàng"}
            </span>
          </div>
        </div>
      </div>

      {/* Form card */}
      <div className="w-full max-w-sm rounded-3xl p-7 shadow-xl" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        {error && (
          <div className="flex items-start gap-2.5 mb-5 px-4 py-3 rounded-2xl"
            style={{ backgroundColor: "var(--error-tint)", border: "1px solid var(--error)" }}>
            <AlertCircle size={16} className="shrink-0 mt-0.5" style={{ color: "var(--error)" }} />
            <p className="text-sm" style={{ color: "var(--error)" }}>{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Full name */}
          <Field label="Họ và tên" required>
            <InputRow icon={<User size={16} />}>
              <input required placeholder="Nguyễn Văn A" value={form.full_name}
                onChange={(e) => set("full_name", e.target.value)} />
            </InputRow>
          </Field>

          {/* Business name (provider only) */}
          {isProvider && (
            <Field label="Tên doanh nghiệp / Biệt danh">
              <InputRow icon={<Building2 size={16} />}>
                <input placeholder="Nhà xe Văn A" value={form.business_name}
                  onChange={(e) => set("business_name", e.target.value)} />
              </InputRow>
            </Field>
          )}

          {/* Email */}
          <Field label="Email" required>
            <InputRow icon={<Mail size={16} />}>
              <input type="email" required placeholder="email@example.com" value={form.email}
                onChange={(e) => set("email", e.target.value)} />
            </InputRow>
          </Field>

          {/* Phone */}
          <Field label="Số điện thoại">
            <InputRow icon={<Phone size={16} />}>
              <input type="tel" placeholder="0901234567" value={form.phone}
                onChange={(e) => set("phone", e.target.value)} />
            </InputRow>
          </Field>

          {/* Vehicle type (provider only) */}
          {isProvider && (
            <Field label="Loại phương tiện" required>
              <select value={form.vehicle_type} onChange={(e) => set("vehicle_type", e.target.value)}
                className="w-full h-12 rounded-xl border px-4 text-sm"
                style={{ backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)" }}>
                {VEHICLES.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </Field>
          )}

          {/* Password */}
          <Field label="Mật khẩu" required>
            <InputRow icon={<Lock size={16} />} trailing={
              <button type="button" onClick={() => setShowPw(!showPw)} className="p-1" style={{ color: "var(--muted)" }}>
                {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
              </button>
            }>
              <input type={showPw ? "text" : "password"} required minLength={6}
                placeholder="Tối thiểu 6 ký tự" value={form.password}
                onChange={(e) => set("password", e.target.value)} />
            </InputRow>
          </Field>

          <button
            type="submit"
            disabled={loading}
            className="w-full flex items-center justify-center gap-2 font-bold text-base text-white transition-opacity disabled:opacity-60 mt-1"
            style={{ height: "52px", borderRadius: "16px", background: gradient, cursor: loading ? "not-allowed" : "pointer" }}
          >
            {loading ? (
              <><span className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white animate-spin inline-block" /> Đang đăng ký...</>
            ) : (
              <><CheckCircle size={18} /> {isProvider ? "Đăng ký đối tác" : "Tạo tài khoản"}</>
            )}
          </button>
        </form>

        <p className="text-center text-sm mt-5" style={{ color: "var(--muted)" }}>
          Đã có tài khoản?{" "}
          <Link href="/login" className="font-bold hover:underline" style={{ color: accent }}>Đăng nhập</Link>
        </p>
      </div>
    </div>
  );
}

/* ── Helpers ── */
function Field({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-sm font-semibold mb-1.5" style={{ color: "var(--text)" }}>
        {label}{required && <span className="ml-0.5" style={{ color: "var(--error)" }}>*</span>}
      </label>
      {children}
    </div>
  );
}

function InputRow({ icon, trailing, children }: { icon: React.ReactNode; trailing?: React.ReactNode; children: React.ReactElement<React.InputHTMLAttributes<HTMLInputElement>> }) {
  return (
    <div className="relative flex items-center">
      <span className="absolute left-3.5 pointer-events-none" style={{ color: "var(--muted)" }}>{icon}</span>
      {React.cloneElement(children, {
        className: "w-full h-12 pl-10 rounded-xl border text-sm focus:outline-none focus:ring-2 focus:ring-offset-0",
        style: { backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)", paddingRight: trailing ? "44px" : "16px" } as React.CSSProperties,
      })}
      {trailing && <span className="absolute right-3">{trailing}</span>}
    </div>
  );
}
