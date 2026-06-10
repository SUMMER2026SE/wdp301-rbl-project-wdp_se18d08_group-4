"use client";

import React, { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { Search, Plus, Heart, Tag, MapPin, SlidersHorizontal } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { marketplaceApi } from "@/lib/api";
import { formatVND, timeAgo } from "@/lib/utils";

interface Listing { id: string; title: string; price?: number; category: string; condition?: string; city?: string; status: string; images?: string[]; created_at: string; is_interested?: boolean; }

const CATS = [
  { value: "", label: "Tất cả danh mục" },
  { value: "furniture", label: "🛋️ Nội thất" },
  { value: "electronics", label: "💻 Điện tử" },
  { value: "books", label: "📚 Sách vở" },
  { value: "clothes", label: "👕 Quần áo" },
  { value: "appliances", label: "🍳 Nhà bếp" },
  { value: "other", label: "📦 Khác" },
];

const CONDS = [
  { value: "", label: "Tất cả tình trạng" },
  { value: "new", label: "Mới" },
  { value: "like_new", label: "Như mới" },
  { value: "good", label: "Tốt" },
  { value: "fair", label: "Bình thường" },
];

const TABS = [
  { key: "explore", label: "Khám phá" },
  { key: "saved", label: "Yêu thích" },
  { key: "mine", label: "Tin của tôi" },
];

export default function MarketplacePage() {
  const [tab, setTab] = useState(0);
  const [search, setSearch] = useState("");
  const [cat, setCat] = useState("");
  const [cond, setCond] = useState("");
  const [listings, setListings] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async (q: string, c: string, t: number) => {
    setLoading(true);
    try {
      const res = t === 0 ? await marketplaceApi.list({ search: q || undefined, category: c || undefined })
        : t === 1 ? await marketplaceApi.myInterests()
        : await marketplaceApi.myListings();
      if (res.success) {
        const d = res.data as { listings?: Listing[] } | Listing[] | undefined;
        const list = res.listings ?? (Array.isArray(d) ? d : d?.listings ?? []);
        setListings(list as Listing[]);
      }
    } finally { setLoading(false); }
  }, []);

  useEffect(() => {
    const t = setTimeout(() => load(search, cat, tab), 400);
    return () => clearTimeout(t);
  }, [search, cat, tab, load]);

  const filtered = cond ? listings.filter(l => l.condition === cond) : listings;

  const toggleInterest = async (e: React.MouseEvent, l: Listing) => {
    e.preventDefault();
    try {
      l.is_interested ? await marketplaceApi.removeInterest(l.id) : await marketplaceApi.addInterest(l.id);
      setListings(p => p.map(x => x.id === l.id ? { ...x, is_interested: !x.is_interested } : x));
    } catch {}
  };

  return (
    <div className="space-y-5 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Chợ sinh viên</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>Mua bán đồ dùng sinh viên</p>
        </div>
        <Link href="/marketplace/new">
          <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-white text-sm font-semibold"
            style={{ background: "linear-gradient(135deg, #1d4ed8, #3b82f6)" }}>
            <Plus size={16} /> Đăng tin bán đồ
          </button>
        </Link>
      </div>

      {/* Tabs */}
      <div className="flex gap-1.5 p-1 rounded-xl w-fit" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        {TABS.map((t, i) => (
          <button key={i} onClick={() => setTab(i)}
            className="px-5 py-2 rounded-lg text-sm font-medium transition-all"
            style={{ backgroundColor: tab === i ? "var(--primary)" : "transparent", color: tab === i ? "white" : "var(--muted)" }}>
            {t.label}
          </button>
        ))}
      </div>

      <div className="flex gap-6">
        {/* Sidebar filter */}
        {tab === 0 && (
          <aside className="hidden lg:flex flex-col gap-4 w-52 shrink-0">
            <div className="rounded-2xl p-4" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
              <div className="flex items-center gap-2 mb-3">
                <SlidersHorizontal size={15} style={{ color: "var(--muted)" }} />
                <span className="text-sm font-semibold" style={{ color: "var(--text)" }}>Bộ lọc</span>
              </div>

              <div className="space-y-1">
                <p className="text-xs font-semibold mb-2 uppercase tracking-wider" style={{ color: "var(--muted)" }}>Danh mục</p>
                {CATS.map(c => (
                  <button key={c.value} onClick={() => setCat(c.value)}
                    className="w-full text-left px-3 py-2 rounded-lg text-sm transition-colors"
                    style={{ backgroundColor: cat === c.value ? "var(--primary-tint)" : "transparent", color: cat === c.value ? "var(--primary)" : "var(--muted)", fontWeight: cat === c.value ? 600 : 400 }}>
                    {c.label}
                  </button>
                ))}
              </div>

              <div className="mt-4 space-y-1">
                <p className="text-xs font-semibold mb-2 uppercase tracking-wider" style={{ color: "var(--muted)" }}>Tình trạng</p>
                {CONDS.map(c => (
                  <button key={c.value} onClick={() => setCond(c.value)}
                    className="w-full text-left px-3 py-2 rounded-lg text-sm transition-colors"
                    style={{ backgroundColor: cond === c.value ? "var(--primary-tint)" : "transparent", color: cond === c.value ? "var(--primary)" : "var(--muted)", fontWeight: cond === c.value ? 600 : 400 }}>
                    {c.label}
                  </button>
                ))}
              </div>
            </div>
          </aside>
        )}

        {/* Main content */}
        <div className="flex-1 min-w-0">
          {/* Search (explore tab) */}
          {tab === 0 && (
            <div className="relative mb-4">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2" style={{ color: "var(--muted)" }} />
              <input placeholder="Tìm kiếm đồ dùng, sản phẩm..." value={search} onChange={e => setSearch(e.target.value)}
                className="w-full h-10 pl-9 pr-4 rounded-xl border text-sm"
                style={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--text)" }} />
            </div>
          )}

          {loading ? (
            <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                  <Skeleton className="h-44 w-full rounded-none" />
                  <div className="p-3 space-y-2"><Skeleton className="h-4 w-3/4" /><Skeleton className="h-4 w-1/2" /></div>
                </div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="rounded-2xl py-16 text-center" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
              <Tag size={48} className="mx-auto mb-3 opacity-20" style={{ color: "var(--text)" }} />
              <p className="font-semibold mb-2" style={{ color: "var(--text)" }}>
                {tab === 0 ? "Không tìm thấy sản phẩm" : tab === 1 ? "Chưa có tin yêu thích" : "Bạn chưa đăng tin nào"}
              </p>
              {tab === 0 && <Link href="/marketplace/new"><button className="px-5 py-2.5 rounded-xl text-white text-sm font-semibold" style={{ background: "linear-gradient(135deg, #1d4ed8, #3b82f6)" }}>Đăng tin đầu tiên</button></Link>}
            </div>
          ) : (
            <>
              <p className="text-xs mb-3" style={{ color: "var(--muted)" }}>{filtered.length} sản phẩm</p>
              <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
                {filtered.map(l => {
                  const sold = l.status === "sold" || l.status === "completed";
                  return (
                    <Link key={l.id} href={`/marketplace/${l.id}`}>
                      <div className="rounded-2xl overflow-hidden hover:shadow-lg transition-all cursor-pointer group"
                        style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
                        <div className="relative h-44" style={{ backgroundColor: "var(--surface)" }}>
                          {l.images?.[0]
                            ? <img src={l.images[0]} alt={l.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                            : <div className="w-full h-full flex items-center justify-center"><Tag size={32} style={{ color: "var(--border)" }} /></div>}
                          {sold && <div className="absolute inset-0 bg-black/50 flex items-center justify-center"><span className="text-white font-bold text-sm px-3 py-1 rounded-full bg-black/60">Đã bán</span></div>}
                          {tab !== 2 && (
                            <button onClick={e => toggleInterest(e, l)}
                              className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 flex items-center justify-center shadow-sm hover:scale-110 transition-transform"
                              style={{ border: "1px solid var(--border)" }}>
                              <Heart size={15} fill={l.is_interested ? "#ef4444" : "transparent"} style={{ color: l.is_interested ? "#ef4444" : "var(--muted)" }} />
                            </button>
                          )}
                          {l.condition && (
                            <Badge className="absolute bottom-2 left-2 text-[10px]"
                              style={{ backgroundColor: "rgba(0,0,0,0.6)", color: "white", border: "none" }}>
                              {l.condition}
                            </Badge>
                          )}
                        </div>
                        <div className="p-3">
                          <p className="text-sm font-semibold line-clamp-2 mb-1.5" style={{ color: "var(--text)" }}>{l.title}</p>
                          <p className="text-base font-bold mb-1" style={{ color: (!l.price || l.price === 0) ? "var(--success)" : "var(--primary)" }}>
                            {(!l.price || l.price === 0) ? "Miễn phí" : formatVND(l.price)}
                          </p>
                          <div className="flex items-center gap-1.5 text-xs" style={{ color: "var(--muted)" }}>
                            {(l.city ?? (l as Listing & { area?: string }).area) && <><MapPin size={10} /><span>{l.city ?? (l as Listing & { area?: string }).area} ·</span></>}
                            <span>{timeAgo(l.created_at)}</span>
                          </div>
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
