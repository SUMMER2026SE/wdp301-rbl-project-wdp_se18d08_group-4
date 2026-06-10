"use client";

import React, { useEffect, useState } from "react";
import { DollarSign, TrendingUp, Package, Star, RefreshCw, ArrowUpRight } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { ordersApi } from "@/lib/api";
import { formatVND, formatDate } from "@/lib/utils";

interface Completed { id: string; final_price?: number; estimated_price?: number; created_at: string; dropoff_address: string; }

export default function EarningsPage() {
  const [orders, setOrders] = useState<Completed[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const r = await ordersApi.list({ status: "completed" });
      if (r.success && r.data) {
        const d = r.data as { orders?: Completed[] } | Completed[];
        setOrders(Array.isArray(d) ? d : (d?.orders ?? []));
      }
    } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const total = orders.reduce((s, o) => s + (o.final_price ?? o.estimated_price ?? 0), 0);
  const net = total * 0.9;
  const fee = total * 0.1;
  const avg = orders.length > 0 ? Math.round(total / orders.length) : 0;

  const byMonth: Record<string, { total: number; count: number }> = {};
  orders.forEach(o => {
    const m = new Date(o.created_at).toLocaleString("vi-VN", { month: "long", year: "numeric" });
    if (!byMonth[m]) byMonth[m] = { total: 0, count: 0 };
    byMonth[m].total += (o.final_price ?? o.estimated_price ?? 0);
    byMonth[m].count++;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Thu nhập</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>Tổng quan doanh thu và lịch sử giao dịch</p>
        </div>
        <button onClick={load} className="p-2.5 rounded-xl border" style={{ borderColor: "var(--border)", color: "var(--muted)", backgroundColor: "var(--card)" }}>
          <RefreshCw size={16} />
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="rounded-2xl p-5 lg:col-span-2" style={{ background: "linear-gradient(135deg, #14532d, #16a34a)", border: "none" }}>
          <div className="flex items-center gap-2 mb-3"><DollarSign size={18} className="text-green-100" /><p className="text-green-100 text-sm">Tổng doanh thu</p></div>
          {loading ? <Skeleton className="h-9 w-36 mb-1" style={{ background: "rgba(255,255,255,0.2)" }} /> : <p className="text-3xl font-bold text-white">{formatVND(total)}</p>}
          <div className="grid grid-cols-2 gap-4 mt-4">
            <div><p className="text-green-100 text-xs mb-0.5">Thực nhận (90%)</p><p className="text-xl font-bold text-white">{formatVND(net)}</p></div>
            <div><p className="text-green-100 text-xs mb-0.5">Phí nền tảng (10%)</p><p className="text-xl font-bold text-yellow-200">{formatVND(fee)}</p></div>
          </div>
        </div>
        <div className="rounded-2xl p-5" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
          <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-3" style={{ backgroundColor: "var(--primary-tint)" }}>
            <Package size={20} style={{ color: "var(--primary)" }} />
          </div>
          <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>{orders.length}</p>
          <p className="text-xs" style={{ color: "var(--muted)" }}>Tổng chuyến hoàn thành</p>
        </div>
        <div className="rounded-2xl p-5" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
          <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-3" style={{ backgroundColor: "var(--warning-tint)" }}>
            <TrendingUp size={20} style={{ color: "var(--warning)" }} />
          </div>
          <p className="text-2xl font-bold" style={{ color: "var(--text)" }}>{formatVND(avg)}</p>
          <p className="text-xs" style={{ color: "var(--muted)" }}>Trung bình/chuyến</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Monthly breakdown */}
        {Object.keys(byMonth).length > 0 && (
          <div className="lg:col-span-1">
            <h3 className="font-semibold mb-3" style={{ color: "var(--text)" }}>Thu nhập theo tháng</h3>
            <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
              {Object.entries(byMonth).map(([month, data], i, arr) => (
                <div key={month} className="flex items-center justify-between px-4 py-3"
                  style={{ borderBottom: i < arr.length - 1 ? "1px solid var(--border)" : "none" }}>
                  <div>
                    <p className="text-sm font-medium" style={{ color: "var(--text)" }}>{month}</p>
                    <p className="text-xs" style={{ color: "var(--muted)" }}>{data.count} chuyến</p>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <ArrowUpRight size={14} style={{ color: "var(--success)" }} />
                    <span className="font-bold text-sm" style={{ color: "var(--success)" }}>{formatVND(data.total)}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Transaction history */}
        <div className="lg:col-span-2">
          <h3 className="font-semibold mb-3" style={{ color: "var(--text)" }}>Lịch sử giao dịch</h3>
          <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
            {loading ? (
              <div className="p-5 space-y-3">{[1, 2, 3].map(i => <Skeleton key={i} className="h-12 w-full" />)}</div>
            ) : orders.length === 0 ? (
              <div className="py-12 text-center">
                <DollarSign size={40} className="mx-auto mb-3 opacity-20" style={{ color: "var(--muted)" }} />
                <p className="font-semibold" style={{ color: "var(--text)" }}>Chưa có giao dịch</p>
              </div>
            ) : (
              <table>
                <thead><tr><th>Mô tả</th><th>Ngày</th><th>Doanh thu</th><th>Thực nhận</th></tr></thead>
                <tbody>
                  {orders.slice(0, 20).map(o => (
                    <tr key={o.id}>
                      <td>
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: "var(--success-tint)" }}>
                            <Package size={14} style={{ color: "var(--success)" }} />
                          </div>
                          <span className="text-sm max-w-[160px] truncate block">{o.dropoff_address}</span>
                        </div>
                      </td>
                      <td><span className="text-sm" style={{ color: "var(--muted)" }}>{formatDate(o.created_at)}</span></td>
                      <td><span className="text-sm font-semibold">{formatVND(o.final_price ?? o.estimated_price ?? 0)}</span></td>
                      <td><span className="text-sm font-bold" style={{ color: "var(--success)" }}>+{formatVND((o.final_price ?? o.estimated_price ?? 0) * 0.9)}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
