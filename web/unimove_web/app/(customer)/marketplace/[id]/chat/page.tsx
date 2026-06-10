"use client";

import React, { useEffect, useState, useRef } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, Send } from "lucide-react";
import { marketplaceApi } from "@/lib/api";
import { getStoredUser } from "@/lib/auth";
import { timeAgo } from "@/lib/utils";

interface Message { id:string; content:string; text?:string; from_buyer?:boolean; sender_id?:string; created_at:string; }
interface Listing { id:string; title:string; seller_id?:string; seller?:{full_name:string}; profiles?:{id?:string;full_name?:string}; }

export default function MarketplaceChatPage() {
  const {id} = useParams<{id:string}>();
  const [listing, setListing] = useState<Listing|null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const currentUser = getStoredUser();
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!currentUser) return;
    marketplaceApi.get(id).then(r => {
      if (r.success && r.data) {
        const l = r.data as Listing;
        setListing(l);
        const sellerId = l.seller_id ?? l.profiles?.id;
        const buyerId = currentUser.id !== sellerId ? currentUser.id : "";
        if (buyerId) {
          marketplaceApi.getMessages(id, buyerId).then(mr => {
            if (mr.success && mr.data) {
              const d = mr.data as {messages?:Message[]}|Message[];
              setMessages(Array.isArray(d) ? d : (d?.messages ?? []));
            }
          });
        }
      }
    });
  }, [id, currentUser]);

  useEffect(() => { bottomRef.current?.scrollIntoView({behavior:"smooth"}); }, [messages]);

  const sendMsg = async () => {
    if (!text.trim() || !listing || !currentUser) return;
    const sellerId = listing.seller_id ?? listing.profiles?.id;
    const buyerId = currentUser.id !== sellerId ? currentUser.id : "";
    if (!buyerId) return;
    setSending(true);
    try {
      const r = await marketplaceApi.sendMessage(id, buyerId, text.trim());
      if (r.success && r.data) { setMessages(p=>[...p, r.data as Message]); setText(""); }
    } catch {}
    finally { setSending(false); }
  };

  return (
    <div className="h-screen flex flex-col" style={{ backgroundColor:"var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor:"var(--card)", borderBottom:"1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href={`/marketplace/${id}`} className="p-2 rounded-xl" style={{ backgroundColor:"var(--surface)" }}>
            <ArrowLeft size={20} style={{ color:"var(--text)" }} />
          </Link>
          <div className="flex-1 min-w-0">
            <p className="font-bold truncate" style={{ color:"var(--text)" }}>{listing?.seller?.full_name ?? "Người bán"}</p>
            <p className="text-xs truncate" style={{ color:"var(--muted)" }}>{listing?.title}</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {messages.length===0 && (
          <div className="text-center py-10"><p className="text-sm" style={{ color:"var(--muted)" }}>Bắt đầu trò chuyện về sản phẩm này</p></div>
        )}
        {messages.map(m => {
          const mine = m.from_buyer === true;
          const text = m.content ?? m.text ?? "";
          return (
            <div key={m.id} className={`flex ${mine?"justify-end":"justify-start"}`}>
              <div className="max-w-[75%] px-4 py-2.5 rounded-2xl"
                style={{ backgroundColor:mine?"var(--primary)":"var(--card)", color:mine?"white":"var(--text)", border:mine?"none":"1px solid var(--border)" }}>
                <p className="text-sm">{text}</p>
                <p className="text-[10px] mt-1 opacity-70 text-right">{timeAgo(m.created_at)}</p>
              </div>
            </div>
          );
        })}
        <div ref={bottomRef} />
      </div>

      <div className="px-4 py-3 pb-6" style={{ backgroundColor:"var(--card)", borderTop:"1px solid var(--border)" }}>
        <div className="flex gap-2">
          <input type="text" value={text} onChange={e=>setText(e.target.value)}
            onKeyDown={e=>e.key==="Enter"&&sendMsg()}
            placeholder="Nhập tin nhắn..."
            className="flex-1 h-11 rounded-xl border px-4 text-sm"
            style={{ backgroundColor:"var(--surface)", borderColor:"var(--border)", color:"var(--text)" }} />
          <button onClick={sendMsg} disabled={!text.trim()||sending}
            className="w-11 h-11 rounded-xl flex items-center justify-center disabled:opacity-50"
            style={{ background:"linear-gradient(135deg,#1d4ed8,#3b82f6)" }}>
            <Send size={18} className="text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}
