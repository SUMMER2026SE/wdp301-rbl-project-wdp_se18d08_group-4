"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import {
  MessageSquare, Send, ArrowLeft, Package,
  RefreshCw, Search, Phone, MoreVertical,
  CheckCheck, Clock, Smile,
} from "lucide-react";
import { conversationsApi } from "@/lib/api";
import { getStoredUser, type AuthUser } from "@/lib/auth";
import { timeAgo } from "@/lib/utils";

const BRAND = "#1A56DB";

interface Counterpart { id: string; full_name: string; avatar_url?: string; phone?: string; }
interface Order       { id: string; status: string; service_type?: string; }
interface Conversation {
  id: string; order_id: string;
  last_message_preview?: string; last_message_at?: string;
  unread_count: number; order?: Order; counterpart?: Counterpart;
}
interface Message {
  id: string; content: string; is_mine: boolean; created_at: string;
  sender?: { id: string; full_name: string };
}

const SERVICE_MAP: Record<string, { label: string; color: string; bg: string }> = {
  moving:       { label: "Chuyển nhà",  color: "#7C3AED", bg: "#EDE9FE" },
  delivery:     { label: "Giao hàng",   color: "#059669", bg: "#D1FAE5" },
  heavy_lifting:{ label: "Khuân vác",   color: "#D97706", bg: "#FEF3C7" },
};

function Avatar({ name, url, size = 40, online = false }: { name?: string; url?: string; size?: number; online?: boolean }) {
  const initials = (name ?? "?").split(" ").slice(-2).map(w => w[0]).join("").toUpperCase().slice(0, 2);
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      {url ? (
        <img src={url} alt={name} className="rounded-full object-cover w-full h-full" />
      ) : (
        <div className="rounded-full flex items-center justify-center w-full h-full text-white font-bold"
          style={{ fontSize: size * 0.35, background: `linear-gradient(135deg, ${BRAND}, #3B82F6)` }}>
          {initials}
        </div>
      )}
      {online && (
        <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-emerald-400 border-2 border-white" />
      )}
    </div>
  );
}

function ServiceBadge({ type }: { type?: string }) {
  const s = SERVICE_MAP[type ?? ""] ?? { label: "Đơn hàng", color: "#6B7280", bg: "#F3F4F6" };
  return (
    <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold"
      style={{ color: s.color, backgroundColor: s.bg }}>
      {s.label}
    </span>
  );
}

export default function ProviderMessagesPage() {
  const [me,          setMe]          = useState<AuthUser | null>(null);
  const [convos,      setConvos]      = useState<Conversation[]>([]);
  const [filtered,    setFiltered]    = useState<Conversation[]>([]);
  const [search,      setSearch]      = useState("");
  const [loadingList, setLoadingList] = useState(true);
  const [active,      setActive]      = useState<Conversation | null>(null);
  const [messages,    setMessages]    = useState<Message[]>([]);
  const [loadingMsgs, setLoadingMsgs] = useState(false);
  const [input,       setInput]       = useState("");
  const [sending,     setSending]     = useState(false);
  const bottomRef    = useRef<HTMLDivElement>(null);
  const inputRef     = useRef<HTMLTextAreaElement>(null);

  useEffect(() => { setMe(getStoredUser()); }, []);

  const loadConvos = useCallback(() => {
    setLoadingList(true);
    conversationsApi.list().then(r => {
      if (r.success && r.data) {
        setConvos(r.data as Conversation[]);
        setFiltered(r.data as Conversation[]);
      }
    }).finally(() => setLoadingList(false));
  }, []);

  useEffect(() => { loadConvos(); }, [loadConvos]);

  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(!q ? convos : convos.filter(c =>
      c.counterpart?.full_name?.toLowerCase().includes(q) ||
      c.last_message_preview?.toLowerCase().includes(q)
    ));
  }, [search, convos]);

  const openConvo = useCallback((conv: Conversation) => {
    setActive(conv);
    setMessages([]);
    setLoadingMsgs(true);
    conversationsApi.getMessages(conv.order_id).then(r => {
      if (r.success && r.data) {
        const d = r.data as { messages?: Message[] };
        setMessages(d.messages ?? []);
        setConvos(prev => prev.map(c => c.id === conv.id ? { ...c, unread_count: 0 } : c));
      }
    }).finally(() => setLoadingMsgs(false));
    setTimeout(() => inputRef.current?.focus(), 100);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const send = async () => {
    if (!active || !input.trim() || sending) return;
    const text = input.trim();
    setInput("");
    setSending(true);
    const optimistic: Message = {
      id: `opt-${Date.now()}`, content: text, is_mine: true,
      created_at: new Date().toISOString(),
      sender: me ? { id: me.id, full_name: me.full_name } : undefined,
    };
    setMessages(prev => [...prev, optimistic]);
    try {
      const r = await conversationsApi.sendMessage(active.order_id, text);
      if (r.success && r.data) {
        const real = r.data as Message;
        setMessages(prev => prev.map(m => m.id === optimistic.id ? { ...optimistic, ...real } : m));
        setConvos(prev => prev.map(c =>
          c.id === active.id ? { ...c, last_message_preview: text, last_message_at: real.created_at } : c
        ));
      }
    } finally { setSending(false); }
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); }
  };

  const totalUnread = convos.reduce((s, c) => s + c.unread_count, 0);

  return (
    <div className="h-full -m-6 flex overflow-hidden" style={{ background: "#F1F5F9" }}>

      {/* ── Left panel: conversation list ── */}
      <div
        className={`flex flex-col shrink-0 bg-white border-r border-gray-100 ${active ? "hidden lg:flex" : "flex"}`}
        style={{ width: 300 }}
      >
        {/* Panel header */}
        <div className="px-4 pt-5 pb-3 shrink-0">
          <div className="flex items-center justify-between mb-1">
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-bold text-gray-900">Tin nhắn</h2>
              {totalUnread > 0 && (
                <span className="flex items-center justify-center rounded-full text-white text-[10px] font-bold px-1.5 py-0.5 min-w-[20px]"
                  style={{ backgroundColor: BRAND }}>
                  {totalUnread > 99 ? "99+" : totalUnread}
                </span>
              )}
            </div>
            <button onClick={loadConvos}
              className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:bg-gray-100 transition-colors">
              <RefreshCw size={14} />
            </button>
          </div>
          <p className="text-xs text-gray-400">Chat với khách hàng</p>
        </div>

        {/* Search */}
        <div className="px-4 pb-3 shrink-0">
          <div className="flex items-center gap-2 bg-gray-50 rounded-xl px-3 py-2 border border-gray-100">
            <Search size={14} className="text-gray-400 shrink-0" />
            <input
              value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Tìm kiếm..."
              className="flex-1 bg-transparent text-sm text-gray-700 placeholder:text-gray-400 focus:outline-none"
            />
          </div>
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto">
          {loadingList ? (
            <div className="px-4 py-3 space-y-4">
              {[1, 2, 3, 4].map(i => (
                <div key={i} className="flex gap-3 items-center animate-pulse">
                  <div className="w-11 h-11 rounded-full bg-gray-100 shrink-0" />
                  <div className="flex-1 space-y-2">
                    <div className="h-3 w-24 rounded-full bg-gray-100" />
                    <div className="h-2.5 w-36 rounded-full bg-gray-100" />
                  </div>
                </div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full py-16 px-6 text-center">
              <div className="w-16 h-16 rounded-2xl bg-gray-50 flex items-center justify-center mb-4">
                <MessageSquare size={28} className="text-gray-300" />
              </div>
              <p className="font-semibold text-gray-700 mb-1">
                {search ? "Không tìm thấy" : "Chưa có tin nhắn"}
              </p>
              <p className="text-xs text-gray-400 leading-relaxed">
                {search ? "Thử tìm với từ khác" : "Khi khách hàng nhắn tin,\ncuộc trò chuyện sẽ xuất hiện ở đây."}
              </p>
            </div>
          ) : (
            <div>
              {filtered.map(conv => {
                const isActive = active?.id === conv.id;
                return (
                  <button key={conv.id} onClick={() => openConvo(conv)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-left transition-all relative"
                    style={{
                      backgroundColor: isActive ? "#EFF4FE" : "transparent",
                    }}>
                    {isActive && (
                      <span className="absolute left-0 top-2 bottom-2 w-0.5 rounded-r-full"
                        style={{ backgroundColor: BRAND }} />
                    )}
                    <Avatar name={conv.counterpart?.full_name} url={conv.counterpart?.avatar_url} size={44} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-1 mb-0.5">
                        <span className={`text-sm truncate ${conv.unread_count > 0 ? "font-bold text-gray-900" : "font-medium text-gray-700"}`}>
                          {conv.counterpart?.full_name ?? "Khách hàng"}
                        </span>
                        <span className="text-[10px] text-gray-400 shrink-0">
                          {conv.last_message_at ? timeAgo(conv.last_message_at) : ""}
                        </span>
                      </div>
                      <div className="flex items-center justify-between gap-1">
                        <p className={`text-xs truncate flex-1 ${conv.unread_count > 0 ? "font-medium text-gray-600" : "text-gray-400"}`}>
                          {conv.last_message_preview ?? <ServiceBadge type={conv.order?.service_type} />}
                        </p>
                        {conv.unread_count > 0 ? (
                          <span className="flex items-center justify-center rounded-full text-white text-[9px] font-bold shrink-0"
                            style={{ width: 17, height: 17, backgroundColor: BRAND }}>
                            {conv.unread_count > 9 ? "9+" : conv.unread_count}
                          </span>
                        ) : null}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* ── Right panel: chat window ── */}
      <div className={`flex-1 flex flex-col min-w-0 ${active ? "flex" : "hidden lg:flex"}`}>
        {!active ? (
          /* Empty state */
          <div className="flex flex-col items-center justify-center h-full text-center px-8 select-none">
            <div className="w-24 h-24 rounded-3xl flex items-center justify-center mb-6"
              style={{ background: "linear-gradient(135deg, #EFF4FE 0%, #DBEAFE 100%)" }}>
              <MessageSquare size={40} style={{ color: BRAND }} />
            </div>
            <p className="text-xl font-bold text-gray-800 mb-2">Chọn cuộc trò chuyện</p>
            <p className="text-sm text-gray-400 max-w-xs leading-relaxed">
              Chọn một cuộc trò chuyện từ danh sách bên trái để bắt đầu chat với khách hàng
            </p>
          </div>
        ) : (
          <div className="flex flex-col h-full bg-white">

            {/* Chat header */}
            <div className="flex items-center gap-3 px-5 py-3 border-b border-gray-100 shrink-0 bg-white shadow-sm">
              <button onClick={() => setActive(null)}
                className="lg:hidden w-8 h-8 rounded-full flex items-center justify-center text-gray-500 hover:bg-gray-100 transition-colors">
                <ArrowLeft size={18} />
              </button>
              <Avatar name={active.counterpart?.full_name} url={active.counterpart?.avatar_url} size={40} online />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-gray-900 truncate leading-tight">
                  {active.counterpart?.full_name ?? "Khách hàng"}
                </p>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <Package size={11} className="text-gray-400" />
                  <span className="text-xs text-gray-400">
                    #{active.order_id.slice(0, 8).toUpperCase()}
                  </span>
                  {active.order?.service_type && (
                    <>
                      <span className="text-gray-300">·</span>
                      <ServiceBadge type={active.order.service_type} />
                    </>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-1">
                {active.counterpart?.phone && (
                  <a href={`tel:${active.counterpart.phone}`}
                    className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:bg-gray-100 transition-colors">
                    <Phone size={15} />
                  </a>
                )}
                <button className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:bg-gray-100 transition-colors">
                  <MoreVertical size={15} />
                </button>
              </div>
            </div>

            {/* Messages area */}
            <div className="flex-1 overflow-y-auto px-5 py-4 space-y-1"
              style={{ background: "linear-gradient(180deg, #F8FAFF 0%, #F1F5F9 100%)" }}>
              {loadingMsgs ? (
                <div className="space-y-4 py-4">
                  {[1, 2, 3, 4].map(i => (
                    <div key={i} className={`flex ${i % 2 === 0 ? "justify-end" : "justify-start"} animate-pulse`}>
                      <div className="h-10 rounded-2xl bg-gray-200/80" style={{ width: `${30 + i * 12}%` }} />
                    </div>
                  ))}
                </div>
              ) : messages.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full py-12 text-center">
                  <div className="w-14 h-14 rounded-2xl bg-white flex items-center justify-center mb-3 shadow-sm border border-gray-100">
                    <Smile size={22} className="text-gray-300" />
                  </div>
                  <p className="text-sm font-semibold text-gray-500 mb-1">Chưa có tin nhắn</p>
                  <p className="text-xs text-gray-400">Hãy bắt đầu cuộc trò chuyện!</p>
                </div>
              ) : (
                <MessageList messages={messages} counterpart={active.counterpart} />
              )}
              <div ref={bottomRef} />
            </div>

            {/* Input bar */}
            <div className="px-4 py-3 border-t border-gray-100 bg-white shrink-0">
              <div className="flex items-end gap-2 bg-gray-50 rounded-2xl pl-4 pr-2 py-2 border border-gray-200 focus-within:border-blue-400 focus-within:ring-2 focus-within:ring-blue-100 transition-all">
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  onKeyDown={handleKey}
                  placeholder="Nhập tin nhắn..."
                  rows={1}
                  className="flex-1 bg-transparent resize-none text-sm text-gray-900 placeholder:text-gray-400 focus:outline-none py-1.5 max-h-28"
                  style={{ lineHeight: "1.5" }}
                />
                <button
                  onClick={send}
                  disabled={!input.trim() || sending}
                  className="w-9 h-9 rounded-xl flex items-center justify-center text-white transition-all hover:brightness-110 active:scale-95 disabled:opacity-40 shrink-0 mb-0.5"
                  style={{ backgroundColor: BRAND }}>
                  {sending
                    ? <span className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                    : <Send size={15} />}
                </button>
              </div>
              <p className="text-[10px] text-gray-400 text-center mt-1.5">Enter để gửi · Shift+Enter xuống dòng</p>
            </div>

          </div>
        )}
      </div>
    </div>
  );
}

/* ── MessageList: groups messages by date + consecutive sender ── */
function MessageList({ messages, counterpart }: { messages: Message[]; counterpart?: Counterpart }) {
  // Group by date
  const groups: { date: string; msgs: Message[] }[] = [];
  for (const msg of messages) {
    const d = new Date(msg.created_at).toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" });
    const last = groups[groups.length - 1];
    if (last && last.date === d) last.msgs.push(msg);
    else groups.push({ date: d, msgs: [msg] });
  }

  return (
    <>
      {groups.map(group => (
        <div key={group.date}>
          {/* Date divider */}
          <div className="flex items-center gap-3 my-4">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-[10px] text-gray-400 font-medium px-2 py-1 bg-white rounded-full border border-gray-100 shrink-0">
              {group.date}
            </span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          {group.msgs.map((msg, i) => {
            const prev = group.msgs[i - 1];
            const next = group.msgs[i + 1];
            const samePrevSender = prev?.is_mine === msg.is_mine;
            const sameNextSender = next?.is_mine === msg.is_mine;
            const isFirst = !samePrevSender;
            const isLast  = !sameNextSender;

            return (
              <div key={msg.id}
                className={`flex ${msg.is_mine ? "justify-end" : "justify-start"} ${isLast ? "mb-3" : "mb-0.5"}`}>

                {/* Avatar for others, only on last of group */}
                {!msg.is_mine && (
                  <div className="w-7 shrink-0 self-end mr-1.5">
                    {isLast && <Avatar name={counterpart?.full_name} url={counterpart?.avatar_url} size={28} />}
                  </div>
                )}

                <div className={`max-w-[68%] flex flex-col ${msg.is_mine ? "items-end" : "items-start"}`}>
                  {/* Sender label on first bubble of group */}
                  {isFirst && !msg.is_mine && (
                    <p className="text-[10px] text-gray-400 font-medium mb-1 ml-1">
                      {counterpart?.full_name ?? "Khách hàng"}
                    </p>
                  )}

                  <div
                    className="px-3.5 py-2 text-sm leading-relaxed"
                    style={msg.is_mine ? {
                      background: `linear-gradient(135deg, ${BRAND}, #3B82F6)`,
                      color: "#fff",
                      borderRadius: isFirst && isLast ? "18px" : isFirst ? "18px 18px 4px 18px" : isLast ? "18px 4px 18px 18px" : "18px 4px 4px 18px",
                    } : {
                      backgroundColor: "#fff",
                      color: "#1F2937",
                      border: "1px solid #E5E7EB",
                      borderRadius: isFirst && isLast ? "18px" : isFirst ? "18px 18px 18px 4px" : isLast ? "4px 18px 18px 18px" : "4px 18px 18px 4px",
                    }}>
                    {msg.content}
                  </div>

                  {/* Timestamp on last bubble of group */}
                  {isLast && (
                    <div className={`flex items-center gap-1 mt-1 ${msg.is_mine ? "flex-row-reverse" : ""}`}>
                      <Clock size={9} className="text-gray-300" />
                      <span className="text-[10px] text-gray-400">{timeAgo(msg.created_at)}</span>
                      {msg.is_mine && <CheckCheck size={12} className="text-blue-400" />}
                    </div>
                  )}
                </div>

                {/* Spacer for own messages */}
                {msg.is_mine && <div className="w-7 shrink-0" />}
              </div>
            );
          })}
        </div>
      ))}
    </>
  );
}
