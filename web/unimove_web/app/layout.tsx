import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono, Calistoga } from "next/font/google";
import { ToastProvider } from "@/components/ui/toast";
import { ThemeInit } from "@/components/shared/theme-init";
import "./globals.css";

const inter = Inter({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-inter",
  display: "swap",
});

const calistoga = Calistoga({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-display",
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "UniMove - Chuyển trọ thông minh",
  description: "Nền tảng vận chuyển và chuyển trọ dành cho sinh viên",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#0052FF",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <body
        className={`${inter.className} ${inter.variable} ${calistoga.variable} ${jetbrainsMono.variable} antialiased`}
      >
        <ThemeInit />
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
