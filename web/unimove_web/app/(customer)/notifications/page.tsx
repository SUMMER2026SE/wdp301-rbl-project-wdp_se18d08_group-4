"use client";

import React, { useEffect, useState } from "react";
import { CheckCheck, Bell, Package, ShoppingBag, Zap, Info } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { notificationsApi } from "@/lib/api";
import { timeAgo } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface Notification { id: string; title: string; body: string; type: string; notification_type?: string; is_read: boolean; created_at: string; }

const getIcon = (type: string) => {
  if (type === "order") return { icon: <Package size={18} />, bg: "var(--primary-tint)", color: "var(--primary)" };
  if (type === "marketplace") return { icon: <ShoppingBag size={18} />, bg: "var(--warning-tint)", color: "var(--warning)" };
  if (type === "promo") return { icon: <Zap size={18} />, bg: "var(--success-tint)", color: "var(--success)" };
  return { icon: <Info size={18} />, bg: "var(--surface)", color: "var(--muted)" };
};

export default function NotificationsPage() {
  const { toast } = useToast();
  const [notifs, setNotifs] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    notificationsApi.list({ pageSize: 50 }).then(r => {
      if (r.success && r.data) {
        const d = r.data as { notifications?: Notification[] } | Notification[];
        setNotifs(Array.isArray(d) ? d : (d?.notifications ?? []));
      }
    }).finally(() => setLoading(false));
  }, []);

  const markRead = async (id: string) => {
    await notificationsApi.markRead(id);
    setNotifs(p => p.map(n => n.id === id ? { ...n, is_read: true } : n));
  };

  const markAll = async () => {
    await notificationsApi.markAllRead();
    setNotifs(p => p.map(n => ({ ...n, is_read: true })));
    toast("Đã đánh dấu tất cả là đã đọc", "success");
  };

  const unread = notifs.filter(n => !n.is_read).length;

  return (
    <div className="max-w-2xl space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: "var(--text)" }}>Thông báo</h1>
          <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>{unread > 0 ? `${unread} thông báo chưa đọc` : "Tất cả đã đọc"}</p>
        </div>
        {unread > 0 && (
          <button onClick={markAll} className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold"
            style={{ backgroundColor: "var(--primary-tint)", color: "var(--primary)" }}>
            <CheckCheck size={16} /> Đánh dấu tất cả đã đọc
          </button>
        )}
      </div>

      <div className="rounded-2xl overflow-hidden" style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}>
        {loading ? (
          <div className="p-5 space-y-4">
            {[1, 2, 3, 4].map(i => (
              <div key={i} className="flex gap-3">
                <Skeleton className="w-10 h-10 rounded-xl shrink-0" />
                <div className="flex-1 space-y-2"><Skeleton className="h-4 w-3/4" /><Skeleton className="h-3 w-full" /></div>
              </div>
            ))}
          </div>
        ) : notifs.length === 0 ? (
          <div className="py-16 text-center">
            <Bell size={48} className="mx-auto mb-3 opacity-20" style={{ color: "var(--text)" }} />
            <p className="font-semibold" style={{ color: "var(--text)" }}>Chưa có thông báo nào</p>
          </div>
        ) : (
          notifs.map((n, i) => {
            const { icon, bg, color } = getIcon(n.type ?? n.notification_type ?? "");
            return (
              <div key={n.id}
                className="flex gap-4 px-5 py-4 cursor-pointer hover:opacity-90 transition-opacity"
                style={{
                  backgroundColor: n.is_read ? "transparent" : "var(--primary-tint)",
                  borderBottom: i < notifs.length - 1 ? "1px solid var(--border)" : "none",
                }}
                onClick={() => !n.is_read && markRead(n.id)}>
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
                  style={{ backgroundColor: bg, color }}>
                  {icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-3">
                    <p className="text-sm" style={{ color: "var(--text)", fontWeight: n.is_read ? 500 : 700 }}>
                      {n.title}
                    </p>
                    <span className="text-xs shrink-0" style={{ color: "var(--muted)" }}>{timeAgo(n.created_at)}</span>
                  </div>
                  <p className="text-sm mt-0.5" style={{ color: "var(--muted)" }}>{n.body}</p>
                </div>
                {!n.is_read && (
                  <div className="w-2 h-2 rounded-full mt-2 shrink-0" style={{ backgroundColor: "var(--primary)" }} />
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
