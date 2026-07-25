"use client";

import { Sun, Moon, Monitor } from "lucide-react";
import { useTheme, type Theme } from "@/components/admin-providers/theme-provider";
import { cn } from "@/lib/admin/utils";

const THEME_OPTIONS: { value: Theme; label: string; icon: React.ElementType; description: string }[] = [
  {
    value: "light",
    label: "Sáng",
    icon: Sun,
    description: "Giao diện nền trắng",
  },
  {
    value: "dark",
    label: "Tối",
    icon: Moon,
    description: "Giao diện nền tối",
  },
  {
    value: "system",
    label: "Hệ thống",
    icon: Monitor,
    description: "Theo cài đặt thiết bị",
  },
];

export function ThemeSection() {
  const { theme, resolvedTheme, setTheme } = useTheme();

  return (
    <div
      className="rounded-2xl overflow-hidden"
      style={{ border: "1px solid var(--border)" }}
    >
      {/* Header gradient tím nhạt */}
      <div
        className="px-6 py-4"
        style={{
          background: "linear-gradient(135deg, #EDE9FE 0%, #F5F3FF 100%)",
          borderBottom: "1px solid #DDD6FE",
        }}
      >
        <div className="flex items-center gap-2">
          <div
            className="w-7 h-7 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: "#7C3AED" }}
          >
            <Sun className="w-4 h-4 text-white" />
          </div>
          <div>
            <h2 className="text-sm font-semibold" style={{ color: "#3B0764" }}>
              Giao diện
            </h2>
            <p className="text-xs" style={{ color: "#6D28D9" }}>
              Hiện tại:{" "}
              <span className="font-medium">
                {resolvedTheme === "dark" ? "Tối" : "Sáng"}
              </span>
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6" style={{ backgroundColor: "var(--card)" }}>
        <div className="grid grid-cols-3 gap-3">
          {THEME_OPTIONS.map(({ value, label, icon: Icon, description }) => {
            const isActive = theme === value;
            return (
              <button
                key={value}
                onClick={() => setTheme(value)}
                className={cn(
                  "flex flex-col items-center gap-2 p-4 rounded-xl text-sm font-medium transition-all",
                  "border-2"
                )}
                style={
                  isActive
                    ? {
                        borderColor: "#7C3AED",
                        backgroundColor: "#F5F3FF",
                        color: "#7C3AED",
                      }
                    : {
                        borderColor: "var(--border)",
                        backgroundColor: "var(--surface)",
                        color: "var(--muted)",
                      }
                }
              >
                <Icon className="w-5 h-5" />
                <span>{label}</span>
                <span
                  className="text-xs font-normal"
                  style={{ color: isActive ? "#7C3AED" : "var(--muted)", opacity: 0.8 }}
                >
                  {description}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
