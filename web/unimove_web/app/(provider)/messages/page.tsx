"use client";

import React, { useEffect, useState } from "react";
import { CheckCheck, Bell, Package, Info } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { notificationsApi } from "@/lib/api";
import { timeAgo } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface Notif { id: string; title: string; body: string; type: string; is_read: boolean; created_at: string; }

export default function ProviderMessagesPage() {
  const { toast } = useToast();
  const [notifs, setNotifs] = useState<Notif[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    notificationsApi.list({ pageSize: 50 }).then(r => {
      if (r.success && r.data) {
        const d = r.data as { notifications?: Notif[] } | Notif[];
        setNotifs(Array.isArray(d) ? d : (d?.notifications ?? []));
      }
    }).finally(() => setLoading(false));
  }, []);

  const markRead = async (id: string) => { await notificationsApi.markRead(id); setNotifs(p => p.map(n => n.id === id ? { ...n, is_read: true } : n)); };
  const markAll = async () => { await notificationsApi.markAllRead(); setNotifs(p => p.map(n => ({ ...n, is_read: true }))); toast("Đã đọc tất cả", "success"); };

  const unread = notifs.filter(n => !n.is_read).length;

  return (
    <div className="max-w-2xl space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Thông báo</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>{unread > 0 ? `${unread} chưa đọc` : "Tất cả đã đọc"}</p>
        </div>
        {unread > 0 && (
          <button onClick={markAll} className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold"
            style={{ backgroundColor: "var(--provider-tint)", color: "var(--provider)" }}>
            <CheckCheck size={16} /> Đánh dấu tất cả đã đọc
          </button>
        )}
      </div>

      <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        {loading ? (
          <div className="p-5 space-y-4">{[1, 2, 3].map(i => <div key={i} className="flex gap-3"><Skeleton className="w-10 h-10 rounded-xl shrink-0" /><div className="flex-1 space-y-2"><Skeleton className="h-4 w-3/4" /><Skeleton className="h-3 w-full" /></div></div>)}</div>
        ) : notifs.length === 0 ? (
          <div className="py-16 text-center"><Bell size={48} className="mx-auto mb-3 opacity-20" style={{ color: "var(--text)" }} /><p className="font-semibold" style={{ color: "var(--text)" }}>Chưa có thông báo</p></div>
        ) : notifs.map((n, i) => (
          <div key={n.id}
            className="flex gap-4 px-5 py-4 cursor-pointer hover:opacity-90 transition-opacity"
            style={{ backgroundColor: n.is_read ? "transparent" : "var(--provider-tint)", borderBottom: i < notifs.length - 1 ? "1px solid var(--border)" : "none" }}
            onClick={() => !n.is_read && markRead(n.id)}>
            <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
              style={{ backgroundColor: "var(--surface)", color: "var(--provider)" }}>
              {n.type === "order" ? <Package size={18} /> : <Info size={18} />}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-3">
                <p className="text-sm" style={{ color: "var(--text)", fontWeight: n.is_read ? 500 : 700 }}>{n.title}</p>
                <span className="text-xs shrink-0" style={{ color: "var(--muted)" }}>{timeAgo(n.created_at)}</span>
              </div>
              <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>{n.body}</p>
            </div>
            {!n.is_read && <div className="w-2 h-2 rounded-full mt-2 shrink-0" style={{ backgroundColor: "var(--provider)" }} />}
          </div>
        ))}
      </div>
    </div>
  );
}
