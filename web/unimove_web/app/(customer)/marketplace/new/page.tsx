"use client";

import React, { useState, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, Camera, X, ChevronRight } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { marketplaceApi } from "@/lib/api";
import { useToast } from "@/components/ui/toast";

const CATS = [{value:"furniture",label:"Nội thất"},{value:"electronics",label:"Điện tử"},{value:"books",label:"Sách"},{value:"clothes",label:"Quần áo"},{value:"appliances",label:"Nhà bếp"},{value:"other",label:"Khác"}];
const CONDS = [{value:"new",label:"Mới"},{value:"like_new",label:"Như mới"},{value:"good",label:"Tốt"},{value:"fair",label:"Bình thường"},{value:"poor",label:"Cũ"}];

export default function NewListingPage() {
  const router = useRouter(); const { toast } = useToast();
  const fileRef = useRef<HTMLInputElement>(null);
  const [form, setForm] = useState({ title:"", description:"", price:"", category:"furniture", condition:"good", city:"", is_free:false });
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const set = (k:string, v:string|boolean) => setForm(p=>({...p,[k]:v}));

  const handleImages = (e:React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files||[]).slice(0,5-images.length);
    setImages(p=>[...p,...files].slice(0,5));
    setPreviews(p=>[...p,...files.map(f=>URL.createObjectURL(f))].slice(0,5));
  };

  const handleSubmit = async (e:React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim()||!form.description.trim()){toast("Điền đủ tiêu đề và mô tả","error");return;}
    setLoading(true);
    try {
      let uploadedImages:string[] = [];
      if (images.length>0) {
        const r = await marketplaceApi.uploadImages(images);
        if (r.success && r.data) uploadedImages = r.data as string[];
      }
      const res = await marketplaceApi.create({
        title:form.title.trim(), description:form.description.trim(),
        price: form.is_free ? 0 : parseInt(form.price||"0"),
        category:form.category, condition:form.condition,
        area:form.city.trim()||undefined, images:uploadedImages,
      });
      if (!res.success){toast((res as {message?:string}).message||"Thất bại","error");return;}
      toast("Đăng tin thành công!","success");
      router.push("/marketplace");
    } catch(err){toast(err instanceof Error?err.message:"Lỗi kết nối","error");}
    finally{setLoading(false);}
  };

  return (
    <div className="min-h-screen flex flex-col" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/marketplace" className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}>
            <ArrowLeft size={20} style={{ color:"var(--text)" }} />
          </Link>
          <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>Đăng tin bán đồ</h1>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto px-4 py-4 space-y-5">
        {/* Images */}
        <div>
          <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Ảnh sản phẩm <span style={{ color:"var(--muted)" }}>(tối đa 5)</span></label>
          <div className="flex gap-2 flex-wrap">
            {previews.map((url,i) => (
              <div key={i} className="relative w-20 h-20 rounded-xl overflow-hidden" style={{ border:"1px solid var(--border)" }}>
                <img src={url} alt="" className="w-full h-full object-cover" />
                <button type="button" onClick={()=>{setImages(p=>p.filter((_,j)=>j!==i));setPreviews(p=>p.filter((_,j)=>j!==i));}}
                  className="absolute top-1 right-1 w-5 h-5 rounded-full bg-black/60 flex items-center justify-center">
                  <X size={10} className="text-white" />
                </button>
              </div>
            ))}
            {previews.length<5 && (
              <button type="button" onClick={()=>fileRef.current?.click()}
                className="w-20 h-20 rounded-xl flex flex-col items-center justify-center gap-1"
                style={{ border:"2px dashed var(--border)", color:"var(--muted)" }}>
                <Camera size={20} /><span className="text-[10px]">Thêm ảnh</span>
              </button>
            )}
          </div>
          <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={handleImages} />
        </div>

        <div className="space-y-1.5">
          <label className="text-sm font-bold" style={{ color:"var(--text)" }}>Tiêu đề <span style={{ color:"var(--error)" }}>*</span></label>
          <Input required placeholder="VD: Bàn học gấp IKEA ít dùng" value={form.title} onChange={e=>set("title",e.target.value)} />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Danh mục</label>
            <select value={form.category} onChange={e=>set("category",e.target.value)} className="w-full h-11 rounded-xl border px-3 text-sm"
              style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }}>
              {CATS.map(c=><option key={c.value} value={c.value}>{c.label}</option>)}
            </select>
          </div>
          <div>
            <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Tình trạng</label>
            <select value={form.condition} onChange={e=>set("condition",e.target.value)} className="w-full h-11 rounded-xl border px-3 text-sm"
              style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }}>
              {CONDS.map(c=><option key={c.value} value={c.value}>{c.label}</option>)}
            </select>
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm font-bold" style={{ color:"var(--text)" }}>Giá bán</label>
            <label className="flex items-center gap-2 text-sm cursor-pointer" style={{ color:"var(--muted)" }}>
              <input type="checkbox" checked={form.is_free} onChange={e=>set("is_free",e.target.checked)} className="rounded" />
              Cho tặng miễn phí
            </label>
          </div>
          {!form.is_free ? (
            <Input type="number" min="0" step="1000" placeholder="VNĐ" value={form.price} onChange={e=>set("price",e.target.value)} />
          ) : (
            <div className="h-11 rounded-xl border flex items-center px-3 text-sm font-semibold" style={{ backgroundColor:"var(--success-tint)", borderColor:"var(--success)", color:"var(--success)" }}>
              Miễn phí - Cho tặng ♥
            </div>
          )}
        </div>

        <div className="space-y-1.5">
          <label className="text-sm font-bold" style={{ color:"var(--text)" }}>Thành phố</label>
          <Input placeholder="VD: Hà Nội, TP.HCM..." value={form.city} onChange={e=>set("city",e.target.value)} />
        </div>

        <div>
          <label className="text-sm font-bold block mb-2" style={{ color:"var(--text)" }}>Mô tả chi tiết <span style={{ color:"var(--error)" }}>*</span></label>
          <textarea required rows={5} placeholder="Mô tả tình trạng, kích thước, lý do bán..."
            value={form.description} onChange={e=>set("description",e.target.value)}
            className="w-full rounded-xl border px-3 py-3 text-sm resize-none"
            style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }} />
        </div>
      </form>

      <div className="px-4 py-4 pb-6" style={{ backgroundColor:"var(--card)", borderTop:"1px solid var(--border)" }}>
        <Button variant="gradient-c" size="xl" className="w-full" loading={loading}
          onClick={handleSubmit as unknown as React.MouseEventHandler}>
          Đăng tin <ChevronRight size={20} />
        </Button>
      </div>
    </div>
  );
}
