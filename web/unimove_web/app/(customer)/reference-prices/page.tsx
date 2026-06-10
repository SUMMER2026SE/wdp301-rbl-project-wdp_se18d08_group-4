"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Info } from "lucide-react";
import { Card } from "@/components/ui/card";

const DATA = [
  { cat:"Phòng nhỏ (≤ 20m²)", items:[["Chuyển gần (1-2km)","400.000 - 600.000đ"],["Chuyển vừa (3-5km)","500.000 - 800.000đ"],["Chuyển xa (5-10km)","700.000 - 1.200.000đ"]] },
  { cat:"Phòng vừa (20-40m²)", items:[["Chuyển gần (1-2km)","700.000 - 1.000.000đ"],["Chuyển vừa (3-5km)","900.000 - 1.400.000đ"],["Chuyển xa (5-10km)","1.200.000 - 2.000.000đ"]] },
  { cat:"Phụ phí thêm", items:[["Mỗi tầng không thang máy","+30.000 - 50.000đ/tầng"],["Đồ nặng (tủ lạnh, máy giặt...)","+100.000 - 300.000đ/món"],["Đóng gói chuyên nghiệp","+50.000 - 150.000đ"],["Phí chờ (> 30 phút)","+50.000đ/30 phút"]] },
  { cat:"Gói khuân vác thuần", items:[["1 người (2 tiếng)","150.000 - 200.000đ"],["2 người (2 tiếng)","280.000 - 350.000đ"],["Thêm mỗi giờ/người","+60.000 - 80.000đ"]] },
];

export default function ReferencePricesPage() {
  return (
    <div className="min-h-screen" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/home" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}><ArrowLeft size={20} style={{ color:"var(--text)" }} /></Link>
          <div>
            <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Bảng phụ phí tham khảo</h1>
            <p className="text-xs" style={{ color:"var(--muted)" }}>Giá ước tính · Thực tế có thể thay đổi</p>
          </div>
        </div>
      </div>
      <div className="px-4 py-4 space-y-4">
        <Card className="p-4" style={{ backgroundColor:"var(--primary-tint)", borderColor:"var(--primary)"+"33" }}>
          <div className="flex items-start gap-2.5"><Info size={16} className="shrink-0 mt-0.5" style={{ color:"var(--primary)" }} />
            <p className="text-sm" style={{ color:"var(--primary)" }}>Giá tham khảo. Báo giá thực tế từ nhà xe dựa trên khối lượng đồ đạc và điều kiện cụ thể.</p>
          </div>
        </Card>
        {DATA.map(s=>(
          <Card key={s.cat} className="overflow-hidden">
            <div className="px-4 py-3" style={{ backgroundColor:"var(--primary)" }}>
              <h3 className="font-bold text-sm text-white">{s.cat}</h3>
            </div>
            {s.items.map(([label,price],i)=>(
              <div key={i} className="flex items-center justify-between px-4 py-3" style={{ borderBottom:i<s.items.length-1?"1px solid var(--border)":"none" }}>
                <span className="text-sm" style={{ color:"var(--text)" }}>{label}</span>
                <span className="text-sm font-bold" style={{ color:"var(--primary)" }}>{price}</span>
              </div>
            ))}
          </Card>
        ))}
        <p className="text-center text-xs py-2" style={{ color:"var(--muted)" }}>Cập nhật tháng 6/2026 · UniMove</p>
      </div>
    </div>
  );
}
