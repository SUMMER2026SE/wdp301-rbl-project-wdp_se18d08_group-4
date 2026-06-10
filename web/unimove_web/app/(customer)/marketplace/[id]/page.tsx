"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, Heart, MessageCircle, MapPin, Star, Tag, CheckCircle } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { marketplaceApi } from "@/lib/api";
import { formatVND, timeAgo } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";
import { getStoredUser } from "@/lib/auth";

interface ListingDetail {
  id:string;title:string;description:string;price?:number;category:string;condition?:string;city?:string;
  status:string;images?:string[];created_at:string;is_interested?:boolean;seller_id:string;
  seller?:{id:string;full_name:string;avatar_url?:string;rating?:number;total_sales?:number};
}

export default function ListingDetailPage() {
  const {id} = useParams<{id:string}>();
  const {toast} = useToast();
  const [listing, setListing] = useState<ListingDetail|null>(null);
  const [loading, setLoading] = useState(true);
  const [imgIdx, setImgIdx] = useState(0);
  const currentUser = getStoredUser();
  const isOwner = currentUser?.id === listing?.seller_id;

  useEffect(() => {
    marketplaceApi.get(id).then(r=>{if(r.success&&r.data)setListing(r.data as ListingDetail);}).finally(()=>setLoading(false));
  },[id]);

  const toggleInterest = async () => {
    if (!listing) return;
    try {
      listing.is_interested ? await marketplaceApi.removeInterest(listing.id) : await marketplaceApi.addInterest(listing.id);
      setListing(p=>p?{...p,is_interested:!p.is_interested}:null);
      toast(listing.is_interested?"Đã bỏ yêu thích":"Đã thêm yêu thích","info");
    } catch {toast("Thử lại sau","error");}
  };

  if (loading) return (
    <div className="min-h-screen" style={{ backgroundColor:"var(--bg)" }}>
      <Skeleton className="h-72 w-full rounded-none" />
      <div className="px-4 py-4 space-y-3"><Skeleton className="h-6 w-3/4" /><Skeleton className="h-8 w-1/3" /><Skeleton className="h-24 w-full" /></div>
    </div>
  );

  if (!listing) return (
    <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor:"var(--bg)" }}>
      <div className="text-center">
        <p style={{ color:"var(--text)" }}>Không tìm thấy tin đăng</p>
        <Link href="/marketplace"><Button variant="outline" className="mt-4">Quay lại</Button></Link>
      </div>
    </div>
  );

  const sold = listing.status==="sold"||listing.status==="completed";

  return (
    <div className="min-h-screen flex flex-col" style={{ backgroundColor:"var(--bg)" }}>
      {/* Image */}
      <div className="relative h-72" style={{ backgroundColor:"var(--surface)" }}>
        {listing.images?.[imgIdx] ? (
          <img src={listing.images[imgIdx]} alt={listing.title} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full flex items-center justify-center"><Tag size={48} style={{ color:"var(--border)" }} /></div>
        )}
        <div className="absolute top-0 left-0 right-0 flex items-center justify-between p-4 pt-12 bg-gradient-to-b from-black/50 to-transparent">
          <Link href="/marketplace" className="w-9 h-9 rounded-full bg-black/40 flex items-center justify-center">
            <ArrowLeft size={18} className="text-white" />
          </Link>
          <button onClick={toggleInterest} className="w-9 h-9 rounded-full bg-black/40 flex items-center justify-center">
            <Heart size={16} fill={listing.is_interested?"#ef4444":"transparent"} style={{ color:listing.is_interested?"#ef4444":"white" }} />
          </button>
        </div>
        {sold && <div className="absolute inset-0 bg-black/50 flex items-center justify-center"><span className="text-white font-bold text-xl px-6 py-3 rounded-full bg-black/60">ĐÃ BÁN</span></div>}
        {listing.images && listing.images.length>1 && (
          <div className="absolute bottom-3 left-0 right-0 flex justify-center gap-1.5">
            {listing.images.map((_,i) => (
              <button key={i} onClick={()=>setImgIdx(i)} className="w-2 h-2 rounded-full transition-all"
                style={{ backgroundColor:i===imgIdx?"white":"rgba(255,255,255,0.5)" }} />
            ))}
          </div>
        )}
      </div>

      <div className="flex-1 px-4 py-4 space-y-4">
        <div>
          <div className="flex items-start justify-between mb-2">
            <p className="text-2xl font-bold" style={{ color:(!listing.price||listing.price===0)?"var(--success)":"var(--primary)" }}>
              {(!listing.price||listing.price===0)?"Miễn phí":formatVND(listing.price)}
            </p>
            {listing.condition && <Badge variant="secondary">{listing.condition}</Badge>}
          </div>
          <h1 className="text-lg font-bold" style={{ color:"var(--text)" }}>{listing.title}</h1>
          <div className="flex items-center gap-3 mt-2">
            {listing.city && <div className="flex items-center gap-1"><MapPin size={13} style={{ color:"var(--muted)" }} /><span className="text-sm" style={{ color:"var(--muted)" }}>{listing.city}</span></div>}
            <span className="text-sm" style={{ color:"var(--muted)" }}>{timeAgo(listing.created_at)}</span>
          </div>
        </div>

        <Card className="p-4">
          <h3 className="font-bold mb-2" style={{ color:"var(--text)" }}>Mô tả</h3>
          <p className="text-sm leading-relaxed whitespace-pre-line" style={{ color:"var(--muted)" }}>{listing.description}</p>
        </Card>

        {listing.seller && (
          <Card className="p-4">
            <h3 className="font-bold mb-3" style={{ color:"var(--text)" }}>Người bán</h3>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-white font-bold text-lg"
                style={{ background:"linear-gradient(135deg,#1d4ed8,#3b82f6)" }}>
                {listing.seller.full_name[0]}
              </div>
              <div className="flex-1">
                <p className="font-bold" style={{ color:"var(--text)" }}>{listing.seller.full_name}</p>
                {listing.seller.total_sales!==undefined && (
                  <p className="text-xs flex items-center gap-1" style={{ color:"var(--muted)" }}>
                    <CheckCircle size={12} style={{ color:"var(--success)" }} />{listing.seller.total_sales} giao dịch
                  </p>
                )}
                {listing.seller.rating && (
                  <div className="flex items-center gap-1 mt-0.5">
                    <Star size={12} fill="#f59e0b" style={{ color:"#f59e0b" }} />
                    <span className="text-xs" style={{ color:"var(--muted)" }}>{listing.seller.rating.toFixed(1)}</span>
                  </div>
                )}
              </div>
            </div>
          </Card>
        )}
      </div>

      {!isOwner && !sold && (
        <div className="px-4 py-4 pb-6" style={{ backgroundColor:"var(--card)", borderTop:"1px solid var(--border)" }}>
          <Link href={`/marketplace/${id}/chat`}>
            <Button variant="gradient-c" size="xl" className="w-full gap-2">
              <MessageCircle size={20} /> Nhắn tin hỏi mua
            </Button>
          </Link>
        </div>
      )}

      {isOwner && (
        <div className="px-4 py-4 pb-6 grid grid-cols-2 gap-3" style={{ backgroundColor:"var(--card)", borderTop:"1px solid var(--border)" }}>
          <Button variant="outline" size="lg" className="w-full" onClick={async()=>{
            try{await marketplaceApi.bump(listing.id);toast("Đã đẩy tin!","success");}catch{toast("Thử lại","error");}
          }}>Đẩy tin</Button>
          <Button variant="destructive" size="lg" className="w-full" onClick={async()=>{
            try{await marketplaceApi.updateStatus(listing.id,"hidden");toast("Đã ẩn tin","info");}catch{toast("Thử lại","error");}
          }}>Ẩn tin</Button>
        </div>
      )}
    </div>
  );
}
