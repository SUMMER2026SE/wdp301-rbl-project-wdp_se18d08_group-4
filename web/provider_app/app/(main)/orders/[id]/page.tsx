"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, MapPin, Phone, CheckCircle, XCircle, Clock, DollarSign, User } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { providerOrdersApi } from "@/lib/api";
import { getOrderStatusLabel, getOrderStatusColor, formatVND, formatDate } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface OrderDetail {
  id: string;
  status: string;
  service_type: string;
  pickup_address: string;
  dropoff_address: string;
  description?: string;
  floor_number?: number;
  num_helpers?: number;
  special_notes?: string;
  estimated_price?: number;
  final_price?: number;
  deposit_amount?: number;
  created_at: string;
  customer?: { id: string; full_name: string; phone: string; avatar_url?: string };
}

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { toast } = useToast();
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [responding, setResponding] = useState(false);
  const [estimatedPrice, setEstimatedPrice] = useState("");

  useEffect(() => {
    providerOrdersApi.getOrder(id)
      .then((res) => { if (res.success && res.data) setOrder(res.data as OrderDetail); })
      .finally(() => setLoading(false));
  }, [id]);

  const respond = async (action: "accept" | "reject") => {
    setResponding(true);
    try {
      const body: { action: "accept" | "reject"; estimated_price?: number } = { action };
      if (action === "accept" && estimatedPrice) {
        body.estimated_price = parseInt(estimatedPrice);
      }
      await providerOrdersApi.respondToOrder(id, body);
      toast(action === "accept" ? "Đã chấp nhận đơn!" : "Đã từ chối đơn", action === "accept" ? "success" : "info");
      const res = await providerOrdersApi.getOrder(id);
      if (res.success && res.data) setOrder(res.data as OrderDetail);
    } catch { toast("Thử lại sau", "error"); }
    finally { setResponding(false); }
  };

  const statusColor = order ? getOrderStatusColor(order.status) : "var(--muted)";
  const isPending = order?.status === "pending";

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor: "var(--card)", borderBottom: "1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/orders" className="p-2 rounded-xl" style={{ backgroundColor: "var(--surface)" }}>
            <ArrowLeft size={20} style={{ color: "var(--text)" }} />
          </Link>
          <div>
            <h1 className="text-lg font-bold" style={{ color: "var(--text)" }}>Chi tiết đơn hàng</h1>
            {order && <p className="text-xs" style={{ color: "var(--muted)" }}>#{order.id.slice(0, 8).toUpperCase()}</p>}
          </div>
        </div>
      </div>

      {loading ? (
        <div className="px-4 py-4 space-y-4">
          {[1, 2, 3].map((i) => <Skeleton key={i} className="h-32 w-full rounded-2xl" />)}
        </div>
      ) : !order ? (
        <div className="text-center py-16">
          <XCircle size={52} className="mx-auto mb-4 opacity-30" style={{ color: "var(--error)" }} />
          <p style={{ color: "var(--text)" }}>Không tìm thấy đơn hàng</p>
        </div>
      ) : (
        <div className="px-4 py-4 space-y-4">
          {/* Status */}
          <Card className="p-5">
            <div className="flex items-center justify-between">
              <Badge style={{ backgroundColor: statusColor + "22", color: statusColor, border: `1px solid ${statusColor}44`, fontSize: "13px", padding: "4px 12px" }}>
                {getOrderStatusLabel(order.status)}
              </Badge>
              <span className="text-xs" style={{ color: "var(--muted)" }}>{formatDate(order.created_at)}</span>
            </div>
          </Card>

          {/* Customer */}
          {order.customer && (
            <Card className="p-5">
              <h3 className="font-bold mb-3" style={{ color: "var(--text)" }}>Khách hàng</h3>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-white font-bold text-lg"
                  style={{ background: "linear-gradient(135deg, var(--gradient-from), var(--gradient-to))" }}>
                  {order.customer.full_name[0]}
                </div>
                <div>
                  <p className="font-bold" style={{ color: "var(--text)" }}>{order.customer.full_name}</p>
                  <p className="text-sm" style={{ color: "var(--muted)" }}>{order.customer.phone}</p>
                </div>
              </div>
              <a href={`tel:${order.customer.phone}`}>
                <Button variant="outline" className="w-full gap-2">
                  <Phone size={16} /> Gọi cho khách
                </Button>
              </a>
            </Card>
          )}

          {/* Route */}
          <Card className="p-5">
            <h3 className="font-bold mb-4" style={{ color: "var(--text)" }}>Lộ trình</h3>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-xl flex items-center justify-center mt-0.5" style={{ backgroundColor: "var(--primary-tint)" }}>
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: "var(--primary)" }} />
                </div>
                <div>
                  <p className="text-xs font-semibold mb-0.5" style={{ color: "var(--muted)" }}>ĐIỂM ĐÓN</p>
                  <p className="text-sm font-medium" style={{ color: "var(--text)" }}>{order.pickup_address}</p>
                </div>
              </div>
              <div className="ml-4 w-0.5 h-5" style={{ backgroundColor: "var(--border)" }} />
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-xl flex items-center justify-center mt-0.5" style={{ backgroundColor: "var(--success-tint)" }}>
                  <MapPin size={16} style={{ color: "var(--success)" }} />
                </div>
                <div>
                  <p className="text-xs font-semibold mb-0.5" style={{ color: "var(--muted)" }}>ĐIỂM ĐẾN</p>
                  <p className="text-sm font-medium" style={{ color: "var(--text)" }}>{order.dropoff_address}</p>
                </div>
              </div>
            </div>
          </Card>

          {/* Order details */}
          <Card className="p-5">
            <h3 className="font-bold mb-4" style={{ color: "var(--text)" }}>Thông tin đồ đạc</h3>
            <div className="space-y-3">
              {order.description && <InfoRow label="Mô tả" value={order.description} />}
              {order.floor_number !== undefined && <InfoRow label="Tầng" value={`Tầng ${order.floor_number}`} />}
              {order.num_helpers && <InfoRow label="Số người khuân" value={`${order.num_helpers} người`} />}
              <InfoRow label="Loại dịch vụ" value={order.service_type || "Tiêu chuẩn"} />
              {order.special_notes && <InfoRow label="Ghi chú" value={order.special_notes} />}
            </div>
          </Card>

          {/* Price */}
          {(order.estimated_price || order.final_price) && (
            <Card className="p-5">
              <h3 className="font-bold mb-3" style={{ color: "var(--text)" }}>Giá dịch vụ</h3>
              {order.estimated_price && <InfoRow label="Giá báo" value={formatVND(order.estimated_price)} />}
              {order.deposit_amount && <InfoRow label="Đã đặt cọc" value={formatVND(order.deposit_amount)} />}
              {order.final_price && (
                <div className="flex items-center justify-between mt-2 pt-2" style={{ borderTop: "1px solid var(--border)" }}>
                  <span className="font-bold" style={{ color: "var(--text)" }}>Tổng cộng</span>
                  <span className="text-lg font-bold" style={{ color: "var(--success)" }}>{formatVND(order.final_price)}</span>
                </div>
              )}
            </Card>
          )}

          {/* Accept/Reject for pending */}
          {isPending && (
            <Card className="p-5">
              <h3 className="font-bold mb-3" style={{ color: "var(--text)" }}>Báo giá & Phản hồi</h3>
              <div className="space-y-3">
                <div>
                  <label className="text-sm font-medium block mb-1.5" style={{ color: "var(--text)" }}>
                    Giá báo của bạn (VNĐ)
                  </label>
                  <div className="relative flex items-center">
                    <DollarSign size={16} className="absolute left-3" style={{ color: "var(--muted)" }} />
                    <input
                      type="number"
                      placeholder="VD: 1500000"
                      value={estimatedPrice}
                      onChange={(e) => setEstimatedPrice(e.target.value)}
                      className="w-full h-11 rounded-xl border pl-9 pr-3 text-sm"
                      style={{ backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)" }}
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <Button variant="destructive" size="lg" className="w-full gap-2" loading={responding}
                    onClick={() => respond("reject")}>
                    <XCircle size={18} /> Từ chối
                  </Button>
                  <Button size="lg" className="w-full gap-2" loading={responding}
                    onClick={() => respond("accept")}
                    style={{ backgroundColor: "var(--success)" }}>
                    <CheckCircle size={18} /> Chấp nhận
                  </Button>
                </div>
              </div>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start justify-between gap-4">
      <span className="text-sm shrink-0" style={{ color: "var(--muted)" }}>{label}</span>
      <span className="text-sm font-medium text-right" style={{ color: "var(--text)" }}>{value}</span>
    </div>
  );
}
