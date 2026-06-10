"use client";

import { useEffect, useState } from "react";
import { getStoredUser } from "@/lib/auth";
import React from "react";
import Link from "next/link";
import { ArrowLeft, User, Phone, Building, Save } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { customerApi, authApi } from "@/lib/api";
import { useToast } from "@/components/ui/toast";

const VEHICLES=[["motorbike","Xe máy"],["pickup","Bán tải"],["van","Xe van"],["truck_1t","Xe tải 1T"],["truck_2t","Xe tải 2T"],["truck_5t","Xe tải 5T+"]];

export default function EditProfilePage() {
  const {toast}=useToast();
  const [role, setRole]=useState<string|null>(null);
  const [form, setForm]=useState({full_name:"",phone:"",student_id:"",business_name:"",vehicle_type:"van"});
  const [loading, setLoading]=useState(false);

  useEffect(()=>{
    const u=getStoredUser();
    if(u){
      setRole(u.role);
      setForm({full_name:u.full_name,phone:u.phone??"",student_id:u.student_id??"",business_name:u.business_name??"",vehicle_type:u.vehicle_type??"van"});
    }
  },[]);

  const handleSubmit=async(e:React.FormEvent)=>{
    e.preventDefault(); setLoading(true);
    try {
      const body:Record<string,unknown>={full_name:form.full_name,phone:form.phone||undefined};
      if(role==="customer") body.student_id=form.student_id||undefined;
      if(role==="provider"){body.business_name=form.business_name||undefined;body.vehicle_type=form.vehicle_type;}
      const r=role==="customer"?await customerApi.updateMe(body):await authApi.updateMe(body);
      if(!r.success){toast((r as {message?:string}).message||"Thất bại","error");return;}
      const u=getStoredUser();
      if(u)localStorage.setItem("unimove_user",JSON.stringify({...u,...form}));
      toast("Cập nhật thành công!","success");
    } catch(err){toast(err instanceof Error?err.message:"Lỗi kết nối","error");}
    finally{setLoading(false);}
  };

  const isProvider=role==="provider";
  const color=isProvider?"var(--provider)":"var(--primary)";
  const gradient=isProvider?"linear-gradient(135deg,#15803d,#22c55e)":"linear-gradient(135deg,#1d4ed8,#3b82f6)";

  return (
    <div className="min-h-screen" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/profile" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}><ArrowLeft size={20} style={{ color:"var(--text)" }}/></Link>
          <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Chỉnh sửa hồ sơ</h1>
        </div>
      </div>
      <form onSubmit={handleSubmit} className="px-4 py-5 space-y-4">
        <div className="space-y-1.5"><label className="text-sm font-medium" style={{ color:"var(--text)" }}>Họ và tên</label>
          <Input required value={form.full_name} onChange={e=>setForm(p=>({...p,full_name:e.target.value}))} startAdornment={<User size={15}/>}/></div>
        <div className="space-y-1.5"><label className="text-sm font-medium" style={{ color:"var(--text)" }}>Số điện thoại</label>
          <Input type="tel" value={form.phone} onChange={e=>setForm(p=>({...p,phone:e.target.value}))} startAdornment={<Phone size={15}/>}/></div>
        {!isProvider&&<div className="space-y-1.5"><label className="text-sm font-medium" style={{ color:"var(--text)" }}>Mã số sinh viên</label>
          <Input value={form.student_id} onChange={e=>setForm(p=>({...p,student_id:e.target.value}))} placeholder="SE123456"/></div>}
        {isProvider&&<>
          <div className="space-y-1.5"><label className="text-sm font-medium" style={{ color:"var(--text)" }}>Tên doanh nghiệp</label>
            <Input value={form.business_name} onChange={e=>setForm(p=>({...p,business_name:e.target.value}))} startAdornment={<Building size={15}/>}/></div>
          <div className="space-y-1.5"><label className="text-sm font-medium" style={{ color:"var(--text)" }}>Loại phương tiện</label>
            <select value={form.vehicle_type} onChange={e=>setForm(p=>({...p,vehicle_type:e.target.value}))} className="w-full h-11 rounded-xl border px-3 text-sm" style={{ backgroundColor:"var(--surface)",borderColor:"var(--border)",color:"var(--text)" }}>
              {VEHICLES.map(([v,l])=><option key={v} value={v}>{l}</option>)}
            </select></div>
        </>}
        <Button type="submit" size="xl" className="w-full gap-2" loading={loading} style={{ background:gradient, color:"white" }}>
          <Save size={18}/> Lưu thay đổi
        </Button>
      </form>
    </div>
  );
}
