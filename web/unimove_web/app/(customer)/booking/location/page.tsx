"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { MapPin, Navigation, Clock, ChevronRight, Info, ArrowLeft } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { customerApi } from "@/lib/api";

interface Place { id: string; address: string; label?: string; }

export default function BookingLocationPage() {
  const router = useRouter();
  const [pickup, setPickup] = useState("");
  const [dropoff, setDropoff] = useState("");
  const [places, setPlaces] = useState<Place[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    customerApi.getRecentPlaces().then(r => {
      if (r.success && r.data) setPlaces(r.data as Place[]);
    }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const handleContinue = () => {
    if (!dropoff.trim()) return;
    const params = new URLSearchParams({ pickup: pickup || "Vị trí hiện tại", dropoff });
    router.push(`/booking/dorm-details?${params}`);
  };

  return (
    <div className="max-w-2xl space-y-5 animate-fade-in">
      <div className="flex items-center gap-3">
        <Link href="/home">
          <button className="p-2 rounded-xl border" style={{ borderColor: "var(--border)", color: "var(--muted)", backgroundColor: "var(--card)" }}>
            <ArrowLeft size={18} />
          </button>
        </Link>
        <div>
          <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Chọn địa điểm</h1>
          <p className="text-sm" style={{ color: "var(--muted)" }}>Báo giá minh bạch · Không cần bản đồ</p>
        </div>
      </div>

      {/* Route input */}
      <div className="rounded-2xl p-6" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        <h3 className="text-sm font-semibold mb-4" style={{ color: "var(--text)" }}>Nhập địa điểm</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: "var(--muted)" }}>Điểm đón</label>
            <div className="relative">
              <Navigation size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2" style={{ color: "var(--primary)" }} />
              <input placeholder="Vị trí hiện tại (để trống)" value={pickup}
                onChange={e => setPickup(e.target.value)}
                className="w-full h-11 pl-10 pr-4 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)" }} />
            </div>
          </div>
          <div>
            <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: "var(--muted)" }}>Địa điểm đến <span style={{ color: "var(--error)" }}>*</span></label>
            <div className="relative">
              <MapPin size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2" style={{ color: "var(--success)" }} />
              <input placeholder="Nhập địa chỉ nơi cần chuyển đến" value={dropoff}
                onChange={e => setDropoff(e.target.value)} required
                className="w-full h-11 pl-10 pr-4 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)" }} />
            </div>
          </div>
          <button onClick={handleContinue} disabled={!dropoff.trim()}
            className="w-full h-11 rounded-xl text-white font-semibold text-sm flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ background: "linear-gradient(135deg, #1d4ed8, #3b82f6)" }}>
            Tiếp tục - Mô tả đồ đạc <ChevronRight size={16} />
          </button>
        </div>
      </div>

      {/* Recent places */}
      <div>
        <p className="text-sm font-semibold mb-3" style={{ color: "var(--text)" }}>Địa điểm gần đây</p>
        {loading ? (
          <div className="space-y-2">{[1, 2, 3].map(i => <Skeleton key={i} className="h-14 w-full" />)}</div>
        ) : places.length > 0 ? (
          <div className="space-y-2">
            {places.map(p => (
              <button key={p.id} onClick={() => { if (!dropoff) setDropoff(p.address); else if (!pickup) setPickup(p.address); }}
                className="w-full flex items-center gap-3 p-3.5 rounded-xl text-left hover:opacity-80 transition-opacity"
                style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: "var(--primary-tint)" }}>
                  <Clock size={16} style={{ color: "var(--primary)" }} />
                </div>
                <div>
                  {p.label && <p className="text-xs font-semibold mb-0.5" style={{ color: "var(--primary)" }}>{p.label}</p>}
                  <p className="text-sm" style={{ color: "var(--text)" }}>{p.address}</p>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <p className="text-sm text-center py-6" style={{ color: "var(--muted)" }}>Chưa có địa điểm gần đây</p>
        )}
      </div>

      <Card className="p-4">
        <div className="flex items-start gap-3">
          <Info size={16} className="shrink-0 mt-0.5" style={{ color: "var(--primary)" }} />
          <div>
            <p className="text-sm font-semibold mb-1" style={{ color: "var(--text)" }}>Quy trình báo giá</p>
            <ol className="text-xs space-y-1" style={{ color: "var(--muted)" }}>
              <li>1. Nhập địa điểm → Mô tả đồ đạc → Gửi yêu cầu</li>
              <li>2. Nhà xe xem xét và gửi báo giá trong 30 phút</li>
              <li>3. Chọn nhà xe → Đặt cọc 30% → Xác nhận lịch</li>
              <li>4. Ngày chuyển → Thanh toán phần còn lại</li>
            </ol>
          </div>
        </div>
      </Card>
    </div>
  );
}
