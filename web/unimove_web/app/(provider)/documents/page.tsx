"use client";

import React, { useRef, useState } from "react";
import Link from "next/link";
import { ArrowLeft, Upload, CheckCircle, Camera, Shield, AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { providerApi } from "@/lib/api";
import { getStoredUser } from "@/lib/auth";
import { useToast } from "@/components/ui/toast";

const DOCS = [
  {key:"cccd_front",label:"CCCD/CMND (mặt trước)",required:true},
  {key:"cccd_back",label:"CCCD/CMND (mặt sau)",required:true},
  {key:"vehicle_registration",label:"Đăng ký xe",required:true},
  {key:"driver_license",label:"Bằng lái xe",required:true},
  {key:"vehicle_photo",label:"Ảnh phương tiện",required:false},
];

export default function DocumentsPage() {
  const {toast} = useToast();
  const user = getStoredUser();
  const [files, setFiles] = useState<Record<string,File|null>>(Object.fromEntries(DOCS.map(d=>[d.key,null])));
  const [previews, setPreviews] = useState<Record<string,string>>(Object.fromEntries(DOCS.map(d=>[d.key,""])));
  const [loading, setLoading] = useState(false);
  const refs = useRef<Record<string,HTMLInputElement|null>>({});

  const handleFile = (key:string, e:React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setFiles(p=>({...p,[key]:f}));
    setPreviews(p=>({...p,[key]:URL.createObjectURL(f)}));
  };

  const handleSubmit = async () => {
    const missing = DOCS.filter(d=>d.required&&!files[d.key]).map(d=>d.label);
    if (missing.length>0){toast(`Vui lòng upload: ${missing.join(", ")}`,"error");return;}
    setLoading(true);
    try {
      const toUpload: Record<string,File> = {};
      Object.entries(files).forEach(([k,v])=>{if(v)toUpload[k]=v;});
      await providerApi.uploadDocuments(toUpload);
      toast("Upload thành công! Chờ admin xét duyệt.","success");
    } catch(err){toast(err instanceof Error?err.message:"Upload thất bại","error");}
    finally{setLoading(false);}
  };

  const uploaded = Object.values(files).filter(Boolean).length;

  return (
    <div className="min-h-screen" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/dashboard" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}><ArrowLeft size={20} style={{ color:"var(--text)" }} /></Link>
          <div>
            <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Xác minh tài khoản</h1>
            <p className="text-xs" style={{ color:"var(--muted)" }}>{uploaded}/{DOCS.length} giấy tờ đã tải lên</p>
          </div>
        </div>
      </div>

      <div className="px-4 py-4 space-y-4">
        {user?.is_verified ? (
          <Card className="p-4" style={{ backgroundColor:"var(--success-tint)", borderColor:"var(--success)"+"44" }}>
            <div className="flex items-center gap-3"><CheckCircle size={24} style={{ color:"var(--success)" }} /><div><p className="font-bold" style={{ color:"var(--success)" }}>Tài khoản đã được xác minh</p><p className="text-xs" style={{ color:"var(--success)" }}>Bạn có thể nhận đơn bình thường</p></div></div>
          </Card>
        ) : (
          <Card className="p-4" style={{ backgroundColor:"var(--warning-tint)", borderColor:"var(--warning)"+"44" }}>
            <div className="flex items-center gap-3"><AlertTriangle size={24} style={{ color:"var(--warning)" }} /><div><p className="font-bold" style={{ color:"var(--warning)" }}>Chưa xác minh</p><p className="text-xs" style={{ color:"var(--warning)" }}>Upload đủ giấy tờ, duyệt trong 24h</p></div></div>
          </Card>
        )}

        <Card className="p-4">
          <div className="flex items-start gap-2.5"><Shield size={16} className="shrink-0 mt-0.5" style={{ color:"var(--primary)" }} />
            <ul className="text-xs space-y-1" style={{ color:"var(--muted)" }}>
              <li>• Tăng độ tin cậy với khách hàng</li>
              <li>• Bắt buộc để nhận đơn hàng</li>
              <li>• Ưu tiên hiển thị trong danh sách</li>
            </ul>
          </div>
        </Card>

        <div className="space-y-3">
          {DOCS.map(({key,label,required})=>{
            const uploaded = !!files[key];
            return (
              <div key={key}>
                <input type="file" accept="image/*" className="hidden"
                  ref={el=>{refs.current[key]=el;}}
                  onChange={e=>handleFile(key,e)} />
                <button onClick={()=>refs.current[key]?.click()}
                  className="w-full p-4 rounded-2xl border-2 flex items-center gap-3 text-left transition-all"
                  style={{ backgroundColor:uploaded?"var(--success-tint)":"var(--card)", borderColor:uploaded?"var(--success)":"var(--border)" }}>
                  {previews[key] ? (
                    <img src={previews[key]} alt="" className="w-14 h-14 rounded-xl object-cover shrink-0" />
                  ) : (
                    <div className="w-14 h-14 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor:uploaded?"var(--success-tint)":"var(--surface)" }}>
                      {uploaded?<CheckCircle size={24} style={{ color:"var(--success)" }} />:<Upload size={24} style={{ color:"var(--muted)" }} />}
                    </div>
                  )}
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-semibold" style={{ color:uploaded?"var(--success)":"var(--text)" }}>{label}</p>
                      {required&&!uploaded&&<span className="text-[10px] px-1.5 py-0.5 rounded-full text-white" style={{ backgroundColor:"var(--error)" }}>Bắt buộc</span>}
                    </div>
                    <p className="text-xs mt-0.5" style={{ color:"var(--muted)" }}>{uploaded?"✓ Đã tải lên · Nhấn để thay đổi":"Nhấn để chọn ảnh"}</p>
                  </div>
                </button>
              </div>
            );
          })}
        </div>

        <Button size="xl" className="w-full gap-2" loading={loading} onClick={handleSubmit}
          style={{ background:"linear-gradient(135deg,#15803d,#22c55e)", color:"white" }}>
          <Upload size={20}/> Gửi giấy tờ xác minh
        </Button>
      </div>
    </div>
  );
}
