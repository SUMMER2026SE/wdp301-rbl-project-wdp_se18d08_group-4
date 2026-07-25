import { NextRequest, NextResponse } from "next/server";

const GEMINI_API_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

export async function POST(req: NextRequest) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "Gemini API key not configured" }, { status: 500 });
  }

  let body: { reviews?: Array<{ rating: number; comment?: string | null; tags?: string[] }> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
  }

  const reviews = body.reviews ?? [];
  if (reviews.length === 0) {
    return NextResponse.json({ summary: null });
  }

  // Build a compact review list for the prompt (avoid sending too much text)
  const reviewLines = reviews
    .slice(0, 20)
    .map((r, i) => {
      const stars = `${r.rating}/5 sao`;
      const comment = r.comment?.trim() ? `"${r.comment.trim().slice(0, 120)}"` : "";
      const tags = r.tags?.length ? `tags: [${r.tags.join(", ")}]` : "";
      const parts = [stars, comment, tags].filter(Boolean).join(" — ");
      return `${i + 1}. ${parts}`;
    })
    .join("\n");

  // Count positive signals for richer context
  const allTags = reviews.flatMap((r) => r.tags ?? []);
  const tagFreq: Record<string, number> = {};
  for (const t of allTags) tagFreq[t] = (tagFreq[t] ?? 0) + 1;
  const topTags = Object.entries(tagFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([tag, count]) => `${tag} (${count} lần)`)
    .join(", ");

  const avgRating = (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1);

  const prompt = `Bạn là trợ lý tóm tắt đánh giá cho nền tảng vận chuyển chuyển trọ sinh viên UniMove.

Thống kê đánh giá của nhà xe:
- Số đánh giá: ${reviews.length}
- Điểm trung bình: ${avgRating}/5
- Tags phổ biến nhất: ${topTags || "không có"}

Chi tiết từng đánh giá:
${reviewLines}

Hãy viết ĐÚNG 1-2 câu ngắn gọn bằng tiếng Việt, tóm tắt điểm nổi bật của nhà xe dựa trên dữ liệu trên.
Quy tắc:
- Bắt đầu bằng "Nhà xe được khách hàng đánh giá" hoặc "Khách hàng nhận xét".
- Dù ít hay nhiều review, vẫn phải viết dựa trên dữ liệu có sẵn (rating, tags).
- Không dùng gạch đầu dòng. Chỉ trả về câu tóm tắt, không giải thích thêm.`;

  try {
    const geminiRes = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.4,
          maxOutputTokens: 200,
          topP: 0.9,
        },
      }),
    });

    if (!geminiRes.ok) {
      const err = await geminiRes.text();
      console.error("[Gemini] API error:", err);
      return NextResponse.json({ summary: null });
    }

    const data = await geminiRes.json();
    const text: string =
      data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

    // If Gemini returns empty, build a basic fallback from the data we have
    if (!text) {
      const avgRating2 = (reviews.reduce((s: number, r: { rating: number }) => s + r.rating, 0) / reviews.length).toFixed(1);
      const fallback = `Khách hàng đánh giá nhà xe ${avgRating2}/5 sao với ${reviews.length} lượt đánh giá.`;
      return NextResponse.json({ summary: fallback });
    }

    return NextResponse.json({ summary: text });
  } catch (err) {
    console.error("[Gemini] Fetch failed:", err);
    return NextResponse.json({ summary: null });
  }
}
