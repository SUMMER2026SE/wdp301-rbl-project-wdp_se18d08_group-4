import { BottomNav } from "@/components/layout/bottom-nav";
import { AuthGuard } from "@/components/providers/auth-guard";

export default function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <div className="min-h-screen pb-nav" style={{ backgroundColor: "var(--bg)" }}>
        {children}
      </div>
      <BottomNav />
    </AuthGuard>
  );
}
