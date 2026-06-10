"use client";

import React, { useEffect, useState } from "react";
import { Bell, Check, CheckCheck, Package, ShoppingBag, Star, Zap, Info } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { notificationsApi } from "@/lib/api";
import { timeAgo } from "@/lib/utils";
import { useToast } from "@/components/ui/toast";

interface Notification {
  id: string;
  title: string;
  body: string;
  type: string;
  is_read: boolean;
  created_at: string;
  action_url?: string;
}

function getNotifIcon(type: string) {
  const map: Record<string, { icon: React.ReactNode; bg: string; color: string }> = {
    order: { icon: <Package size={18} />, bg: "var(--primary-tint)", color: "var(--primary)" },
    marketplace: { icon: <ShoppingBag size={18} />, bg: "var(--warning-tint)", color: "var(--warning)" },
    review: { icon: <Star size={18} />, bg: "#fef3c7", color: "#d97706" },
    promo: { icon: <Zap size={18} />, bg: "var(--success-tint)", color: "var(--success)" },
  };
  return map[type] ?? { icon: <Info size={18} />, bg: "var(--surface)", color: "var(--muted)" };
}

export default function NotificationsPage() {
  const { toast } = useToast();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchNotifications = async () => {
    setLoading(true);
    try {
      const res = await notificationsApi.getNotifications({ pageSize: 50 });
      if (res.success && res.data) {
        const data = res.data as { notifications?: Notification[] } | Notification[];
        setNotifications(Array.isArray(data) ? data : (data?.notifications ?? []));
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchNotifications(); }, []);

  const markRead = async (id: string) => {
    try {
      await notificationsApi.markRead(id);
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
      );
    } catch {
      // silent
    }
  };

  const markAllRead = async () => {
    try {
      await notificationsApi.markAllRead();
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
      toast("Đã đánh dấu tất cả là đã đọc", "success");
    } catch {
      toast("Thử lại sau", "error");
    }
  };

  const unreadCount = notifications.filter((n) => !n.is_read).length;

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      {/* Header */}
      <div
        className="px-4 pt-12 pb-4 sticky top-0 z-10"
        style={{ backgroundColor: "var(--card)", borderBottom: "1px solid var(--border)" }}
      >
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold" style={{ color: "var(--text)" }}>Thông báo</h1>
            {unreadCount > 0 && (
              <p className="text-xs mt-0.5" style={{ color: "var(--muted)" }}>{unreadCount} chưa đọc</p>
            )}
          </div>
          {unreadCount > 0 && (
            <button
              onClick={markAllRead}
              className="flex items-center gap-1.5 text-sm font-medium px-3 py-1.5 rounded-xl"
              style={{ color: "var(--primary)", backgroundColor: "var(--primary-tint)" }}
            >
              <CheckCheck size={16} /> Đọc tất cả
            </button>
          )}
        </div>
      </div>

      {/* List */}
      <div className="py-2">
        {loading ? (
          <div className="px-4 py-4 space-y-3">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="flex gap-3">
                <Skeleton className="w-10 h-10 rounded-xl shrink-0" />
                <div className="flex-1 space-y-2">
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-3 w-full" />
                  <Skeleton className="h-3 w-1/2" />
                </div>
              </div>
            ))}
          </div>
        ) : notifications.length === 0 ? (
          <div className="text-center py-16 px-4">
            <Bell size={52} className="mx-auto mb-4 opacity-20" style={{ color: "var(--text)" }} />
            <p className="font-semibold mb-1" style={{ color: "var(--text)" }}>Chưa có thông báo</p>
            <p className="text-sm" style={{ color: "var(--muted)" }}>Thông báo mới sẽ xuất hiện ở đây</p>
          </div>
        ) : (
          <div>
            {notifications.map((notif, i) => {
              const { icon, bg, color } = getNotifIcon(notif.type);
              return (
                <button
                  key={notif.id}
                  className="w-full text-left px-4 py-4 flex gap-3 transition-colors hover:opacity-90"
                  style={{
                    backgroundColor: notif.is_read ? "transparent" : "var(--primary-tint)",
                    borderBottom: i < notifications.length - 1 ? "1px solid var(--border)" : "none",
                  }}
                  onClick={() => !notif.is_read && markRead(notif.id)}
                >
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
                    style={{ backgroundColor: bg, color }}
                  >
                    {icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <p
                        className="text-sm font-semibold line-clamp-1"
                        style={{ color: "var(--text)", fontWeight: notif.is_read ? 500 : 700 }}
                      >
                        {notif.title}
                      </p>
                      <span className="text-[11px] shrink-0" style={{ color: "var(--muted)" }}>
                        {timeAgo(notif.created_at)}
                      </span>
                    </div>
                    <p className="text-xs mt-0.5 line-clamp-2" style={{ color: "var(--muted)" }}>
                      {notif.body}
                    </p>
                    {!notif.is_read && (
                      <div className="flex items-center gap-1 mt-1.5">
                        <Check size={11} style={{ color: "var(--primary)" }} />
                        <span className="text-[10px] font-medium" style={{ color: "var(--primary)" }}>Chưa đọc</span>
                      </div>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
