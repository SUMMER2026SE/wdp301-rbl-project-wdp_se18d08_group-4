"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Truck, Package, ShoppingBag, DollarSign, Shield,
  ChevronRight, MapPin, Clock, Star, TrendingUp, Zap, Plus
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { customerApi, ordersApi, notificationsApi } from "@/lib/api";
import { getStoredUser, type AuthUser } from "@/lib/auth";
import { formatVND, getOrderStatusLabel, getOrderStatusColor, timeAgo } from "@/lib/utils";

interface Order {
  id: string; status: string;
  pickup_address: string; dropoff_address: string;
  estimated_price?: number; final_price?: number; created_at: string;
  provider?: { full_name: string; rating: number };
}

export default function CustomerHomePage() {
  const [user, setUser] = useState<AuthUser | null>(getStoredUser());
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const [profileRes, ordersRes] = await Promise.allSettled([
          customerApi.getMe(),
          ordersApi.list({ page: 1 }),
        ]);
        if (profileRes.status === "fulfilled" && profileRes.value.success)
          setUser(profileRes.value.data as AuthUser);
        if (ordersRes.status === "fulfilled" && ordersRes.value.success) {
          const d = ordersRes.value.data as { orders?: Order[] } | Order[];
          setOrders((Array.isArray(d) ? d : (d?.orders ?? [])).slice(0, 5));
        }
      } finally { setLoading(false); }
    })();
  }, []);

  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Chào buổi sáng" : hour < 18 ? "Chào buổi chiều" : "Chào buổi tối";
  const activeOrders = orders.filter(o => !["completed", "cancelled"].includes(o.status));

  const services = [
    { label: "Chuyển trọ", desc: "Báo giá minh bạch", href: "/booking/location", icon: Truck, color: "#3b82f6", bg: "#dbeafe" },
    { label: "Khuân vác", desc: "Theo giờ linh hoạt", href: "/booking/location?type=labor", icon: Package, color: "#16a34a", bg: "#dcfce7" },
    { label: "Chợ sinh viên", desc: "Mua bán đồ cũ", href: "/marketplace", icon: ShoppingBag, color: "#d97706", bg: "#fef3c7" },
    { label: "Bảng phụ phí", desc: "Giá tham khảo", href: "/reference-prices", icon: Shield, color: "#9333ea", bg: "#f3e8ff" },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Welcome banner */}
      <div className="rounded-2xl overflow-hidden relative" style={{ background: "linear-gradient(135deg, #1e3a8a 0%, #1d4ed8 50%, #3b82f6 100%)", minHeight: "140px" }}>
        <div className="px-8 py-7">
          <p className="text-blue-100 text-sm mb-1">{greeting},</p>
          {loading
            ? <div className="h-8 w-48 rounded-lg mb-1" style={{ background: "rgba(255,255,255,0.2)" }} />
            : <h1 className="text-2xl font-bold text-white mb-1">{user?.full_name} 👋</h1>
          }
          <p className="text-blue-100 text-sm">Bạn cần chuyển trọ hôm nay?</p>
          <Link href="/booking/location" className="inline-flex items-center gap-2 mt-4 px-5 py-2.5 rounded-xl bg-white text-sm font-semibold" style={{ color: "var(--primary)" }}>
            <Zap size={16} /> Đặt dịch vụ ngay
          </Link>
        </div>
        <Truck className="absolute -right-4 top-1/2 -translate-y-1/2 opacity-10 text-white" size={160} />
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Đơn đang thực hiện" value={activeOrders.length.toString()} icon={<Truck size={20} />} color="var(--primary)" bg="var(--primary-tint)" />
        <StatCard label="Đơn hoàn thành" value={orders.filter(o => o.status === "completed").length.toString()} icon={<TrendingUp size={20} />} color="var(--success)" bg="var(--success-tint)" />
        <StatCard label="Điểm thưởng" value={(user?.loyalty_points ?? 0).toString()} icon={<Star size={20} />} color="#d97706" bg="#fef3c7" />
        <StatCard label="Đang chờ báo giá" value={orders.filter(o => o.status === "pending").length.toString()} icon={<Clock size={20} />} color="var(--warning)" bg="var(--warning-tint)" />
      </div>

      {/* Main content grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Services */}
        <div className="xl:col-span-1">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-bold" style={{ color: "var(--text)" }}>Dịch vụ</h2>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {services.map(({ label, desc, href, icon: Icon, color, bg }) => (
              <Link key={href} href={href}>
                <div className="p-4 rounded-2xl hover:shadow-md transition-all cursor-pointer group"
                  style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                  <div className="w-11 h-11 rounded-xl flex items-center justify-center mb-3" style={{ backgroundColor: bg }}>
                    <Icon size={22} style={{ color }} />
                  </div>
                  <p className="text-sm font-bold" style={{ color: "var(--text)" }}>{label}</p>
                  <p className="text-xs mt-0.5" style={{ color: "var(--muted)" }}>{desc}</p>
                </div>
              </Link>
            ))}
          </div>

          {/* Promo banner */}
          <Link href="/reference-prices" className="block mt-3">
            <div className="p-4 rounded-2xl flex items-center justify-between" style={{ background: "linear-gradient(135deg, #f59e0b, #d97706)" }}>
              <div>
                <p className="text-white text-xs font-bold uppercase tracking-wide">⚡ Giá tham khảo</p>
                <p className="text-white/90 text-sm font-medium mt-0.5">Xem bảng phụ phí</p>
              </div>
              <ChevronRight size={18} className="text-white opacity-80" />
            </div>
          </Link>
        </div>

        {/* Recent orders */}
        <div className="xl:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-bold" style={{ color: "var(--text)" }}>Đơn hàng gần đây</h2>
            <Link href="/orders" className="text-sm font-medium flex items-center gap-1 hover:underline" style={{ color: "var(--primary)" }}>
              Xem tất cả <ChevronRight size={14} />
            </Link>
          </div>

          <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
            {loading ? (
              <div className="p-5 space-y-4">
                {[1, 2, 3].map(i => (
                  <div key={i} className="flex gap-3">
                    <Skeleton className="w-10 h-10 rounded-xl shrink-0" />
                    <div className="flex-1 space-y-2">
                      <Skeleton className="h-4 w-2/3" />
                      <Skeleton className="h-3 w-1/2" />
                    </div>
                    <Skeleton className="h-6 w-20 rounded-full" />
                  </div>
                ))}
              </div>
            ) : orders.length === 0 ? (
              <div className="py-16 text-center">
                <Truck size={48} className="mx-auto mb-3 opacity-20" style={{ color: "var(--muted)" }} />
                <p className="font-semibold mb-1" style={{ color: "var(--text)" }}>Chưa có đơn hàng</p>
                <p className="text-sm mb-4" style={{ color: "var(--muted)" }}>Đặt dịch vụ đầu tiên của bạn!</p>
                <Link href="/booking/location">
                  <button className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl text-white text-sm font-semibold"
                    style={{ background: "linear-gradient(135deg, #1d4ed8, #3b82f6)" }}>
                    <Plus size={16} /> Đặt ngay
                  </button>
                </Link>
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>Điểm đến</th>
                    <th>Nhà xe</th>
                    <th>Giá</th>
                    <th>Trạng thái</th>
                    <th>Thời gian</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {orders.map(order => {
                    const sc = getOrderStatusColor(order.status);
                    const price = order.final_price ?? order.estimated_price;
                    return (
                      <tr key={order.id}>
                        <td>
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: "var(--primary-tint)" }}>
                              <MapPin size={14} style={{ color: "var(--primary)" }} />
                            </div>
                            <span className="text-sm max-w-[180px] truncate">{order.dropoff_address}</span>
                          </div>
                        </td>
                        <td>
                          {order.provider ? (
                            <div className="flex items-center gap-1.5">
                              <div className="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center text-white text-[10px] font-bold">
                                {order.provider.full_name[0]}
                              </div>
                              <span className="text-sm">{order.provider.full_name}</span>
                            </div>
                          ) : <span className="text-sm" style={{ color: "var(--muted)" }}>—</span>}
                        </td>
                        <td>
                          <span className="text-sm font-semibold">{price ? formatVND(price) : "—"}</span>
                        </td>
                        <td>
                          <Badge style={{ backgroundColor: sc + "22", color: sc, border: `1px solid ${sc}44` }}>
                            {getOrderStatusLabel(order.status)}
                          </Badge>
                        </td>
                        <td>
                          <span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(order.created_at)}</span>
                        </td>
                        <td>
                          <Link href={`/orders/${order.id}`}>
                            <button className="text-xs font-medium hover:underline" style={{ color: "var(--primary)" }}>
                              Chi tiết
                            </button>
                          </Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon, color, bg }: { label: string; value: string; icon: React.ReactNode; color: string; bg: string }) {
  return (
    <div className="rounded-2xl p-5" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
      <div className="flex items-center justify-between mb-3">
        <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ backgroundColor: bg, color }}>
          {icon}
        </div>
      </div>
      <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>{value}</p>
      <p className="text-xs mt-1" style={{ color: "var(--muted)" }}>{label}</p>
    </div>
  );
}
