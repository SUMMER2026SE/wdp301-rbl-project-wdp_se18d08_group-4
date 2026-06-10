"use client";

import React, { useRef, useState } from "react";
import Link from "next/link";
import { ArrowLeft, Upload, CheckCircle, FileText, Camera, Shield, AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { providerProfileApi } from "@/lib/api";
import { getStoredUser } from "@/lib/auth";
import { useToast } from "@/components/ui/toast";

interface DocFile { file: File | null; preview: string | null; }

const DOC_TYPES = [
  { key: "cccd_front", label: "CCCD/CMND (mặt trước)", icon: FileText, required: true },
  { key: "cccd_back", label: "CCCD/CMND (mặt sau)", icon: FileText, required: true },
  { key: "vehicle_registration", label: "Đăng ký xe", icon: FileText, required: true },
  { key: "driver_license", label: "Bằng lái xe", icon: FileText, required: true },
  { key: "vehicle_photo", label: "Ảnh phương tiện", icon: Camera, required: false },
];

export default function DocumentsPage() {
  const { toast } = useToast();
  const user = getStoredUser();
  const [docs, setDocs] = useState<Record<string, DocFile>>(
    Object.fromEntries(DOC_TYPES.map((d) => [d.key, { file: null, preview: null }]))
  );
  const [loading, setLoading] = useState(false);
  const fileRefs = useRef<Record<string, HTMLInputElement | null>>({});

  const handleFileChange = (key: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const preview = URL.createObjectURL(file);
    setDocs((prev) => ({ ...prev, [key]: { file, preview } }));
  };

  const handleSubmit = async () => {
    const required = DOC_TYPES.filter((d) => d.required);
    const missing = required.filter((d) => !docs[d.key].file);
    if (missing.length > 0) {
      toast(`Vui lòng upload: ${missing.map((d) => d.label).join(", ")}`, "error");
      return;
    }
    setLoading(true);
    try {
      const files: Record<string, File> = {};
      Object.entries(docs).forEach(([key, val]) => { if (val.file) files[key] = val.file; });
      await providerProfileApi.uploadDocuments(files);
      toast("Upload giấy tờ thành công! Chờ admin xét duyệt.", "success");
    } catch (err) {
      toast(err instanceof Error ? err.message : "Upload thất bại", "error");
    } finally { setLoading(false); }
  };

  const uploadedCount = Object.values(docs).filter((d) => d.file !== null).length;

  return (
    <div className="min-h-screen" style={{ backgroundColor: "var(--bg)" }}>
      <div className="px-4 pt-12 pb-4" style={{ backgroundColor: "var(--card)", borderBottom: "1px solid var(--border)" }}>
        <div className="flex items-center gap-3">
          <Link href="/dashboard" className="p-2 rounded-xl" style={{ backgroundColor: "var(--surface)" }}>
            <ArrowLeft size={20} style={{ color: "var(--text)" }} />
          </Link>
          <div>
            <h1 className="text-lg font-bold" style={{ color: "var(--text)" }}>Xác minh tài khoản</h1>
            <p className="text-xs" style={{ color: "var(--muted)" }}>{uploadedCount}/{DOC_TYPES.length} giấy tờ đã tải lên</p>
          </div>
        </div>
      </div>

      <div className="px-4 py-4 space-y-4">
        {/* Status */}
        {user?.is_verified ? (
          <Card className="p-4" style={{ backgroundColor: "var(--success-tint)", borderColor: "var(--success)" + "44" }}>
            <div className="flex items-center gap-3">
              <CheckCircle size={24} style={{ color: "var(--success)" }} />
              <div>
                <p className="font-bold" style={{ color: "var(--success)" }}>Tài khoản đã được xác minh</p>
                <p className="text-xs mt-0.5" style={{ color: "var(--success)" }}>Bạn có thể nhận đơn hàng bình thường</p>
              </div>
            </div>
          </Card>
        ) : (
          <Card className="p-4" style={{ backgroundColor: "var(--warning-tint)", borderColor: "var(--warning)" + "44" }}>
            <div className="flex items-center gap-3">
              <AlertTriangle size={24} style={{ color: "var(--warning)" }} />
              <div>
                <p className="font-bold" style={{ color: "var(--warning)" }}>Chưa xác minh</p>
                <p className="text-xs mt-0.5" style={{ color: "var(--warning)" }}>Upload đủ giấy tờ để được duyệt trong 24h</p>
              </div>
            </div>
          </Card>
        )}

        {/* Info */}
        <Card className="p-4">
          <div className="flex items-start gap-3">
            <Shield size={18} style={{ color: "var(--primary)", flexShrink: 0 }} />
            <div>
              <p className="text-sm font-semibold mb-1" style={{ color: "var(--text)" }}>Tại sao cần xác minh?</p>
              <ul className="text-xs space-y-1" style={{ color: "var(--muted)" }}>
                <li>• Tăng độ tin cậy với khách hàng</li>
                <li>• Bắt buộc để nhận đơn hàng</li>
                <li>• Được ưu tiên hiển thị trong danh sách</li>
              </ul>
            </div>
          </div>
        </Card>

        {/* Document uploads */}
        <div className="space-y-3">
          {DOC_TYPES.map(({ key, label, icon: Icon, required }) => {
            const doc = docs[key];
            const isUploaded = !!doc.file;
            return (
              <div key={key}>
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  ref={(el) => { fileRefs.current[key] = el; }}
                  onChange={(e) => handleFileChange(key, e)}
                />
                <button
                  onClick={() => fileRefs.current[key]?.click()}
                  className="w-full p-4 rounded-2xl border-2 flex items-center gap-3 transition-all text-left"
                  style={{
                    backgroundColor: isUploaded ? "var(--success-tint)" : "var(--card)",
                    borderColor: isUploaded ? "var(--success)" : "var(--border)",
                  }}
                >
                  {doc.preview ? (
                    <img src={doc.preview} alt="" className="w-14 h-14 rounded-xl object-cover shrink-0" />
                  ) : (
                    <div className="w-14 h-14 rounded-xl flex items-center justify-center shrink-0"
                      style={{ backgroundColor: isUploaded ? "var(--success-tint)" : "var(--surface)" }}>
                      {isUploaded ? (
                        <CheckCircle size={24} style={{ color: "var(--success)" }} />
                      ) : (
                        <Upload size={24} style={{ color: "var(--muted)" }} />
                      )}
                    </div>
                  )}
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-semibold" style={{ color: isUploaded ? "var(--success)" : "var(--text)" }}>
                        {label}
                      </p>
                      {required && !isUploaded && (
                        <span className="text-[10px] px-1.5 py-0.5 rounded-full text-white" style={{ backgroundColor: "var(--error)" }}>
                          Bắt buộc
                        </span>
                      )}
                    </div>
                    <p className="text-xs mt-0.5" style={{ color: "var(--muted)" }}>
                      {isUploaded ? "✓ Đã tải lên - Nhấn để thay đổi" : "Nhấn để chọn ảnh"}
                    </p>
                  </div>
                </button>
              </div>
            );
          })}
        </div>

        <Button variant="gradient" size="xl" className="w-full gap-2" loading={loading} onClick={handleSubmit}>
          <Upload size={20} /> Gửi giấy tờ xác minh
        </Button>
      </div>
    </div>
  );
}
