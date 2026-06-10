"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, User, Phone, Building, Save } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { providerProfileApi } from "@/lib/api";
import { getStoredUser } from "@/lib/auth";
import { useToast } from "@/components/ui/toast";

const VEHICLE_TYPES = [
  { value: "motorbike", label: "Xe máy" },
  { value: "pickup", label: "Bán tải" },
  { value: "van", label: "Xe van" },
  { value: "truck_1t", label: "Xe tải 1 tấn" },
  { value: "truck_2t", label: "Xe tải 2 tấn" },
  { value: "truck_5t", label: "Xe tải 5 tấn+" },
];

export default function EditProviderProfilePage() {
  const { toast } = useToast();
  const [form, setForm] = useState({ full_name: "", phone: "", business_name: "", vehicle_type: "van" });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const user = getStoredUser();
    if (user) setForm({
      full_name: user.full_name ?? "",
      phone: user.phone ?? "",
      business_name: user.business_name ?? "",
      vehicle_type: user.vehicle_type ?? "van",
    });
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await providerProfileApi.updateMe({ ...form });
      if (!res.success) { toast((res as { message?: string }).message || "Cập nhật thất bại", "error"); return; }
      const stored = getStoredUser();
      if (stored) localStorage.setItem("provider_user", JSON.stringify({ ...stored, ...form }));
      toast("Cập nhật thành công!", "success");
    } catch (err) {
      toast(err instanceof Error ? err.message : "Lỗi kết nối", "error");
    } finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor: "var(--card)", borderBottom: "1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/profile" className="p-2 rounded-xl" style={{ backgroundColor: "var(--surface)" }}>
            <ArrowLeft size={20} style={{ color: "var(--text)" }} />
          </Link>
          <h1 className="text-lg font-bold" style={{ color: "var(--text)" }}>Chỉnh sửa hồ sơ</h1>
        </div>
      </div>
      <form onSubmit={handleSubmit} className="px-4 py-5 space-y-4">
        <div className="space-y-1.5">
          <label className="text-sm font-medium" style={{ color: "var(--text)" }}>Họ và tên</label>
          <Input required value={form.full_name} onChange={(e) => setForm((p) => ({ ...p, full_name: e.target.value }))}
            startAdornment={<User size={15} />} />
        </div>
        <div className="space-y-1.5">
          <label className="text-sm font-medium" style={{ color: "var(--text)" }}>Tên doanh nghiệp</label>
          <Input value={form.business_name} onChange={(e) => setForm((p) => ({ ...p, business_name: e.target.value }))}
            startAdornment={<Building size={15} />} />
        </div>
        <div className="space-y-1.5">
          <label className="text-sm font-medium" style={{ color: "var(--text)" }}>Số điện thoại</label>
          <Input type="tel" value={form.phone} onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))}
            startAdornment={<Phone size={15} />} />
        </div>
        <div className="space-y-1.5">
          <label className="text-sm font-medium" style={{ color: "var(--text)" }}>Loại phương tiện</label>
          <select value={form.vehicle_type} onChange={(e) => setForm((p) => ({ ...p, vehicle_type: e.target.value }))}
            className="w-full h-11 rounded-xl border px-3 text-sm"
            style={{ backgroundColor: "var(--surface)", borderColor: "var(--border)", color: "var(--text)" }}>
            {VEHICLE_TYPES.map((v) => <option key={v.value} value={v.value}>{v.label}</option>)}
          </select>
        </div>
        <Button type="submit" size="xl" className="w-full gap-2" loading={loading}
          style={{ background: "linear-gradient(135deg, #16a34a, #22c55e)", color: "white" }}>
          <Save size={18} /> Lưu thay đổi
        </Button>
      </form>
    </div>
  );
}
