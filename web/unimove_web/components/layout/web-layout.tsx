"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Truck, Bell, LogOut, User,
  Home, ClipboardList, ShoppingBag, CreditCard, LayoutDashboard,
  DollarSign, MessageSquare, FileText, Moon, Sun, Menu, X,
} from "lucide-react";
import { getStoredUser, logoutToHome, storeAuth, type AuthUser } from "@/lib/auth";
import { notificationsApi, customerApi, authApi } from "@/lib/api";
import { cn } from "@/lib/utils";
import { UserMenuDropdown } from "@/components/layout/user-menu-dropdown";

interface NavItem {
  href: string;
  label: string;
  icon: React.ElementType;
  badge?: number;
}

const customerNav: NavItem[] = [
  { href: "/home",          label: "Trang chủ",   icon: Home },
  { href: "/orders",        label: "Đơn hàng",    icon: ClipboardList },
  { href: "/marketplace",   label: "Chợ sinh viên", icon: ShoppingBag },
  { href: "/payments",      label: "Thanh toán",  icon: CreditCard },
  { href: "/notifications", label: "Thông báo",   icon: Bell },
];

const providerNav: NavItem[] = [
  { href: "/dashboard",  label: "Tổng quan",    icon: LayoutDashboard },
  { href: "/orders",     label: "Đơn hàng",     icon: ClipboardList },
  { href: "/earnings",   label: "Thu nhập",     icon: DollarSign },
  { href: "/messages",   label: "Thông báo",    icon: MessageSquare },
  { href: "/documents",  label: "Giấy tờ",      icon: FileText },
];

export function WebLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [unread, setUnread] = useState(0);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);

  useEffect(() => {
    const u = getStoredUser();
    setUser(u);
    setDarkMode(document.documentElement.classList.contains("dark"));

    notificationsApi.unreadCount().then(r => {
      if (r.success && r.data) setUnread((r.data as { count?: number }).count ?? 0);
    }).catch(() => {});

    if (u?.role === "customer") {
      customerApi.getMe().then(r => {
        if (r.success && r.data) {
          const profile = { ...u, ...(r.data as AuthUser) };
          setUser(profile);
          const token = localStorage.getItem("unimove_token");
          if (token) storeAuth(profile, token);
        }
      }).catch(() => {});
    } else if (u?.role === "provider") {
      authApi.getMe().then(r => {
        if (r.success && r.data) {
          const profile = { ...u, ...(r.data as AuthUser) };
          setUser(profile);
          const token = localStorage.getItem("unimove_token");
          if (token) storeAuth(profile, token);
        }
      }).catch(() => {});
    }
  }, []);

  const toggleTheme = () => {
    const isDark = document.documentElement.classList.toggle("dark");
    setDarkMode(isDark);
    localStorage.setItem("unimove-theme", isDark ? "dark" : "light");
  };

  const logout = () => logoutToHome(router);

  const nav = user?.role === "provider" ? providerNav : customerNav;
  const accentColor = user?.role === "provider" ? "var(--provider)" : "var(--primary)";
  const accentGradient = user?.role === "provider"
    ? "linear-gradient(135deg, #15803d, #22c55e)"
    : "linear-gradient(135deg, #0052ff, #4d7cff)";

  const SidebarContent = () => (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-5" style={{ borderBottom: "1px solid var(--border)" }}>
        <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: accentGradient }}>
          <Truck size={18} className="text-white" />
        </div>
        <div>
          <span className="text-base font-bold" style={{ color: "var(--text)" }}>UniMove</span>
          <p className="text-[11px]" style={{ color: "var(--muted)" }}>
            {user?.role === "provider" ? "Nhà vận chuyển" : "Khách hàng"}
          </p>
        </div>
      </div>

      {/* Nav items */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || pathname.startsWith(href + "/");
          return (
            <Link key={href} href={href} onClick={() => setSidebarOpen(false)}>
              <div
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all text-sm font-medium",
                  active ? "text-white" : "hover:opacity-80"
                )}
                style={{
                  backgroundColor: active ? accentColor : "transparent",
                  color: active ? "white" : "var(--muted)",
                }}
              >
                <Icon size={18} strokeWidth={active ? 2.5 : 1.8} />
                <span>{label}</span>
                {href === "/notifications" && unread > 0 && (
                  <span className="ml-auto text-[11px] px-1.5 py-0.5 rounded-full text-white font-bold"
                    style={{ backgroundColor: "#ef4444" }}>
                    {unread}
                  </span>
                )}
              </div>
            </Link>
          );
        })}
      </nav>

      {/* Bottom section */}
      <div className="px-3 py-4 space-y-1" style={{ borderTop: "1px solid var(--border)" }}>
        <Link href="/profile" onClick={() => setSidebarOpen(false)}>
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium hover:opacity-80 transition-all"
            style={{ color: "var(--muted)" }}>
            <User size={18} strokeWidth={1.8} />
            <span>Hồ sơ</span>
          </div>
        </Link>
        <button onClick={logout} className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium hover:opacity-80 transition-all"
          style={{ color: "var(--error)" }}>
          <LogOut size={18} strokeWidth={1.8} />
          <span>Đăng xuất</span>
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen overflow-hidden" style={{ backgroundColor: "var(--bg)" }}>
      {/* Desktop Sidebar */}
      <aside
        className="hidden lg:flex flex-col flex-shrink-0"
        style={{
          width: "var(--sidebar-width)",
          backgroundColor: "var(--nav-bg)",
          borderRight: "1px solid var(--border)",
        }}
      >
        <SidebarContent />
      </aside>

      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div className="lg:hidden fixed inset-0 z-50 flex">
          <div className="fixed inset-0 bg-black/50" onClick={() => setSidebarOpen(false)} />
          <aside className="relative w-64 flex flex-col h-full shadow-2xl animate-slide-in"
            style={{ backgroundColor: "var(--nav-bg)", borderRight: "1px solid var(--border)" }}>
            <button onClick={() => setSidebarOpen(false)} className="absolute top-4 right-4 p-1.5 rounded-lg"
              style={{ color: "var(--muted)" }}>
              <X size={18} />
            </button>
            <SidebarContent />
          </aside>
        </div>
      )}

      {/* Main area — không overflow-hidden để dropdown không bị cắt */}
      <div className="flex-1 flex flex-col min-w-0 min-h-0">
        {/* Top Header — luôn nổi trên nội dung trang */}
        <header
          className="sticky top-0 z-[200] isolate flex items-center justify-between px-6 shrink-0"
          style={{
            height: "var(--header-height)",
            backgroundColor: "var(--nav-bg)",
            borderBottom: "1px solid var(--border)",
            boxShadow: "0 1px 0 var(--border)",
          }}
        >
          {/* Left: hamburger (mobile) + breadcrumb */}
          <div className="flex items-center gap-3">
            <button onClick={() => setSidebarOpen(true)} className="lg:hidden p-2 rounded-lg"
              style={{ color: "var(--muted)" }}>
              <Menu size={20} />
            </button>
            <PageTitle pathname={pathname} nav={nav} />
          </div>

          {/* Right: theme toggle + notifications + user */}
          <div className="flex items-center gap-2">
            {/* Theme toggle */}
            <button onClick={toggleTheme}
              className="w-9 h-9 rounded-xl flex items-center justify-center transition-colors"
              style={{ backgroundColor: "var(--surface)", color: "var(--muted)" }}>
              {darkMode ? <Sun size={16} /> : <Moon size={16} />}
            </button>

            {/* Notifications */}
            <Link href={user?.role === "provider" ? "/messages" : "/notifications"}>
              <button className="relative w-9 h-9 rounded-xl flex items-center justify-center"
                style={{ backgroundColor: "var(--surface)", color: "var(--muted)" }}>
                <Bell size={16} />
                {unread > 0 && (
                  <span className="absolute -top-1 -right-1 w-4.5 h-4.5 rounded-full text-white text-[9px] font-bold flex items-center justify-center"
                    style={{ width: "18px", height: "18px", backgroundColor: "#ef4444" }}>
                    {unread > 9 ? "9+" : unread}
                  </span>
                )}
              </button>
            </Link>

            <UserMenuDropdown user={user} accentGradient={accentGradient} />
          </div>
        </header>

        {/* Page content — z-0 để không đè header/dropdown */}
        <main className="relative z-0 flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}

function PageTitle({ pathname, nav }: { pathname: string; nav: NavItem[] }) {
  const current = nav.find(n => pathname === n.href || pathname.startsWith(n.href + "/"));
  if (!current) return <span className="text-base font-semibold" style={{ color: "var(--text)" }}>UniMove</span>;
  const Icon = current.icon;
  return (
    <div className="flex items-center gap-2">
      <Icon size={18} style={{ color: "var(--muted)" }} />
      <span className="text-base font-semibold" style={{ color: "var(--text)" }}>{current.label}</span>
    </div>
  );
}
