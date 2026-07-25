"use client";

import React, { useEffect, useRef, useState } from "react";
import { Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import type { ProviderReviewItem } from "./ProviderReviewsSection";

interface AiReviewSummaryProps {
  reviews: ProviderReviewItem[];
  /** Don't call Gemini if fewer than this many reviews exist */
  minReviews?: number;
  className?: string;
}

type Status = "idle" | "loading" | "done" | "empty" | "error";

export function AiReviewSummary({
  reviews,
  minReviews = 3,
  className,
}: AiReviewSummaryProps) {
  const [summary, setSummary] = useState<string | null>(null);
  const [status, setStatus] = useState<Status>("idle");
  const calledRef = useRef(false);

  useEffect(() => {
    // Only call once per mount; don't retry on re-renders
    if (calledRef.current) return;
    if (reviews.length < minReviews) {
      setStatus("empty");
      return;
    }

    calledRef.current = true;
    setStatus("loading");

    const payload = reviews.slice(0, 20).map((r) => ({
      rating: r.rating,
      comment: r.comment ?? null,
      tags: r.tags ?? [],
    }));

    fetch("/api/ai/review-summary", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reviews: payload }),
    })
      .then((res) => res.json())
      .then((data: { summary?: string | null }) => {
        console.log("[AiReviewSummary] response:", data);
        if (data.summary) {
          setSummary(data.summary);
          setStatus("done");
        } else {
          setStatus("empty");
        }
      })
      .catch((err) => {
        console.error("[AiReviewSummary] fetch error:", err);
        setStatus("error");
      });
  }, [reviews, minReviews]);

  // Don't render anything if not enough reviews or Gemini returned nothing
  if (status === "idle" || status === "empty") return null;

  return (
    <div
      className={cn(
        "rounded-xl border bg-gradient-to-br from-blue-50/80 to-indigo-50/60",
        "border-blue-100 p-4 mb-5",
        className,
      )}
    >
      {/* Header */}
      <div className="flex items-center gap-2 mb-2">
        <div className="w-6 h-6 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shrink-0">
          <Sparkles size={12} className="text-white" />
        </div>
        <span className="text-xs font-bold text-blue-700 uppercase tracking-wide">
          AI Tóm tắt đánh giá
        </span>
      </div>

      {/* Body */}
      {status === "loading" && (
        <div className="flex items-center gap-2">
          <LoadingDots />
          <span className="text-xs text-gray-400">Đang phân tích đánh giá...</span>
        </div>
      )}

      {status === "done" && summary && (
        <p className="text-sm text-gray-700 leading-relaxed">{summary}</p>
      )}

      {status === "error" && (
        <p className="text-xs text-gray-400 italic">Không thể tải tóm tắt lúc này.</p>
      )}

      {/* Footer attribution */}
      {status === "done" && (
        <p className="text-[10px] text-blue-400/70 mt-2 text-right">
          Tóm tắt bởi Gemini AI · Dựa trên {reviews.length} đánh giá
        </p>
      )}
    </div>
  );
}

function LoadingDots() {
  return (
    <div className="flex gap-1">
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-bounce"
          style={{ animationDelay: `${i * 150}ms` }}
        />
      ))}
    </div>
  );
}
