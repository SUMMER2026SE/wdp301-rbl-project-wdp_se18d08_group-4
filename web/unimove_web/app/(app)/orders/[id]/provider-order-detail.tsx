"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, MapPin, Phone, CheckCircle, XCircle, DollarSign } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ordersApi } from "@/lib/api";
import { getOrderStatusLabel, getOrderStatusColor, formatVND, formatDate } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface OrderDetail { id:string;status:string;service_type:string;pickup_address:string;dropoff_address:string;description?:string;floor_number?:number;num_helpers?:number;special_notes?:string;estimated_price?:number;final_price?:number;deposit_amount?:number;created_at:string;customer?:{id:string;full_name:string;phone:string}; }

export default function ProviderOrderDetailPage() {
  const {id}=useParams<{id:string}>();
  const {toast}=useToast();
  const [order,setOrder]=useState<OrderDetail|null>(null);
  const [loading,setLoading]=useState(true);
  const [responding,setResponding]=useState(false);
  const [price,setPrice]=useState("");

  useEffect(()=>{ordersApi.get(id).then(r=>{if(r.success&&r.data)setOrder(r.data as OrderDetail);}).finally(()=>setLoading(false));},[id]);

  const respond=async(action:"accept"|"reject")=>{
    setResponding(true);
    try {
      await ordersApi.respond(id,action,action==="accept"&&price?parseInt(price):undefined);
      toast(action==="accept"?"Đã chấp nhận!":"Đã từ chối",action==="accept"?"success":"info");
      const r=await ordersApi.get(id);
      if(r.success&&r.data)setOrder(r.data as OrderDetail);
    } catch{toast("Thử lại sau","error");}
    finally{setResponding(false);}
  };

  const sc=order?getOrderStatusColor(order.status):"var(--muted)";

  return (
    <div className="min-h-screen" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/orders" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}><ArrowLeft size={20} style={{ color:"var(--text)" }}/></Link>
          <div><h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Chi tiết đơn hàng</h1>{order&&<p className="text-xs" style={{ color:"var(--muted)" }}>#{order.id.slice(0,8).toUpperCase()}</p>}</div>
        </div>
      </div>
      {loading?<div className="px-4 py-4 space-y-4">{[1,2,3].map(i=><Skeleton key={i} className="h-32 rounded-2xl"/>)}</div>
      :!order?<div className="text-center py-16"><p style={{ color:"var(--muted)" }}>Không tìm thấy</p></div>
      :<div className="px-4 py-4 space-y-4">
        <Card className="p-5 flex items-center justify-between">
          <Badge style={{ backgroundColor:sc+"22",color:sc,border:`1px solid ${sc}44`,fontSize:"13px",padding:"4px 12px" }}>{getOrderStatusLabel(order.status)}</Badge>
          <span className="text-xs" style={{ color:"var(--muted)" }}>{formatDate(order.created_at)}</span>
        </Card>
        {order.customer&&<Card className="p-5"><h3 className="font-bold mb-3" style={{ color:"var(--text)" }}>Khách hàng</h3>
          <div className="flex items-center gap-3 mb-3">
            <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-white font-bold text-lg" style={{ background:"linear-gradient(135deg,#1d4ed8,#3b82f6)" }}>{order.customer.full_name[0]}</div>
            <div><p className="font-bold" style={{ color:"var(--text)" }}>{order.customer.full_name}</p><p className="text-sm" style={{ color:"var(--muted)" }}>{order.customer.phone}</p></div>
          </div>
          <a href={`tel:${order.customer.phone}`}><Button variant="outline" className="w-full gap-2"><Phone size={16}/> Gọi cho khách</Button></a>
        </Card>}
        <Card className="p-5"><h3 className="font-bold mb-4" style={{ color:"var(--text)" }}>Lộ trình</h3>
          <div className="space-y-3">
            <div className="flex items-start gap-3"><div className="w-8 h-8 rounded-xl flex items-center justify-center mt-0.5 shrink-0" style={{ backgroundColor:"var(--primary-tint)" }}><div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor:"var(--primary)" }}/></div><div><p className="text-xs font-semibold mb-0.5" style={{ color:"var(--muted)" }}>ĐIỂM ĐÓN</p><p className="text-sm font-medium" style={{ color:"var(--text)" }}>{order.pickup_address}</p></div></div>
            <div className="ml-4 w-0.5 h-5" style={{ backgroundColor:"var(--border)" }}/>
            <div className="flex items-start gap-3"><div className="w-8 h-8 rounded-xl flex items-center justify-center mt-0.5 shrink-0" style={{ backgroundColor:"var(--success-tint)" }}><MapPin size={16} style={{ color:"var(--success)" }}/></div><div><p className="text-xs font-semibold mb-0.5" style={{ color:"var(--muted)" }}>ĐIỂM ĐẾN</p><p className="text-sm font-medium" style={{ color:"var(--text)" }}>{order.dropoff_address}</p></div></div>
          </div>
        </Card>
        <Card className="p-5"><h3 className="font-bold mb-3" style={{ color:"var(--text)" }}>Thông tin đồ đạc</h3>
          <div className="space-y-2.5">
            {order.description&&<div className="flex justify-between gap-4"><span className="text-sm" style={{ color:"var(--muted)" }}>Mô tả</span><span className="text-sm font-medium text-right" style={{ color:"var(--text)" }}>{order.description}</span></div>}
            {order.floor_number!==undefined&&<div className="flex justify-between"><span className="text-sm" style={{ color:"var(--muted)" }}>Tầng</span><span className="text-sm font-medium" style={{ color:"var(--text)" }}>Tầng {order.floor_number}</span></div>}
            {order.num_helpers&&<div className="flex justify-between"><span className="text-sm" style={{ color:"var(--muted)" }}>Số người khuân</span><span className="text-sm font-medium" style={{ color:"var(--text)" }}>{order.num_helpers} người</span></div>}
            {order.special_notes&&<div className="flex justify-between gap-4"><span className="text-sm shrink-0" style={{ color:"var(--muted)" }}>Ghi chú</span><span className="text-sm font-medium text-right" style={{ color:"var(--text)" }}>{order.special_notes}</span></div>}
          </div>
        </Card>
        {order.status==="pending"&&<Card className="p-5"><h3 className="font-bold mb-3" style={{ color:"var(--text)" }}>Báo giá & Phản hồi</h3>
          <div className="space-y-3">
            <div><label className="text-sm font-medium block mb-1.5" style={{ color:"var(--text)" }}>Giá báo của bạn (VNĐ)</label>
              <div className="relative flex items-center"><DollarSign size={16} className="absolute left-3" style={{ color:"var(--muted)" }}/><input type="number" placeholder="VD: 1500000" value={price} onChange={e=>setPrice(e.target.value)} className="w-full h-11 rounded-xl border pl-9 pr-3 text-sm" style={{ backgroundColor:"var(--surface)",borderColor:"var(--border)",color:"var(--text)" }}/></div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <Button variant="destructive" size="lg" className="w-full gap-2" loading={responding} onClick={()=>respond("reject")}><XCircle size={18}/> Từ chối</Button>
              <Button size="lg" className="w-full gap-2" loading={responding} onClick={()=>respond("accept")} style={{ backgroundColor:"var(--success)" }}><CheckCircle size={18}/> Chấp nhận</Button>
            </div>
          </div>
        </Card>}
      </div>}
    </div>
  );
}
