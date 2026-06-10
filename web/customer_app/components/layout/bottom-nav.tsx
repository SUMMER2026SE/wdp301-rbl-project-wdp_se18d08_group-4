"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, ShoppingBag, ClipboardList, Bell, User } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/home", label: "Trang chủ", icon: Home },
  { href: "/marketplace", label: "Chợ SV", icon: ShoppingBag },
  { href: "/orders", label: "Đơn hàng", icon: ClipboardList },
  { href: "/notifications", label: "Thông báo", icon: Bell },
  { href: "/profile", label: "Hồ sơ", icon: User },
];

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 flex items-stretch"
      style={{
        backgroundColor: "var(--nav-bg)",
        borderTop: "1px solid var(--nav-border)",
        boxShadow: "var(--nav-shadow)",
        height: "64px",
        paddingBottom: "env(safe-area-inset-bottom)",
      }}
    >
      {navItems.map(({ href, label, icon: Icon }) => {
        const active = pathname === href || pathname.startsWith(href + "/");
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex flex-1 flex-col items-center justify-center gap-1 transition-colors",
              active ? "text-[var(--primary)]" : "text-[var(--muted)]"
            )}
          >
            <div className="relative">
              <Icon size={22} strokeWidth={active ? 2.5 : 1.8} />
              {href === "/notifications" && (
                <NotificationDot />
              )}
            </div>
            <span className={cn("text-[10px] font-medium", active ? "font-bold" : "")}>
              {label}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}

function NotificationDot() {
  return (
    <span className="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-red-500 border-2 border-[var(--nav-bg)]" />
  );
}
