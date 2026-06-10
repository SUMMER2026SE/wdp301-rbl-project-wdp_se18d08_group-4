import { getStoredToken } from "./auth";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000/api";

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  meta?: { page: number; pageSize: number; total: number; pages: number };
  listings?: T[];
  notifications?: T[];
  unread_count?: number;
}

export interface ApiError extends Error { status?: number; }

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
  const token = getStoredToken();
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers: { ...headers, ...options.headers } });
  const data = await res.json();
  if (!res.ok) {
    const err: ApiError = new Error(data.message || data.error || "API error");
    err.status = res.status;
    throw err;
  }
  return data;
}

async function upload<T>(endpoint: string, formData: FormData): Promise<ApiResponse<T>> {
  const token = getStoredToken();
  const headers: Record<string, string> = {};
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${API_BASE}${endpoint}`, { method: "POST", headers, body: formData });
  const data = await res.json();
  if (!res.ok) { const err: ApiError = new Error(data.message || data.error || "Upload failed"); err.status = res.status; throw err; }
  return data;
}

function buildUrl(endpoint: string, params?: Record<string, unknown>): string {
  if (!params) return endpoint;
  const sp = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null) sp.append(k, String(v)); });
  const q = sp.toString();
  return q ? `${endpoint}?${q}` : endpoint;
}

const get  = <T>(ep: string, p?: Record<string, unknown>) => request<T>(buildUrl(ep, p));
const post  = <T>(ep: string, body?: unknown) => request<T>(ep, { method: "POST", body: JSON.stringify(body) });
const patch = <T>(ep: string, body?: unknown) => request<T>(ep, { method: "PATCH", body: JSON.stringify(body) });
const put   = <T>(ep: string, body?: unknown) => request<T>(ep, { method: "PUT",   body: JSON.stringify(body) });
const del   = <T>(ep: string) => request<T>(ep, { method: "DELETE" });

/** Chuẩn hóa order từ DB sang field frontend dùng */
export function normalizeOrder(raw: Record<string, unknown>) {
  const delivery = (raw.delivery_address ?? raw.dropoff_address) as string | undefined;
  const pickup = raw.pickup_address as string | undefined;
  return {
    ...raw,
    pickup_address: pickup ?? "",
    dropoff_address: delivery ?? "",
    delivery_address: delivery ?? "",
    floor_number: raw.floor_number ?? raw.pickup_floor,
    estimated_price: raw.estimated_price ?? raw.total_price ?? raw.base_price,
    final_price: raw.final_price ?? raw.total_price,
    description: raw.description ?? raw.pickup_notes,
    status: raw.status as string | undefined,
  };
}

/** Chuẩn hóa listing marketplace */
export function normalizeListing(raw: Record<string, unknown>) {
  const profiles = raw.profiles as { id?: string; full_name?: string; avatar_url?: string } | undefined;
  const ownerId = (raw.owner_id ?? profiles?.id) as string | undefined;
  return {
    ...raw,
    city: raw.city ?? raw.area,
    area: raw.area ?? raw.city,
    seller_id: raw.seller_id ?? ownerId,
    seller: raw.seller ?? (profiles ? { full_name: profiles.full_name, avatar_url: profiles.avatar_url } : undefined),
  };
}

/** Chuẩn hóa notification */
export function normalizeNotification(raw: Record<string, unknown>) {
  return {
    ...raw,
    type: raw.type ?? raw.notification_type,
  };
}

/** Chuẩn hóa chat message */
export function normalizeMessage(raw: Record<string, unknown>, buyerId?: string) {
  const fromBuyer = raw.from_buyer as boolean | undefined;
  return {
    ...raw,
    content: raw.content ?? raw.text,
    sender_id: raw.sender_id ?? (fromBuyer === true ? buyerId : fromBuyer === false ? "seller" : undefined),
    from_buyer: fromBuyer,
  };
}

function normalizeOrdersResponse(res: ApiResponse) {
  if (!res.success || !res.data) return res;
  const d = res.data as Record<string, unknown> | unknown[];
  if (Array.isArray(d)) {
    return { ...res, data: d.map(o => normalizeOrder(o as Record<string, unknown>)) };
  }
  if (Array.isArray(d.orders)) {
    return { ...res, data: { ...d, orders: (d.orders as Record<string, unknown>[]).map(normalizeOrder) } };
  }
  return { ...res, data: normalizeOrder(d as Record<string, unknown>) };
}

function normalizeListingsResponse(res: ApiResponse) {
  const listings = (res.listings ?? (res.data as { listings?: unknown[] })?.listings) as Record<string, unknown>[] | undefined;
  if (!listings) return res;
  const normalized = listings.map(normalizeListing);
  return { ...res, success: res.success ?? true, data: { listings: normalized }, listings: normalized };
}

function normalizeNotificationsResponse(res: ApiResponse) {
  const raw = res as ApiResponse & { notifications?: Record<string, unknown>[] };
  if (raw.notifications) {
    const notifications = raw.notifications.map(normalizeNotification);
    return { success: true, data: { notifications } };
  }
  return res;
}

function normalizeUnreadCountResponse(res: ApiResponse) {
  const raw = res as ApiResponse & { unread_count?: number };
  if (raw.unread_count !== undefined) {
    return { success: true, data: { count: raw.unread_count } };
  }
  return res;
}

/* ── Auth ── */
export const authApi = {
  login: (email: string, password: string) => post("/auth/login", { email, password }),
  register: (body: Record<string, unknown>) => post("/auth/register", body),
  forgotPassword: (email: string) => post("/auth/forgot-password", { email }),
  resetPassword: (email: string, token: string, newPassword: string) =>
    post("/auth/reset-password", { email, token, newPassword }),
  getMe: () => get("/auth/me"),
  updateMe: (body: Record<string, unknown>) => patch("/auth/me", body),
  changePassword: (currentPassword: string, newPassword: string) =>
    post("/auth/change-password", { currentPassword, newPassword }),
};

/* ── Customer ── */
export const customerApi = {
  getMe: () => get("/customers/me"),
  updateMe: (body: Record<string, unknown>) => patch("/customers/me", body),
  getRecentPlaces: async () => {
    const res = await get<Array<{ title?: string; address: string; lat?: number; lng?: number }>>("/customers/me/recent-places");
    if (res.success && Array.isArray(res.data)) {
      return {
        ...res,
        data: res.data.map((p, i) => ({
          id: p.address || String(i),
          address: p.address,
          label: p.title ?? p.address.split(",")[0]?.trim(),
        })),
      };
    }
    return res;
  },
  uploadAvatar: (file: File) => { const fd = new FormData(); fd.append("avatar", file); return upload("/customers/me/avatar", fd); },
};

/* ── Orders ── */
export const ordersApi = {
  list: async (params?: Record<string, unknown>) => {
    const res = await get("/orders", params);
    if (res.success && Array.isArray(res.data)) {
      let orders = (res.data as Record<string, unknown>[]).map(normalizeOrder);
      const status = params?.status as string | undefined;
      if (status) {
        const allowed = status.split(",").map(s => s.trim()).filter(Boolean);
        if (allowed.length) orders = orders.filter(o => allowed.includes(String(o.status)));
      }
      return { ...res, data: orders };
    }
    return normalizeOrdersResponse(res);
  },
  get: async (id: string) => normalizeOrdersResponse(await get(`/orders/${id}`)),
  create: (body: Record<string, unknown>) => post("/orders", {
    ...body,
    number_of_helpers: body.number_of_helpers ?? body.num_helpers,
    delivery_address: body.delivery_address ?? body.dropoff_address,
  }),
  respond: (id: string, action: "accept" | "reject", _estimatedPrice?: number, notes?: string) =>
    post(`/orders/${id}/respond`, {
      response: action === "accept" ? "accepted" : "declined",
      decline_reason: notes || undefined,
    }),
};

/* ── Providers ── */
export const providersApi = {
  browse: (params?: Record<string, unknown>) => get("/providers/browse", params),
  getById: (id: string) => get(`/providers/${id}`),
};

/* ── Notifications ── */
export const notificationsApi = {
  list: async (params?: Record<string, unknown>) => {
    const mapped = params?.pageSize ? { ...params, limit: params.pageSize } : params;
    const res = await get("/notifications", mapped);
    return normalizeNotificationsResponse(res);
  },
  unreadCount: async () => normalizeUnreadCountResponse(await get("/notifications/unread-count")),
  markRead: async (id: string) => {
    const res = await patch(`/notifications/${id}/read`, {});
    return { success: !!(res as { ok?: boolean }).ok || res.success !== false };
  },
  markAllRead: async () => {
    const res = await patch("/notifications/read-all", {});
    return { success: !!(res as { ok?: boolean }).ok || res.success !== false };
  },
};

/* ── Marketplace ── */
export const marketplaceApi = {
  list: async (p?: Record<string, unknown>) => {
    const params = p ? { ...p } : {};
    if (params.search) { params.keyword = params.search; delete params.search; }
    if (params.category === "kitchen") params.category = "appliances";
    const res = await get("/marketplace/listings", params);
    return normalizeListingsResponse(res);
  },
  myListings: async () => normalizeListingsResponse(await get("/marketplace/my-listings")),
  create: (body: Record<string, unknown>) => post("/marketplace/listings", body),
  uploadImages: async (files: File[]) => {
    const urls: string[] = [];
    for (const file of files) {
      const fd = new FormData();
      fd.append("image", file);
      const res = await upload<{ url: string }>("/marketplace/listings/images", fd);
      if (!res.success || !res.data?.url) {
        throw new Error(res.message || "Upload ảnh thất bại");
      }
      urls.push(res.data.url);
    }
    return { success: true, data: urls };
  },
  get: async (id: string) => {
    const res = await get(`/marketplace/listings/${id}`);
    if (res.success && res.data) {
      return { ...res, data: normalizeListing(res.data as Record<string, unknown>) };
    }
    return res;
  },
  updateStatus: (id: string, status: string) => patch(`/marketplace/listings/${id}/status`, { status }),
  addInterest: (id: string) => post(`/marketplace/listings/${id}/interest`, {}),
  removeInterest: (id: string) => del(`/marketplace/listings/${id}/interest`),
  myInterests: async () => normalizeListingsResponse(await get("/marketplace/my-interests")),
  getMessages: async (listingId: string, buyerId: string) => {
    const res = await get(`/marketplace/listings/${listingId}/conversations/${buyerId}/messages`);
    if (res.success && res.data) {
      const d = res.data as { messages?: Record<string, unknown>[] };
      const messages = (d.messages ?? []).map(m => normalizeMessage(m, buyerId));
      return { ...res, data: { ...d, messages } };
    }
    return res;
  },
  sendMessage: (listingId: string, buyerId: string, content: string) =>
    post(`/marketplace/listings/${listingId}/conversations/${buyerId}/messages`, { text: content }),
  sellerStats: (sellerId: string) => get(`/marketplace/seller/${sellerId}/stats`),
  rate: (id: string, rating: number, comment?: string) => post(`/marketplace/listings/${id}/rating`, { rating, comment }),
  bump: (id: string) => post(`/marketplace/listings/${id}/bump`, {}),
};

/* ── Payments ── */
export const paymentsApi = {
  createDeposit: (orderId: string, amount: number, method: string) =>
    post("/payments/deposit", { order_id: orderId, amount, payment_method: method }),
};

/* ── Provider profile (upload docs) ── */
export const providerApi = {
  uploadDocuments: (files: Record<string, File>) => {
    const fd = new FormData();
    Object.entries(files).forEach(([k, v]) => fd.append(k, v));
    return upload("/providers/me/documents", fd);
  },
  uploadAvatar: (file: File) => {
    const fd = new FormData(); fd.append("avatar", file);
    return upload("/customers/me/avatar", fd);
  },
};
