"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { User, Lock, FileText, HelpCircle, ChevronRight, Camera, Truck, Star, TrendingUp } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { authApi } from "@/lib/api";
import { getStoredUser, type AuthUser } from "@/lib/auth";

export default function ProviderProfilePage() {
  const [profile, setProfile] = useState<AuthUser | null>(getStoredUser());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    authApi.getMe().then(r => { if (r.success && r.data) setProfile(r.data as AuthUser); }).finally(() => setLoading(false));
  }, []);

  const isVerified = profile?.is_verified;

  const menu = [
    { icon: User, label: "Chỉnh sửa thông tin", desc: "Tên, SĐT, tên doanh nghiệp", href: "/profile/edit" },
    { icon: FileText, label: "Giấy tờ xác minh", desc: isVerified ? "✓ Đã xác minh" : "Chưa xác minh - Upload ngay", href: "/documents" },
    { icon: Lock, label: "Đổi mật khẩu", desc: "Cập nhật mật khẩu đăng nhập", href: "/profile/change-password" },
    { icon: HelpCircle, label: "Trợ giúp", desc: "FAQ, liên hệ hỗ trợ", href: "/profile/help" },
  ];

  return (
    <div className="max-w-3xl space-y-6 animate-fade-in">
      <div>
        <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Hồ sơ nhà vận chuyển</h1>
        <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>Quản lý thông tin và xác minh tài khoản</p>
      </div>

      <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        <div className="h-28" style={{ background: "linear-gradient(135deg, #14532d, #16a34a, #22c55e)" }} />
        <div className="px-6 pb-6">
          <div className="flex items-end justify-between -mt-10 mb-4">
            <div className="relative">
              {profile?.avatar_url
                ? <img src={profile.avatar_url} alt="" className="w-20 h-20 rounded-2xl object-cover border-4" style={{ borderColor: "var(--card)" }} />
                : <div className="w-20 h-20 rounded-2xl flex items-center justify-center text-3xl font-bold text-white border-4"
                  style={{ background: "linear-gradient(135deg, #15803d, #22c55e)", borderColor: "var(--card)" }}>
                  {profile?.full_name?.[0] ?? "P"}
                </div>}
              <Link href="/profile/edit">
                <div className="absolute -bottom-1 -right-1 w-7 h-7 rounded-xl flex items-center justify-center shadow-md"
                  style={{ backgroundColor: "var(--provider)" }}>
                  <Camera size={13} className="text-white" />
                </div>
              </Link>
            </div>
            <Link href="/profile/edit">
              <button className="px-4 py-2 rounded-xl text-sm font-semibold border"
                style={{ borderColor: "var(--border)", color: "var(--text)", backgroundColor: "transparent" }}>
                Chỉnh sửa
              </button>
            </Link>
          </div>

          {loading
            ? <><Skeleton className="h-6 w-40 mb-2" /><Skeleton className="h-4 w-56" /></>
            : <>
              <h2 className="text-xl font-bold mb-0.5" style={{ color: "var(--text)" }}>{profile?.full_name}</h2>
              {profile?.business_name && (
                <div className="flex items-center gap-1.5 mb-0.5">
                  <Truck size={14} style={{ color: "var(--muted)" }} />
                  <p className="text-sm" style={{ color: "var(--muted)" }}>{profile.business_name}</p>
                </div>
              )}
              <p className="text-sm" style={{ color: "var(--muted)" }}>{profile?.email}</p>
              <div className="flex items-center gap-2 mt-3 flex-wrap">
                <span className="text-xs px-2.5 py-1 rounded-full font-semibold"
                  style={{ backgroundColor: "var(--provider-tint)", color: "var(--provider)" }}>
                  Nhà vận chuyển
                </span>
                {profile?.vehicle_type && (
                  <span className="text-xs px-2.5 py-1 rounded-full"
                    style={{ backgroundColor: "var(--surface)", color: "var(--muted)", border: "1px solid var(--border)" }}>
                    {profile.vehicle_type}
                  </span>
                )}
                <span className="text-xs px-2.5 py-1 rounded-full font-semibold"
                  style={{ backgroundColor: isVerified ? "var(--success-tint)" : "var(--warning-tint)", color: isVerified ? "var(--success)" : "var(--warning)" }}>
                  {isVerified ? "✓ Đã xác minh" : "⚠ Chưa xác minh"}
                </span>
              </div>
            </>}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="rounded-2xl p-5 text-center" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
          <TrendingUp size={20} className="mx-auto mb-2" style={{ color: "var(--provider)" }} />
          <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>0</p>
          <p className="text-xs mt-1" style={{ color: "var(--muted)" }}>Tổng chuyến</p>
        </div>
        <div className="rounded-2xl p-5 text-center" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
          <Star size={20} className="mx-auto mb-2" fill="#f59e0b" style={{ color: "#f59e0b" }} />
          <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>{profile?.rating?.toFixed(1) ?? "—"}</p>
          <p className="text-xs mt-1" style={{ color: "var(--muted)" }}>Đánh giá TB</p>
        </div>
        <div className="rounded-2xl p-5 text-center" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
          <Truck size={20} className="mx-auto mb-2" style={{ color: "var(--primary)" }} />
          <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>0</p>
          <p className="text-xs mt-1" style={{ color: "var(--muted)" }}>Đơn đã nhận</p>
        </div>
      </div>

      <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        <div className="px-5 py-3" style={{ borderBottom: "1px solid var(--border)" }}>
          <p className="text-sm font-semibold" style={{ color: "var(--muted)" }}>Cài đặt tài khoản</p>
        </div>
        {menu.map(({ icon: Icon, label, desc, href }, i) => (
          <Link key={href} href={href}>
            <div className="flex items-center gap-4 px-5 py-4 hover:opacity-80 transition-opacity"
              style={{ borderBottom: i < menu.length - 1 ? "1px solid var(--border)" : "none" }}>
              <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: "var(--surface)" }}>
                <Icon size={18} style={{ color: "var(--muted)" }} />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium" style={{ color: "var(--text)" }}>{label}</p>
                <p className="text-xs" style={{ color: "var(--muted)" }}>{desc}</p>
              </div>
              <ChevronRight size={16} style={{ color: "var(--muted)" }} />
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
