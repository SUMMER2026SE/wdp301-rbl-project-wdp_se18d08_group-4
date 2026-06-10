"use client";

import React, { useState, Suspense } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { ArrowLeft, ChevronRight, Layers, Users, Home } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ordersApi } from "@/lib/api";
import { useToast } from "@/components/ui/toast";

const SERVICE_TYPES = [
  { value: "standard", label: "Tiêu chuẩn", desc: "Phù hợp trọ nhỏ, ít đồ", price: "từ 500k", color: "#3b82f6" },
  { value: "express",  label: "Nhanh",       desc: "Ưu tiên xử lý ngay",    price: "từ 800k", color: "#f59e0b" },
  { value: "premium",  label: "Cao cấp",     desc: "Đóng gói chuyên nghiệp", price: "từ 1.2tr", color: "#9333ea" },
];

function Content() {
  const router = useRouter();
  const { toast } = useToast();
  const sp = useSearchParams();
  const pickup = sp.get("pickup") || "Vị trí hiện tại";
  const dropoff = sp.get("dropoff") || "";

  const [form, setForm] = useState({ description:"", floor:"", num_helpers:"2", service_type:"standard", special_notes:"" });
  const [loading, setLoading] = useState(false);
  const set = (k: string, v: string) => setForm(p => ({ ...p, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.description.trim()) { toast("Vui lòng mô tả đồ đạc", "error"); return; }
    setLoading(true);
    try {
      const res = await ordersApi.create({
        service_type: form.service_type,
        pickup_address: pickup,
        dropoff_address: dropoff,
        description: form.description,
        floor_number: form.floor ? parseInt(form.floor) : undefined,
        num_helpers: parseInt(form.num_helpers),
        special_notes: form.special_notes || undefined,
      });
      if (!res.success) { toast((res as {message?:string}).message || "Gửi thất bại", "error"); return; }
      const d = res.data as { id: string };
      toast("Đã gửi yêu cầu báo giá!", "success");
      router.push(`/orders/${d.id}`);
    } catch (err) { toast(err instanceof Error ? err.message : "Lỗi kết nối", "error"); }
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen flex flex-col" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3 mb-3">
          <Link href="/booking/location" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}>
            <ArrowLeft size={20} style={{ color:"var(--text)" }} />
          </Link>
          <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Thông tin phòng trọ</h1>
        </div>
        <div className="px-3 py-2.5 rounded-xl flex items-center gap-3" style={{ backgroundColor:"var(--surface)" }}>
          <span className="text-xs truncate flex-1" style={{ color:"var(--muted)" }}>{pickup}</span>
          <ChevronRight size={14} style={{ color:"var(--muted)" }} />
          <span className="text-xs font-medium truncate flex-1" style={{ color:"var(--text)" }}>{dropoff}</span>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto px-4 py-4 space-y-5">
        {/* Service type */}
        <div>
          <label className="text-sm font-bold block mb-3" style={{ color:"var(--text)" }}>Loại dịch vụ</label>
          <div className="space-y-2">
            {SERVICE_TYPES.map(st => (
              <button key={st.value} type="button" onClick={() => set("service_type", st.value)}
                className="w-full flex items-center justify-between p-4 rounded-2xl text-left transition-all"
                style={{ backgroundColor: form.service_type===st.value ? st.color+"15" : "var(--card)", border:`2px solid ${form.service_type===st.value ? st.color : "var(--border)"}` }}>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-sm" style={{ color: form.service_type===st.value ? st.color : "var(--text)" }}>{st.label}</span>
                    {form.service_type===st.value && <span className="text-[10px] px-2 py-0.5 rounded-full text-white" style={{ backgroundColor:st.color }}>Đã chọn</span>}
                  </div>
                  <p className="text-xs mt-0.5" style={{ color:"var(--muted)" }}>{st.desc}</p>
                </div>
                <span className="text-sm font-bold" style={{ color:st.color }}>{st.price}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>
            Mô tả đồ đạc <span style={{ color:"var(--error)" }}>*</span>
          </label>
          <textarea required rows={4} placeholder="VD: 1 tủ lạnh, 2 thùng quần áo, 1 bộ bàn ghế..."
            value={form.description} onChange={e => set("description", e.target.value)}
            className="w-full rounded-xl border px-3 py-3 text-sm resize-none"
            style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }} />
          <p className="text-xs mt-1" style={{ color:"var(--muted)" }}>Mô tả càng chi tiết, báo giá càng chính xác</p>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Tầng hiện tại</label>
            <Input type="number" min="0" max="50" placeholder="VD: 3" value={form.floor}
              onChange={e => set("floor", e.target.value)} startAdornment={<Layers size={14} />} />
          </div>
          <div>
            <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Số người khuân</label>
            <Input type="number" min="1" max="10" value={form.num_helpers}
              onChange={e => set("num_helpers", e.target.value)} startAdornment={<Users size={14} />} />
          </div>
        </div>

        <div>
          <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Ghi chú đặc biệt</label>
          <textarea rows={2} placeholder="VD: Có thang máy, đường hẻm nhỏ..."
            value={form.special_notes} onChange={e => set("special_notes", e.target.value)}
            className="w-full rounded-xl border px-3 py-3 text-sm resize-none"
            style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }} />
        </div>

        <Card className="p-4" style={{ backgroundColor:"var(--primary-tint)", borderColor:"var(--primary)"+"33" }}>
          <p className="text-xs" style={{ color:"var(--primary)" }}>
            ✅ Sau khi gửi, nhà xe sẽ xem xét và gửi báo giá chi tiết trong vòng 30 phút.
            Bạn có thể từ chối nếu giá không phù hợp.
          </p>
        </Card>
      </form>

      <div className="px-4 py-4 pb-6" style={{ backgroundColor:"var(--card)", borderTop:"1px solid var(--border)" }}>
        <Button variant="gradient-c" size="xl" className="w-full" loading={loading}
          onClick={handleSubmit as unknown as React.MouseEventHandler} disabled={!form.description.trim()}>
          Gửi yêu cầu báo giá <Home size={20} />
        </Button>
      </div>
    </div>
  );
}

export default function DormDetailsPage() {
  return (
    <Suspense fallback={<div className="min-h-screen flex items-center justify-center" style={{ backgroundColor:"var(--bg)" }}>
      <p style={{ color:"var(--muted)" }}>Đang tải...</p>
    </div>}>
      <Content />
    </Suspense>
  );
}
