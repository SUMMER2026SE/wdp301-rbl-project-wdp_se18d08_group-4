"use client";

import React, { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Truck, MapPin, Clock, ChevronRight, RefreshCw, CheckCircle, XCircle } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { providerOrdersApi } from "@/lib/api";
import { getOrderStatusLabel, getOrderStatusColor, timeAgo, formatVND } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface Order {
  id: string;
  status: string;
  service_type: string;
  pickup_address: string;
  dropoff_address: string;
  estimated_price?: number;
  final_price?: number;
  created_at: string;
  customer?: { full_name: string; phone: string };
}

const TABS = [
  { key: "", label: "Tất cả" },
  { key: "pending", label: "Chờ xác nhận" },
  { key: "accepted,picking_up,in_progress", label: "Đang thực hiện" },
  { key: "completed", label: "Hoàn thành" },
  { key: "cancelled", label: "Đã hủy" },
];

export default function ProviderOrdersPage() {
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState(0);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = useCallback(async (status: string) => {
    setLoading(true);
    try {
      const params: { status?: string } = {};
      if (status) params.status = status;
      const res = await providerOrdersApi.getOrders(params);
      if (res.success && res.data) {
        const data = res.data as { orders?: Order[] } | Order[];
        setOrders(Array.isArray(data) ? data : (data?.orders ?? []));
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOrders(TABS[activeTab].key);
  }, [activeTab, fetchOrders]);

  const handleAccept = async (orderId: string) => {
    try {
      await providerOrdersApi.respondToOrder(orderId, { action: "accept" });
      toast("Đã chấp nhận đơn!", "success");
      fetchOrders(TABS[activeTab].key);
    } catch { toast("Thử lại sau", "error"); }
  };

  const handleReject = async (orderId: string) => {
    try {
      await providerOrdersApi.respondToOrder(orderId, { action: "reject" });
      toast("Đã từ chối đơn", "info");
      fetchOrders(TABS[activeTab].key);
    } catch { toast("Thử lại sau", "error"); }
  };

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      {/* Header */}
      <div className="px-4 pt-12 pb-4 sticky top-0 z-10"
        style={{ backgroundColor: "var(--card)", borderBottom: "1px solid var(--border)" }}>
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold" style={{ color: "var(--text)" }}>Đơn hàng</h1>
          <button onClick={() => fetchOrders(TABS[activeTab].key)}
            className="p-2 rounded-xl" style={{ backgroundColor: "var(--surface)" }}>
            <RefreshCw size={18} style={{ color: "var(--muted)" }} />
          </button>
        </div>
        {/* Tabs */}
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {TABS.map((tab, i) => (
            <button key={i} onClick={() => setActiveTab(i)}
              className="whitespace-nowrap px-4 py-2 rounded-full text-sm font-semibold transition-all shrink-0"
              style={{
                backgroundColor: activeTab === i ? "var(--primary)" : "var(--surface)",
                color: activeTab === i ? "white" : "var(--muted)",
                border: `1px solid ${activeTab === i ? "var(--primary)" : "var(--border)"}`,
              }}>
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="px-4 py-4 space-y-3">
        {loading ? (
          Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="rounded-2xl border p-4 space-y-2"
              style={{ backgroundColor: "var(--card)", borderColor: "var(--border)" }}>
              <Skeleton className="h-5 w-24" />
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-3/4" />
            </div>
          ))
        ) : orders.length === 0 ? (
          <div className="text-center py-16">
            <Truck size={52} className="mx-auto mb-4 opacity-20" style={{ color: "var(--text)" }} />
            <p className="font-semibold" style={{ color: "var(--text)" }}>Không có đơn hàng nào</p>
          </div>
        ) : (
          orders.map((order) => (
            <OrderCard key={order.id} order={order}
              onAccept={() => handleAccept(order.id)}
              onReject={() => handleReject(order.id)} />
          ))
        )}
      </div>
    </div>
  );
}

function OrderCard({ order, onAccept, onReject }: {
  order: Order;
  onAccept: () => void;
  onReject: () => void;
}) {
  const statusColor = getOrderStatusColor(order.status);
  const isPending = order.status === "pending";

  return (
    <Link href={`/orders/${order.id}`}>
      <Card className={`p-4 hover:shadow-md transition-shadow ${isPending ? "border-2" : ""}`}
        style={isPending ? { borderColor: "var(--warning)" + "66" } : {}}>
        {/* Top */}
        <div className="flex items-start justify-between mb-3">
          <Badge style={{ backgroundColor: statusColor + "22", color: statusColor, border: `1px solid ${statusColor}44` }}>
            {getOrderStatusLabel(order.status)}
          </Badge>
          <span className="text-xs" style={{ color: "var(--muted)" }}>{timeAgo(order.created_at)}</span>
        </div>

        {/* Route */}
        <div className="space-y-1.5 mb-3">
          <div className="flex items-start gap-2">
            <div className="w-2 h-2 rounded-full mt-1.5 shrink-0" style={{ backgroundColor: "var(--primary)" }} />
            <p className="text-sm line-clamp-1" style={{ color: "var(--text)" }}>{order.pickup_address}</p>
          </div>
          <div className="flex items-start gap-2">
            <MapPin size={8} className="mt-1.5 shrink-0" style={{ color: "var(--success)" }} />
            <p className="text-sm line-clamp-1" style={{ color: "var(--text)" }}>{order.dropoff_address}</p>
          </div>
        </div>

        {/* Bottom */}
        <div className="flex items-center justify-between pt-2" style={{ borderTop: "1px solid var(--border)" }}>
          <div>
            {order.customer && (
              <p className="text-xs" style={{ color: "var(--muted)" }}>
                {order.customer.full_name}
              </p>
            )}
          </div>
          <div className="flex items-center gap-2">
            {(order.final_price ?? order.estimated_price) && (
              <span className="text-sm font-bold" style={{ color: "var(--success)" }}>
                {formatVND(order.final_price ?? order.estimated_price ?? 0)}
              </span>
            )}
            <ChevronRight size={16} style={{ color: "var(--muted)" }} />
          </div>
        </div>

        {/* Accept/Reject for pending */}
        {isPending && (
          <div className="grid grid-cols-2 gap-2 mt-3 pt-3" style={{ borderTop: "1px solid var(--border)" }}
            onClick={(e) => e.preventDefault()}>
            <button onClick={onReject}
              className="h-9 rounded-xl text-sm font-semibold flex items-center justify-center gap-1.5"
              style={{ color: "var(--error)", backgroundColor: "var(--error-tint)", border: "1px solid var(--error)" + "44" }}>
              <XCircle size={15} /> Từ chối
            </button>
            <button onClick={onAccept}
              className="h-9 rounded-xl text-sm font-semibold text-white flex items-center justify-center gap-1.5"
              style={{ backgroundColor: "var(--success)" }}>
              <CheckCircle size={15} /> Chấp nhận
            </button>
          </div>
        )}
      </Card>
    </Link>
  );
}
