"use client";

import React, { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Truck, CheckCircle, XCircle, Star, DollarSign, Package, Clock, MapPin, AlertTriangle, ChevronRight, TrendingUp, Users } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ordersApi } from "@/lib/api";
import { getStoredUser, type AuthUser } from "@/lib/auth";
import { formatVND, getOrderStatusLabel, getOrderStatusColor, timeAgo } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface Order { id: string; status: string; pickup_address: string; dropoff_address: string; estimated_price?: number; created_at: string; customer?: { full_name: string; phone: string }; }

export default function ProviderDashboardPage() {
  const { toast } = useToast();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [hydrated, setHydrated] = useState(false);
  const [pending, setPending] = useState<Order[]>([]);
  const [active, setActive] = useState<Order[]>([]);
  const [completed, setCompleted] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [pRes, aRes, cRes] = await Promise.allSettled([
        ordersApi.list({ status: "pending" }),
        ordersApi.list({ status: "accepted,picking_up,in_progress" }),
        ordersApi.list({ status: "completed" }),
      ]);
      const getData = (res: PromiseSettledResult<{ success: boolean; data?: unknown }>) => {
        if (res.status === "fulfilled" && res.value.success) {
          const d = res.value.data as { orders?: Order[] } | Order[];
          return Array.isArray(d) ? d : (d?.orders ?? []);
        }
        return [];
      };
      setPending(getData(pRes).slice(0, 5));
      setActive(getData(aRes).slice(0, 3));
      setCompleted(getData(cRes));
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    setUser(getStoredUser());
    setHydrated(true);
  }, []);

  const totalEarnings = completed.reduce((s, o) => s + (o.estimated_price ?? 0), 0);

  const respond = async (id: string, action: "accept" | "reject") => {
    try {
      await ordersApi.respond(id, action);
      toast(action === "accept" ? "Đã chấp nhận đơn!" : "Đã từ chối đơn", action === "accept" ? "success" : "info");
      load();
    } catch { toast("Thử lại sau", "error"); }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* KYC warning */}
      {hydrated && user && !user.is_verified && (
        <Link href="/documents">
          <div className="flex items-center gap-3 px-5 py-3.5 rounded-2xl cursor-pointer hover:opacity-90 transition-opacity"
            style={{ backgroundColor: "var(--warning-tint)", border: "1px solid var(--warning)" }}>
            <AlertTriangle size={18} style={{ color: "var(--warning)" }} />
            <p className="text-sm font-medium flex-1" style={{ color: "var(--warning)" }}>
              Tài khoản chưa được xác minh. Upload giấy tờ để nhận đơn hàng.
            </p>
            <ChevronRight size={16} style={{ color: "var(--warning)" }} />
          </div>
        </Link>
      )}

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Đơn chờ xác nhận" value={pending.length.toString()} icon={<Clock size={20} />} color="var(--warning)" bg="var(--warning-tint)" />
        <StatCard label="Đang thực hiện" value={active.length.toString()} icon={<Truck size={20} />} color="var(--primary)" bg="var(--primary-tint)" />
        <StatCard label="Đã hoàn thành" value={completed.length.toString()} icon={<TrendingUp size={20} />} color="var(--success)" bg="var(--success-tint)" />
        <StatCard label="Tổng thu nhập" value={formatVND(totalEarnings * 0.9)} icon={<DollarSign size={20} />} color="var(--provider)" bg="var(--provider-tint)" />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Pending orders - needs attention */}
        <div className="xl:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <h2 className="text-base font-bold" style={{ color: "var(--text)" }}>Đơn hàng chờ xác nhận</h2>
              {pending.length > 0 && (
                <span className="px-2 py-0.5 rounded-full text-xs text-white font-bold" style={{ backgroundColor: "var(--warning)" }}>
                  {pending.length}
                </span>
              )}
            </div>
            <button onClick={load} className="text-sm font-medium" style={{ color: "var(--provider)" }}>Làm mới</button>
          </div>

          <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
            {loading ? (
              <div className="p-5 space-y-4">
                {[1, 2].map(i => <Skeleton key={i} className="h-20 w-full" />)}
              </div>
            ) : pending.length === 0 ? (
              <div className="py-12 text-center">
                <Package size={40} className="mx-auto mb-3 opacity-20" style={{ color: "var(--text)" }} />
                <p className="font-semibold" style={{ color: "var(--text)" }}>Không có đơn mới</p>
                <p className="text-sm mt-1" style={{ color: "var(--muted)" }}>Đơn hàng mới sẽ xuất hiện ở đây</p>
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>Điểm đến</th>
                    <th>Khách hàng</th>
                    <th>Giá ước tính</th>
                    <th>Thời gian</th>
                    <th>Hành động</th>
                  </tr>
                </thead>
                <tbody>
                  {pending.map(o => (
                    <tr key={o.id}>
                      <td>
                        <div className="max-w-[200px]">
                          <p className="text-sm font-medium truncate">{o.dropoff_address}</p>
                          <p className="text-xs truncate" style={{ color: "var(--muted)" }}>{o.pickup_address}</p>
                        </div>
                      </td>
                      <td>
                        {o.customer ? (
                          <div>
                            <p className="text-sm">{o.customer.full_name}</p>
                            <p className="text-xs" style={{ color: "var(--muted)" }}>{o.customer.phone}</p>
                          </div>
                        ) : <span style={{ color: "var(--muted)" }}>—</span>}
                      </td>
                      <td>
                        <span className="text-sm font-semibold" style={{ color: "var(--success)" }}>
                          {o.estimated_price ? formatVND(o.estimated_price) : "Chờ báo giá"}
                        </span>
                      </td>
                      <td><span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(o.created_at)}</span></td>
                      <td>
                        <div className="flex items-center gap-2">
                          <button onClick={() => respond(o.id, "reject")}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold"
                            style={{ color: "var(--error)", backgroundColor: "var(--error-tint)", border: "1px solid var(--error)" + "44" }}>
                            Từ chối
                          </button>
                          <button onClick={() => respond(o.id, "accept")}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white"
                            style={{ backgroundColor: "var(--success)" }}>
                            Chấp nhận
                          </button>
                          <Link href={`/orders/${o.id}`}>
                            <button className="px-3 py-1.5 rounded-lg text-xs font-semibold"
                              style={{ color: "var(--primary)", backgroundColor: "var(--primary-tint)" }}>
                              Chi tiết
                            </button>
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Active + quick actions */}
        <div className="space-y-5">
          {/* Active orders */}
          <div>
            <h2 className="text-base font-bold mb-3" style={{ color: "var(--text)" }}>Đang thực hiện</h2>
            {active.length === 0 ? (
              <div className="rounded-2xl p-4 text-center" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                <p className="text-sm" style={{ color: "var(--muted)" }}>Không có đơn đang thực hiện</p>
              </div>
            ) : active.map(o => {
              const sc = getOrderStatusColor(o.status);
              return (
                <Link key={o.id} href={`/orders/${o.id}`}>
                  <div className="rounded-2xl p-4 mb-2 hover:shadow-md transition-shadow cursor-pointer" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)", borderLeft: `3px solid ${sc}` }}>
                    <div className="flex items-start justify-between mb-2">
                      <Badge style={{ backgroundColor: sc + "22", color: sc, border: `1px solid ${sc}44` }}>{getOrderStatusLabel(o.status)}</Badge>
                      <span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(o.created_at)}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin size={13} style={{ color: "var(--success)" }} />
                      <p className="text-sm truncate" style={{ color: "var(--text)" }}>{o.dropoff_address}</p>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>

          {/* Quick links */}
          <div>
            <h2 className="text-base font-bold mb-3" style={{ color: "var(--text)" }}>Truy cập nhanh</h2>
            <div className="space-y-2">
              {[
                { href: "/earnings", label: "Thu nhập của tôi", icon: DollarSign, color: "var(--success)", bg: "var(--success-tint)" },
                { href: "/documents", label: hydrated && user?.is_verified ? "Đã xác minh ✓" : "Upload giấy tờ", icon: Users, color: hydrated && user?.is_verified ? "var(--success)" : "var(--warning)", bg: hydrated && user?.is_verified ? "var(--success-tint)" : "var(--warning-tint)" },
                { href: "/orders", label: "Tất cả đơn hàng", icon: Package, color: "var(--primary)", bg: "var(--primary-tint)" },
              ].map(item => (
                <Link key={item.href} href={item.href}>
                  <div className="flex items-center gap-3 p-3.5 rounded-xl hover:shadow-sm transition-all"
                    style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                    <div className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
                      style={{ backgroundColor: item.bg, color: item.color }}>
                      <item.icon size={18} />
                    </div>
                    <span className="text-sm font-medium flex-1" style={{ color: "var(--text)" }}>{item.label}</span>
                    <ChevronRight size={15} style={{ color: "var(--muted)" }} />
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon, color, bg }: { label: string; value: string; icon: React.ReactNode; color: string; bg: string }) {
  return (
    <div className="rounded-2xl p-5" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
      <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-3" style={{ backgroundColor: bg, color }}>{icon}</div>
      <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>{value}</p>
      <p className="text-xs mt-1" style={{ color: "var(--muted)" }}>{label}</p>
    </div>
  );
}
