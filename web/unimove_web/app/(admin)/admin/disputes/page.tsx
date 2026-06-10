"use client";

export const dynamic = "force-dynamic";


import React, { useState, useEffect, useCallback, useTransition } from "react";
import { AlertTriangle, RefreshCw, DollarSign } from "lucide-react";

import {
  getDisputes,
  getDisputeById,
  resolveDispute,
  getRefunds,
  approveRefund,
} from "@/lib/admin/queries/disputes";
import type { Dispute, Refund, DisputeStatus, DisputeType } from "@/lib/admin/types";
import { formatVND, formatDateTime } from "@/lib/admin/formatters";
import { cn } from "@/lib/admin/utils";

import { PageHeader } from "@/components/admin-dashboard/page-header";
import { StatusBadge } from "@/components/admin-dashboard/status-badge";
import { EmptyState } from "@/components/admin-dashboard/empty-state";
import { Pagination } from "@/components/admin-dashboard/pagination";
import { Button } from "@/components/admin-ui/button";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/admin-ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogClose,
} from "@/components/admin-ui/dialog";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/admin-ui/select";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const DISPUTE_TYPE_LABELS: Record<DisputeType, string> = {
  payment: "Thanh toán",
  service_quality: "Chất lượng dịch vụ",
  damage: "Hư hỏng hàng hóa",
  cancellation: "Hủy đơn",
  other: "Khác",
};

const PRIORITY_LABELS: Record<string, { label: string; className: string }> = {
  low: { label: "Thấp", className: "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400" },
  normal: { label: "Bình thường", className: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400" },
  high: { label: "Cao", className: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400" },
  urgent: { label: "Khẩn cấp", className: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400" },
};

function PriorityBadge({ priority }: { priority: string }) {
  const cfg = PRIORITY_LABELS[priority] ?? { label: priority, className: "bg-gray-100 text-gray-600" };
  return (
    <span className={cn("inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium whitespace-nowrap", cfg.className)}>
      {cfg.label}
    </span>
  );
}

// ---------------------------------------------------------------------------
// Types for dispute detail
// ---------------------------------------------------------------------------

interface DisputeMessage {
  id: string;
  content: string;
  created_at: string;
  sender?: { id: string; full_name: string; role: string; avatar_url: string | null };
}

interface DisputeDetail extends Dispute {
  messages?: DisputeMessage[];
}

// ---------------------------------------------------------------------------
// Dispute Detail Dialog
// ---------------------------------------------------------------------------

interface DisputeDetailDialogProps {
  disputeId: string | null;
  open: boolean;
  onClose: () => void;
  onResolved: () => void;
}

function DisputeDetailDialog({ disputeId, open, onClose, onResolved }: DisputeDetailDialogProps) {
  const [detail, setDetail] = useState<DisputeDetail | null>(null);
  const [messages, setMessages] = useState<DisputeMessage[]>([]);
  const [loading, setLoading] = useState(false);

  const [resolution, setResolution] = useState("");
  const [resolutionType, setResolutionType] = useState("no_action");
  const [refundAmount, setRefundAmount] = useState("");
  const [submitting, startSubmit] = useTransition();

  useEffect(() => {
    if (!open || !disputeId) return;
    setLoading(true);
    setResolution("");
    setResolutionType("no_action");
    setRefundAmount("");
    getDisputeById(disputeId).then(({ dispute, messages: msgs }) => {
      setDetail(dispute as DisputeDetail | null);
      setMessages(msgs as DisputeMessage[]);
      setLoading(false);
    });
  }, [open, disputeId]);

  const needsRefund = resolutionType === "refund" || resolutionType === "partial_refund";

  const handleResolve = () => {
    if (!disputeId || !resolution.trim()) return;
    startSubmit(async () => {
      const adminId = "admin"; // placeholder — replace with session user id
      const refund = needsRefund && refundAmount ? parseFloat(refundAmount) : null;
      const { error } = await resolveDispute(disputeId, adminId, resolution, resolutionType, refund);
      if (!error) {
        onResolved();
        onClose();
      }
    });
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose(); }}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Chi tiết khiếu nại</DialogTitle>
        </DialogHeader>

        {loading && (
          <div className="flex items-center justify-center py-10">
            <RefreshCw className="w-6 h-6 animate-spin" style={{ color: "var(--muted)" }} />
          </div>
        )}

        {!loading && detail && (
          <div className="space-y-5">
            {/* Meta */}
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <span style={{ color: "var(--muted)" }}>Mã đơn: </span>
                <span className="font-medium" style={{ color: "var(--text)" }}>
                  #{(detail.order as { order_number?: string } | undefined)?.order_number ?? detail.order_id}
                </span>
              </div>
              <div>
                <span style={{ color: "var(--muted)" }}>Loại: </span>
                <span className="font-medium" style={{ color: "var(--text)" }}>
                  {DISPUTE_TYPE_LABELS[detail.dispute_type]}
                </span>
              </div>
              <div>
                <span style={{ color: "var(--muted)" }}>Người khiếu nại: </span>
                <span className="font-medium" style={{ color: "var(--text)" }}>
                  {detail.raiser?.full_name ?? "—"} ({detail.raised_by_role === "customer" ? "Khách hàng" : "Tài xế"})
                </span>
              </div>
              <div>
                <span style={{ color: "var(--muted)" }}>Trạng thái: </span>
                <StatusBadge type="dispute" status={detail.status} />
              </div>
            </div>

            {/* Subject & Description */}
            <div>
              <p className="text-sm font-semibold mb-1" style={{ color: "var(--text)" }}>{detail.subject}</p>
              <p className="text-sm leading-relaxed" style={{ color: "var(--muted)" }}>{detail.description}</p>
            </div>

            {/* Evidence Images */}
            {detail.evidence_images && detail.evidence_images.length > 0 && (
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: "var(--muted)" }}>
                  Bằng chứng ({detail.evidence_images.length} ảnh)
                </p>
                <div className="grid grid-cols-4 gap-2">
                  {detail.evidence_images.map((url, i) => (
                    <a key={i} href={url} target="_blank" rel="noopener noreferrer">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={url}
                        alt={`Bằng chứng ${i + 1}`}
                        className="w-full aspect-square object-cover rounded-lg border"
                        style={{ borderColor: "var(--border)" }}
                      />
                    </a>
                  ))}
                </div>
              </div>
            )}

            {/* Messages */}
            {messages.length > 0 && (
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: "var(--muted)" }}>
                  Tin nhắn ({messages.length})
                </p>
                <div
                  className="rounded-xl border p-3 space-y-3 max-h-48 overflow-y-auto"
                  style={{ borderColor: "var(--border)", backgroundColor: "var(--surface)" }}
                >
                  {messages.map((msg) => (
                    <div key={msg.id}>
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="text-xs font-medium" style={{ color: "var(--text)" }}>
                          {msg.sender?.full_name ?? "—"}
                        </span>
                        <span className="text-xs" style={{ color: "var(--muted)" }}>
                          · {formatDateTime(msg.created_at)}
                        </span>
                      </div>
                      <p className="text-sm" style={{ color: "var(--muted)" }}>{msg.content}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Resolution Form — only for open/investigating disputes */}
            {(detail.status === "open" || detail.status === "investigating") && (
              <div className="rounded-xl border p-4 space-y-3" style={{ borderColor: "var(--border)" }}>
                <p className="text-sm font-semibold" style={{ color: "var(--text)" }}>Giải quyết khiếu nại</p>

                <div>
                  <label className="block text-xs font-medium mb-1" style={{ color: "var(--muted)" }}>
                    Loại giải quyết
                  </label>
                  <Select value={resolutionType} onValueChange={setResolutionType}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="no_action">Không xử phạt</SelectItem>
                      <SelectItem value="refund">Hoàn tiền toàn bộ</SelectItem>
                      <SelectItem value="partial_refund">Hoàn tiền một phần</SelectItem>
                      <SelectItem value="provider_penalty">Phạt tài xế</SelectItem>
                      <SelectItem value="customer_penalty">Phạt khách hàng</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {needsRefund && (
                  <div>
                    <label className="block text-xs font-medium mb-1" style={{ color: "var(--muted)" }}>
                      Số tiền hoàn (VND)
                    </label>
                    <input
                      type="number"
                      min={0}
                      value={refundAmount}
                      onChange={(e) => setRefundAmount(e.target.value)}
                      placeholder="Nhập số tiền hoàn..."
                      className="w-full h-10 px-3 text-sm rounded-xl border outline-none transition-colors"
                      style={{
                        backgroundColor: "var(--surface)",
                        borderColor: "var(--border)",
                        color: "var(--text)",
                      }}
                    />
                  </div>
                )}

                <div>
                  <label className="block text-xs font-medium mb-1" style={{ color: "var(--muted)" }}>
                    Nội dung giải quyết
                  </label>
                  <textarea
                    value={resolution}
                    onChange={(e) => setResolution(e.target.value)}
                    rows={3}
                    placeholder="Mô tả quyết định giải quyết..."
                    className="w-full px-3 py-2 text-sm rounded-xl border outline-none resize-none transition-colors"
                    style={{
                      backgroundColor: "var(--surface)",
                      borderColor: "var(--border)",
                      color: "var(--text)",
                    }}
                  />
                </div>
              </div>
            )}
          </div>
        )}

        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline" size="sm">Đóng</Button>
          </DialogClose>
          {detail && (detail.status === "open" || detail.status === "investigating") && (
            <Button
              size="sm"
              disabled={!resolution.trim() || submitting}
              onClick={handleResolve}
            >
              {submitting ? "Đang xử lý..." : "Giải quyết"}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ---------------------------------------------------------------------------
// Disputes Tab
// ---------------------------------------------------------------------------

type DisputeRow = {
  id: string;
  dispute_type: DisputeType;
  subject: string;
  status: DisputeStatus;
  priority: string;
  created_at: string;
  order?: { id: string; order_number: string } | null;
  raiser?: { id: string; full_name: string; role: string } | null;
};

function DisputesTab() {
  const [disputes, setDisputes] = useState<DisputeRow[]>([]);
  const [meta, setMeta] = useState({ page: 1, pageSize: 20, total: 0, totalPages: 0 });
  const [status, setStatus] = useState<DisputeStatus | "all">("all");
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const result = await getDisputes({
      page,
      pageSize: 20,
      status: status === "all" ? undefined : status,
    });
    setDisputes(result.data as unknown as DisputeRow[]);
    setMeta(result.meta);
    setLoading(false);
  }, [page, status]);

  useEffect(() => { load(); }, [load]);

  const handleStatusChange = (val: string) => {
    setStatus(val as DisputeStatus | "all");
    setPage(1);
  };

  return (
    <div className="space-y-4">
      {/* Filter bar */}
      <div className="flex items-center gap-3">
        <Select value={status} onValueChange={handleStatusChange}>
          <SelectTrigger className="w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            <SelectItem value="open">Đang mở</SelectItem>
            <SelectItem value="investigating">Đang điều tra</SelectItem>
            <SelectItem value="resolved">Đã giải quyết</SelectItem>
            <SelectItem value="closed">Đã đóng</SelectItem>
          </SelectContent>
        </Select>
        <span className="text-sm ml-auto" style={{ color: "var(--muted)" }}>
          {meta.total} khiếu nại
        </span>
      </div>

      {/* Table */}
      <div
        className="rounded-2xl shadow-sm overflow-hidden"
        style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}
      >
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <RefreshCw className="w-5 h-5 animate-spin" style={{ color: "var(--muted)" }} />
          </div>
        ) : disputes.length === 0 ? (
          <EmptyState
            icon={AlertTriangle}
            title="Không có khiếu nại"
            description="Chưa có khiếu nại nào phù hợp bộ lọc."
          />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    {["#Mã đơn", "Người khiếu nại", "Loại", "Tiêu đề", "Ưu tiên", "Trạng thái", "Ngày tạo", ""].map((h) => (
                      <th
                        key={h}
                        className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide"
                        style={{ color: "var(--muted)" }}
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {disputes.map((d) => (
                    <tr
                      key={d.id}
                      style={{ borderBottom: "1px solid var(--border)" }}
                      className="transition-colors hover:bg-[var(--primary-tint)]/30"
                    >
                      <td className="px-4 py-3 font-medium" style={{ color: "var(--text)" }}>
                        #{d.order?.order_number ?? d.id.slice(0, 8)}
                      </td>
                      <td className="px-4 py-3">
                        <div style={{ color: "var(--text)" }}>{d.raiser?.full_name ?? "—"}</div>
                        <div className="text-xs" style={{ color: "var(--muted)" }}>
                          {d.raiser?.role === "customer" ? "Khách hàng" : d.raiser?.role === "provider" ? "Tài xế" : "—"}
                        </div>
                      </td>
                      <td className="px-4 py-3" style={{ color: "var(--muted)" }}>
                        {DISPUTE_TYPE_LABELS[d.dispute_type]}
                      </td>
                      <td className="px-4 py-3 max-w-[200px]">
                        <span className="line-clamp-2" style={{ color: "var(--text)" }}>{d.subject}</span>
                      </td>
                      <td className="px-4 py-3">
                        <PriorityBadge priority={d.priority} />
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge type="dispute" status={d.status} />
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--muted)" }}>
                        {formatDateTime(d.created_at)}
                      </td>
                      <td className="px-4 py-3">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => { setSelectedId(d.id); setDialogOpen(true); }}
                        >
                          Xem chi tiết
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination
              page={meta.page}
              totalPages={meta.totalPages}
              total={meta.total}
              pageSize={meta.pageSize}
              onPageChange={setPage}
            />
          </>
        )}
      </div>

      <DisputeDetailDialog
        disputeId={selectedId}
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        onResolved={load}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Approve Refund Confirmation Dialog
// ---------------------------------------------------------------------------

interface ApproveRefundDialogProps {
  refundId: string | null;
  open: boolean;
  onClose: () => void;
  onApproved: () => void;
}

function ApproveRefundDialog({ refundId, open, onClose, onApproved }: ApproveRefundDialogProps) {
  const [pending, startTransition] = useTransition();

  const handleApprove = () => {
    if (!refundId) return;
    startTransition(async () => {
      const adminId = "admin"; // placeholder — replace with session user id
      const { error } = await approveRefund(refundId, adminId);
      if (!error) {
        onApproved();
        onClose();
      }
    });
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose(); }}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>Xác nhận duyệt hoàn tiền</DialogTitle>
        </DialogHeader>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          Bạn có chắc chắn muốn duyệt yêu cầu hoàn tiền này không? Hành động này không thể hoàn tác.
        </p>
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline" size="sm">Hủy</Button>
          </DialogClose>
          <Button size="sm" disabled={pending} onClick={handleApprove}>
            {pending ? "Đang xử lý..." : "Duyệt hoàn tiền"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ---------------------------------------------------------------------------
// Refunds Tab
// ---------------------------------------------------------------------------

type RefundRow = {
  id: string;
  refund_amount: number;
  refund_reason: string;
  status: string;
  created_at: string;
  order?: { id: string; order_number: string } | null;
  requester?: { id: string; full_name: string; role: string } | null;
};

function RefundsTab() {
  const [refunds, setRefunds] = useState<RefundRow[]>([]);
  const [meta, setMeta] = useState({ page: 1, pageSize: 20, total: 0, totalPages: 0 });
  const [statusFilter, setStatusFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [approveId, setApproveId] = useState<string | null>(null);
  const [approveOpen, setApproveOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const result = await getRefunds({
      page,
      pageSize: 20,
      status: statusFilter === "all" ? undefined : statusFilter,
    });
    setRefunds(result.data as unknown as RefundRow[]);
    setMeta(result.meta);
    setLoading(false);
  }, [page, statusFilter]);

  useEffect(() => { load(); }, [load]);

  const handleStatusChange = (val: string) => {
    setStatusFilter(val);
    setPage(1);
  };

  return (
    <div className="space-y-4">
      {/* Filter bar */}
      <div className="flex items-center gap-3">
        <Select value={statusFilter} onValueChange={handleStatusChange}>
          <SelectTrigger className="w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            <SelectItem value="pending">Đang chờ</SelectItem>
            <SelectItem value="completed">Đã hoàn tiền</SelectItem>
            <SelectItem value="failed">Thất bại</SelectItem>
          </SelectContent>
        </Select>
        <span className="text-sm ml-auto" style={{ color: "var(--muted)" }}>
          {meta.total} yêu cầu
        </span>
      </div>

      {/* Table */}
      <div
        className="rounded-2xl shadow-sm overflow-hidden"
        style={{ backgroundColor: "var(--card)", border: "1px solid var(--border)" }}
      >
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <RefreshCw className="w-5 h-5 animate-spin" style={{ color: "var(--muted)" }} />
          </div>
        ) : refunds.length === 0 ? (
          <EmptyState
            icon={DollarSign}
            title="Không có yêu cầu hoàn tiền"
            description="Chưa có yêu cầu hoàn tiền nào phù hợp bộ lọc."
          />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    {["#Mã đơn", "Người yêu cầu", "Số tiền hoàn", "Lý do", "Trạng thái", "Ngày tạo", ""].map((h) => (
                      <th
                        key={h}
                        className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide"
                        style={{ color: "var(--muted)" }}
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {refunds.map((r) => (
                    <tr
                      key={r.id}
                      style={{ borderBottom: "1px solid var(--border)" }}
                      className="transition-colors hover:bg-[var(--primary-tint)]/30"
                    >
                      <td className="px-4 py-3 font-medium" style={{ color: "var(--text)" }}>
                        #{r.order?.order_number ?? r.id.slice(0, 8)}
                      </td>
                      <td className="px-4 py-3">
                        <div style={{ color: "var(--text)" }}>{r.requester?.full_name ?? "—"}</div>
                        <div className="text-xs" style={{ color: "var(--muted)" }}>
                          {r.requester?.role === "customer" ? "Khách hàng" : r.requester?.role === "provider" ? "Tài xế" : "—"}
                        </div>
                      </td>
                      <td className="px-4 py-3 font-semibold" style={{ color: "var(--text)" }}>
                        {formatVND(r.refund_amount)}
                      </td>
                      <td className="px-4 py-3 max-w-[200px]">
                        <span className="line-clamp-2" style={{ color: "var(--muted)" }}>{r.refund_reason}</span>
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge type="payment" status={r.status} />
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap" style={{ color: "var(--muted)" }}>
                        {formatDateTime(r.created_at)}
                      </td>
                      <td className="px-4 py-3">
                        {r.status === "pending" && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => { setApproveId(r.id); setApproveOpen(true); }}
                          >
                            Duyệt hoàn tiền
                          </Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination
              page={meta.page}
              totalPages={meta.totalPages}
              total={meta.total}
              pageSize={meta.pageSize}
              onPageChange={setPage}
            />
          </>
        )}
      </div>

      <ApproveRefundDialog
        refundId={approveId}
        open={approveOpen}
        onClose={() => setApproveOpen(false)}
        onApproved={load}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

export default function DisputesPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Khiếu nại & Hoàn tiền"
        description="Quản lý khiếu nại và yêu cầu hoàn tiền của người dùng"
      />

      <Tabs defaultValue="disputes">
        <TabsList>
          <TabsTrigger value="disputes">Khiếu nại</TabsTrigger>
          <TabsTrigger value="refunds">Hoàn tiền</TabsTrigger>
        </TabsList>

        <TabsContent value="disputes">
          <DisputesTab />
        </TabsContent>

        <TabsContent value="refunds">
          <RefundsTab />
        </TabsContent>
      </Tabs>
    </div>
  );
}
