"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Truck, Package, ShoppingBag, DollarSign,
  Bell, Search, ChevronRight, MapPin, Clock,
  MessageCircle, Star, Zap, Shield
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { customerApi, ordersApi, notificationsApi } from "@/lib/api";
import { getStoredUser, type User } from "@/lib/auth";
import { formatVND, getOrderStatusLabel, getOrderStatusColor, timeAgo } from "@/lib/utils";

interface Order {
  id: string;
  status: string;
  service_type: string;
  pickup_address: string;
  dropoff_address: string;
  estimated_price?: number;
  created_at: string;
  provider?: { full_name: string; rating: number; phone: string };
}

export default function HomePage() {
  const [user, setUser] = useState<User | null>(null);
  const [orders, setOrders] = useState<Order[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const stored = getStoredUser();
    setUser(stored);

    const fetchData = async () => {
      try {
        const [profileRes, ordersRes, notifRes] = await Promise.allSettled([
          customerApi.getMe(),
          ordersApi.getOrders({ status: "active", page: 1 }),
          notificationsApi.getUnreadCount(),
        ]);

        if (profileRes.status === "fulfilled" && profileRes.value.success) {
          const profileData = profileRes.value.data as User;
          setUser(profileData);
        }
        if (ordersRes.status === "fulfilled" && ordersRes.value.success) {
          const data = ordersRes.value.data as { orders?: Order[] };
          setOrders((data?.orders ?? []).slice(0, 3));
        }
        if (notifRes.status === "fulfilled" && notifRes.value.success) {
          const countData = notifRes.value.data as { count?: number };
          setUnreadCount(countData?.count ?? 0);
        }
      } catch {
        // silent
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const greeting = () => {
    const h = new Date().getHours();
    if (h < 12) return "Chào buổi sáng";
    if (h < 18) return "Chào buổi chiều";
    return "Chào buổi tối";
  };

  const services = [
    { label: "Báo giá", href: "/booking/location", icon: DollarSign, color: "#3b82f6", bg: "#dbeafe" },
    { label: "Khuân vác", href: "/booking/labor", icon: Package, color: "#16a34a", bg: "#dcfce7" },
    { label: "Chợ SV", href: "/marketplace", icon: ShoppingBag, color: "#d97706", bg: "#fef3c7" },
    { label: "Phụ phí", href: "/reference-prices", icon: Shield, color: "#9333ea", bg: "#f3e8ff" },
  ];

  const activeOrders = orders.filter(
    (o) => !["completed", "cancelled"].includes(o.status)
  );

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      {/* ── Header ── */}
      <div
        className="px-4 pt-12 pb-6"
        style={{ background: "linear-gradient(160deg, var(--gradient-from) 0%, var(--gradient-to) 100%)" }}
      >
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-blue-100 text-sm">{greeting()},</p>
            {loading ? (
              <Skeleton className="h-7 w-32 mt-1" style={{ background: "rgba(255,255,255,0.2)" }} />
            ) : (
              <h1 className="text-2xl font-bold text-white">
                {user?.full_name?.split(" ").slice(-1)[0] ?? "Bạn"} 👋
              </h1>
            )}
          </div>
          <Link href="/notifications" className="relative p-2 rounded-full" style={{ background: "rgba(255,255,255,0.2)" }}>
            <Bell size={22} className="text-white" />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-red-500 border-2 border-blue-600 text-white text-[10px] flex items-center justify-center font-bold">
                {unreadCount > 9 ? "9+" : unreadCount}
              </span>
            )}
          </Link>
        </div>

        {/* Search bar */}
        <Link
          href="/booking/location"
          className="flex items-center gap-3 px-4 py-3 rounded-2xl shadow-sm"
          style={{ backgroundColor: "rgba(255,255,255,0.95)", color: "var(--muted)" }}
        >
          <Search size={18} />
          <span className="text-sm">Bạn muốn chuyển trọ đi đâu?</span>
        </Link>
      </div>

      <div className="px-4 -mt-3 space-y-5 pb-4">
        {/* ── Main CTA Card ── */}
        <Link href="/booking/location">
          <div
            className="rounded-3xl p-5 shadow-lg overflow-hidden relative"
            style={{ background: "linear-gradient(135deg, #1e3a8a 0%, #1d4ed8 50%, #3b82f6 100%)" }}
          >
            <div className="relative z-10">
              <div className="flex items-center gap-2 mb-2">
                <Zap size={16} className="text-yellow-300" />
                <span className="text-yellow-300 text-xs font-bold uppercase tracking-wider">Dịch vụ chính</span>
              </div>
              <h2 className="text-2xl font-bold text-white mb-1">Chuyển trọ thông minh</h2>
              <p className="text-blue-100 text-sm mb-4">Báo giá minh bạch · Không lo phụ phí ẩn</p>
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/20 text-white text-sm font-semibold">
                Đặt ngay <ChevronRight size={16} />
              </div>
            </div>
            <Truck className="absolute -right-4 -bottom-2 opacity-10 text-white" size={140} />
          </div>
        </Link>

        {/* ── Quick services ── */}
        <div>
          <h3 className="text-sm font-bold mb-3" style={{ color: "var(--muted)" }}>DỊCH VỤ KHÁC</h3>
          <div className="grid grid-cols-4 gap-3">
            {services.map(({ label, href, icon: Icon, color, bg }) => (
              <Link
                key={href}
                href={href}
                className="flex flex-col items-center gap-2 p-3 rounded-2xl text-center transition-transform active:scale-95"
                style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}
              >
                <div className="w-11 h-11 rounded-xl flex items-center justify-center" style={{ backgroundColor: bg }}>
                  <Icon size={22} style={{ color }} />
                </div>
                <span className="text-[11px] font-semibold leading-tight" style={{ color: "var(--text)" }}>{label}</span>
              </Link>
            ))}
          </div>
        </div>

        {/* ── Flash Sale Banner ── */}
        <Link href="/reference-prices">
          <div
            className="rounded-2xl p-4 flex items-center justify-between"
            style={{ background: "linear-gradient(135deg, #f59e0b, #d97706)" }}
          >
            <div>
              <p className="text-white text-xs font-bold uppercase tracking-wider mb-1">⚡ Bảng phụ phí</p>
              <p className="text-white/90 text-sm font-medium">Xem bảng giá tham khảo</p>
            </div>
            <ChevronRight size={20} className="text-white opacity-80" />
          </div>
        </Link>

        {/* ── Active Orders ── */}
        {activeOrders.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-bold" style={{ color: "var(--text)" }}>Đơn hàng đang thực hiện</h3>
              <Link href="/orders" className="text-sm font-medium" style={{ color: "var(--primary)" }}>
                Xem tất cả
              </Link>
            </div>
            <div className="space-y-3">
              {activeOrders.map((order) => (
                <ActiveOrderCard key={order.id} order={order} />
              ))}
            </div>
          </div>
        )}

        {/* ── Recent Orders ── */}
        {orders.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-bold" style={{ color: "var(--text)" }}>Lịch sử gần đây</h3>
              <Link href="/orders" className="text-sm font-medium" style={{ color: "var(--primary)" }}>
                Xem tất cả
              </Link>
            </div>
            <div className="space-y-3">
              {orders.slice(0, 3).map((order) => (
                <RecentOrderCard key={order.id} order={order} />
              ))}
            </div>
          </div>
        )}

        {/* Empty state if no orders */}
        {!loading && orders.length === 0 && (
          <Card className="p-6 text-center">
            <Truck size={40} className="mx-auto mb-3 opacity-30" style={{ color: "var(--primary)" }} />
            <p className="font-semibold mb-1" style={{ color: "var(--text)" }}>Chưa có đơn hàng nào</p>
            <p className="text-sm mb-4" style={{ color: "var(--muted)" }}>Đặt dịch vụ chuyển trọ đầu tiên của bạn!</p>
            <Link href="/booking/location">
              <div
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl text-white text-sm font-semibold"
                style={{ background: "linear-gradient(135deg, var(--gradient-from), var(--gradient-to))" }}
              >
                Đặt ngay <ChevronRight size={16} />
              </div>
            </Link>
          </Card>
        )}
      </div>
    </div>
  );
}

function ActiveOrderCard({ order }: { order: Order }) {
  const statusColor = getOrderStatusColor(order.status);

  return (
    <Link href={`/orders/${order.id}`}>
      <Card className="p-4 hover:shadow-md transition-shadow">
        <div className="flex items-start justify-between mb-3">
          <div>
            <Badge style={{ backgroundColor: statusColor + "22", color: statusColor, border: `1px solid ${statusColor}44` }}>
              {getOrderStatusLabel(order.status)}
            </Badge>
          </div>
          <span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(order.created_at)}</span>
        </div>

        <div className="space-y-2 mb-3">
          <div className="flex items-start gap-2">
            <div className="w-2 h-2 rounded-full mt-1.5 shrink-0" style={{ backgroundColor: "var(--primary)" }} />
            <span className="text-sm text-ellipsis overflow-hidden line-clamp-1" style={{ color: "var(--text)" }}>
              {order.pickup_address}
            </span>
          </div>
          <div className="flex items-start gap-2">
            <MapPin size={8} className="mt-1.5 shrink-0" style={{ color: "var(--success)" }} />
            <span className="text-sm text-ellipsis overflow-hidden line-clamp-1" style={{ color: "var(--text)" }}>
              {order.dropoff_address}
            </span>
          </div>
        </div>

        {order.provider && (
          <div
            className="flex items-center justify-between pt-3"
            style={{ borderTop: "1px solid var(--border)" }}
          >
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-full flex items-center justify-center text-white text-xs font-bold"
                style={{ backgroundColor: "var(--primary)" }}>
                {order.provider.full_name[0]}
              </div>
              <span className="text-sm font-medium" style={{ color: "var(--text)" }}>{order.provider.full_name}</span>
              <div className="flex items-center gap-0.5">
                <Star size={11} style={{ color: "#f59e0b" }} fill="#f59e0b" />
                <span className="text-xs" style={{ color: "var(--muted)" }}>{order.provider.rating?.toFixed(1)}</span>
              </div>
            </div>
            <a
              href={`tel:${order.provider.phone}`}
              onClick={(e) => e.stopPropagation()}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium"
              style={{ backgroundColor: "var(--primary-tint)", color: "var(--primary)" }}
            >
              <MessageCircle size={14} /> Chat
            </a>
          </div>
        )}
      </Card>
    </Link>
  );
}

function RecentOrderCard({ order }: { order: Order }) {
  const statusColor = getOrderStatusColor(order.status);

  return (
    <Link href={`/orders/${order.id}`}>
      <Card className="p-4 hover:shadow-md transition-shadow">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center"
              style={{ backgroundColor: "var(--surface)" }}
            >
              <Truck size={18} style={{ color: "var(--primary)" }} />
            </div>
            <div>
              <p className="text-sm font-medium line-clamp-1" style={{ color: "var(--text)" }}>
                {order.dropoff_address}
              </p>
              <div className="flex items-center gap-2 mt-0.5">
                <Clock size={11} style={{ color: "var(--muted)" }} />
                <span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(order.created_at)}</span>
              </div>
            </div>
          </div>
          <div className="text-right">
            <Badge style={{ backgroundColor: statusColor + "22", color: statusColor, border: `1px solid ${statusColor}44` }}>
              {getOrderStatusLabel(order.status)}
            </Badge>
            {order.estimated_price && (
              <p className="text-xs mt-1 font-semibold" style={{ color: "var(--text)" }}>
                {formatVND(order.estimated_price)}
              </p>
            )}
          </div>
        </div>
      </Card>
    </Link>
  );
}
