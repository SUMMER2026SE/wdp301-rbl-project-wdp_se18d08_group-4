"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Truck,
  ShoppingBag,
  Shield,
  CheckCircle,
  MapPin,
  Clock,
  DollarSign,
  Users,
  ArrowRight,
  ChevronRight,
  Moon,
  Sun,
} from "lucide-react";
import { isAuthenticated, getStoredUser, getRoleHome } from "@/lib/auth";
import { SectionLabel } from "@/components/landing/section-label";
import { fadeInUp, stagger, viewport } from "@/components/landing/motion";
import {
  btnOutline,
  btnPrimary,
  container,
  displayFont,
  dotPatternDark,
  featureCard,
  gradientBg,
  gradientText,
  iconGradient,
  invertedSection,
  monoFont,
  sectionPy,
  stepCard,
} from "@/lib/landing-classes";
import { cn } from "@/lib/utils";

const NAV_LINKS = [
  { label: "Tính năng", href: "#features" },
  { label: "Dịch vụ", href: "#services" },
  { label: "Đối tác", href: "#partners" },
  { label: "Liên hệ", href: "#contact" },
];

const STATS = [
  { value: "1,000+", label: "Sinh viên" },
  { value: "200+", label: "Nhà xe" },
  { value: "4.8★", label: "Đánh giá" },
  { value: "99%", label: "Hài lòng" },
];

const FEATURES = [
  { icon: DollarSign, title: "Báo giá minh bạch", desc: "Nhận báo giá chi tiết từ nhiều nhà xe trong 30 phút. Không phụ phí ẩn." },
  { icon: Shield, title: "Thanh toán an toàn", desc: "Tiền đặt cọc qua escrow PayOS. Hoàn tiền 100% nếu có vấn đề." },
  { icon: Clock, title: "Đặt lịch linh hoạt", desc: "Đặt trước hoặc đặt ngay. Nhà xe sẵn sàng 7 ngày/tuần." },
  { icon: MapPin, title: "Không cần bản đồ", desc: "Chỉ cần mô tả địa chỉ. Hệ thống tính giá tự động." },
  { icon: Users, title: "Nhà xe đã xác minh", desc: "Kiểm tra CMND, bằng lái và đăng ký xe trước khi tham gia.", pulse: true },
  { icon: ShoppingBag, title: "Chợ sinh viên", desc: "Mua bán đồ cũ miễn phí trong cộng đồng sinh viên." },
];

const STEPS = [
  { step: "01", title: "Nhập địa chỉ", desc: "Điền điểm đón, điểm đến và mô tả đồ đạc." },
  { step: "02", title: "Nhận báo giá", desc: "Nhà xe gửi báo giá trong 30 phút." },
  { step: "03", title: "Chọn & Đặt cọc", desc: "Chọn nhà xe, đặt cọc 30% qua PayOS." },
  { step: "04", title: "Chuyển & Thanh toán", desc: "Hoàn thành chuyến, thanh toán phần còn lại." },
];

const PROVIDER_BENEFITS = [
  "Nhận đơn hàng phù hợp xe của bạn",
  "Thu nhập 90% sau mỗi chuyến",
  "Quản lý lịch trình theo ý muốn",
  "Hỗ trợ 24/7 từ đội ngũ UniMove",
];

function SectionHeader({ label, title, subtitle }: { label: string; title: React.ReactNode; subtitle: string }) {
  return (
    <motion.div
      initial="hidden"
      whileInView="visible"
      viewport={viewport}
      variants={stagger}
      className="mx-auto mb-16 flex max-w-2xl flex-col items-center text-center"
    >
      <motion.div variants={fadeInUp}>
        <SectionLabel pulse={false}>{label}</SectionLabel>
      </motion.div>
      <motion.h2 variants={fadeInUp} className={cn(displayFont, "mt-6 text-3xl leading-[1.15] md:text-[3.25rem]")}>
        {title}
      </motion.h2>
      <motion.p variants={fadeInUp} className="mt-4 text-base leading-relaxed text-muted-foreground md:text-lg">
        {subtitle}
      </motion.p>
    </motion.div>
  );
}

export default function LandingPage() {
  const router = useRouter();
  const [darkMode, setDarkMode] = useState(false);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    setDarkMode(document.documentElement.classList.contains("dark"));
    if (isAuthenticated()) {
      const user = getStoredUser();
      if (user) {
        router.replace(getRoleHome(user.role));
        return;
      }
    }
    setChecked(true);
  }, [router]);

  const toggleTheme = () => {
    const isDark = document.documentElement.classList.toggle("dark");
    setDarkMode(isDark);
    localStorage.setItem("unimove-theme", isDark ? "dark" : "light");
  };

  if (!checked) return null;

  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Navbar */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className={cn(container, "flex h-16 items-center justify-between gap-4")}>
          <Link href="/" className="flex items-center gap-2.5">
            <div className={cn("flex h-9 w-9 items-center justify-center rounded-xl text-white", gradientBg, "shadow-[0_4px_14px_rgba(0,82,255,0.25)]")}>
              <Truck size={18} />
            </div>
            <span className={cn(displayFont, "text-lg")}>UniMove</span>
          </Link>

          <nav className="hidden items-center gap-8 md:flex">
            {NAV_LINKS.map(({ label, href }) => (
              <a key={href} href={href} className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground">
                {label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label="Đổi giao diện"
              className="flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-card text-muted-foreground hover:text-foreground"
            >
              {darkMode ? <Sun size={16} /> : <Moon size={16} />}
            </button>
            <Link href="/login" className={cn(btnOutline, "hidden h-10 px-4 text-sm sm:inline-flex")}>
              Đăng nhập
            </Link>
            <Link href="/register" className={cn(btnPrimary, "h-10 gap-1.5 px-4 text-sm")}>
              Đăng ký miễn phí
              <ArrowRight size={14} className="transition-transform group-hover:translate-x-0.5" />
            </Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="relative overflow-hidden border-b border-border">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(0,82,255,0.08),transparent_55%)]" />

        <div className={cn(container, "relative z-10 py-28 lg:py-36")}>
          <motion.div
            initial="hidden"
            animate="visible"
            variants={stagger}
            className="mx-auto flex max-w-3xl flex-col items-center text-center lg:mx-0 lg:max-w-2xl lg:items-start lg:text-left"
          >
            <motion.div variants={fadeInUp}>
              <SectionLabel>Nền tảng chuyển trọ #1</SectionLabel>
            </motion.div>

            <motion.h1
              variants={fadeInUp}
              className={cn(displayFont, "mt-8 text-[2.75rem] leading-[1.05] tracking-[-0.02em] md:text-6xl lg:text-[5.25rem]")}
            >
              Chuyển trọ{" "}
              <span className="relative inline-block">
                <span className={gradientText}>thông minh</span>
                <span
                  aria-hidden
                  className="absolute -bottom-1 left-0 h-3 w-full rounded-sm bg-gradient-to-r from-accent/15 to-accent-secondary/10 md:-bottom-2 md:h-4"
                />
              </span>
              <br />
              cho sinh viên
            </motion.h1>

            <motion.p variants={fadeInUp} className="mt-6 max-w-xl text-lg leading-relaxed text-muted-foreground">
              Kết nối sinh viên với nhà vận chuyển uy tín. Báo giá minh bạch, không phụ phí ẩn. Đặt dịch vụ trong 2 phút.
            </motion.p>

            <motion.div variants={fadeInUp} className="mt-10 flex w-full flex-col gap-4 sm:w-auto sm:flex-row">
              <Link href="/register" className={cn(btnPrimary, "group h-14 w-full px-8 sm:w-auto")}>
                Bắt đầu ngay — Miễn phí
                <ArrowRight size={18} className="transition-transform group-hover:translate-x-1" />
              </Link>
              <Link href="/login" className={cn(btnOutline, "h-14 w-full px-8 sm:w-auto")}>
                Đăng nhập tài khoản
              </Link>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Stats — inverted section */}
      <section className={cn(invertedSection, dotPatternDark, "py-16")}>
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={viewport}
          variants={stagger}
          className={cn(container, "grid grid-cols-2 gap-8 md:grid-cols-4")}
        >
          {STATS.map(({ value, label }, i) => (
            <motion.div
              key={label}
              variants={fadeInUp}
              className={cn("text-center", i < STATS.length - 1 && "md:border-r md:border-white/10")}
            >
              <p className={cn(displayFont, "text-3xl text-white md:text-4xl")}>{value}</p>
              <p className="mt-1 text-sm text-white/70">{label}</p>
            </motion.div>
          ))}
        </motion.div>
      </section>

      {/* Features */}
      <section id="features" className={sectionPy}>
        <div className={container}>
          <SectionHeader
            label="Tính năng"
            title={<>Tại sao chọn <span className={gradientText}>UniMove</span>?</>}
            subtitle="Giải pháp chuyển trọ được thiết kế dành riêng cho sinh viên"
          />

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={viewport}
            variants={stagger}
            className="grid gap-6 md:grid-cols-2 lg:grid-cols-3"
          >
            {FEATURES.map(({ icon: Icon, title, desc, pulse }) => (
              <motion.div key={title} variants={fadeInUp} className={featureCard}>
                <div className="pointer-events-none absolute inset-0 bg-gradient-to-br from-accent/[0.03] to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
                <div className="relative">
                  <div className={iconGradient}>
                    <Icon size={22} />
                  </div>
                  <div className="mb-2 flex items-center gap-2">
                    <h3 className="text-lg font-semibold tracking-[-0.01em]">{title}</h3>
                    {pulse && <span className="h-2 w-2 animate-pulse rounded-full bg-accent motion-reduce:animate-none" />}
                  </div>
                  <p className="text-sm leading-relaxed text-muted-foreground">{desc}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Steps — timeline */}
      <section id="services" className={cn("border-y border-border bg-muted", sectionPy)}>
        <div className={container}>
          <SectionHeader
            label="Quy trình"
            title={<>Quy trình <span className={gradientText}>đơn giản</span></>}
            subtitle="Chỉ 4 bước để hoàn tất một chuyến chuyển trọ"
          />

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={viewport}
            variants={stagger}
            className="grid gap-8 md:grid-cols-4"
          >
            {STEPS.map(({ step, title, desc }, i) => (
              <motion.div key={step} variants={fadeInUp} className={cn(stepCard, "relative")}>
                {i < STEPS.length - 1 && (
                  <div aria-hidden className="absolute left-[calc(50%+2.5rem)] top-10 hidden w-[calc(100%-5rem)] md:flex md:items-center">
                    <div className="h-px flex-1 bg-border" />
                    <div className={cn("flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-white", gradientBg)}>
                      <ChevronRight size={14} />
                    </div>
                  </div>
                )}
                <p className={cn(monoFont, "text-3xl font-medium", gradientText)}>{step}</p>
                <h3 className="mt-4 font-semibold">{title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Partner — inverted */}
      <section id="partners" className={cn(invertedSection, dotPatternDark, sectionPy)}>
        <div className={cn(container, "max-w-3xl")}>
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={viewport}
            variants={stagger}
            className="flex flex-col"
          >
            <motion.div variants={fadeInUp}>
              <SectionLabel pulse={false}>Đối tác vận chuyển</SectionLabel>
            </motion.div>
            <motion.h2 variants={fadeInUp} className={cn(displayFont, "mt-6 text-3xl leading-[1.15] text-white md:text-[3.25rem]")}>
              Bạn có <span className={gradientText}>xe tải</span>?
            </motion.h2>
            <motion.p variants={fadeInUp} className="mt-4 max-w-lg text-lg leading-relaxed text-white/80">
              Tham gia mạng lưới nhà vận chuyển UniMove. Thu nhập linh hoạt, nhận đơn khi rảnh.
            </motion.p>
            <motion.ul variants={fadeInUp} className="mt-8 space-y-3">
              {PROVIDER_BENEFITS.map((item) => (
                <li key={item} className="flex items-center gap-3 text-sm text-white/90">
                  <CheckCircle size={16} className="shrink-0 text-accent-secondary" />
                  {item}
                </li>
              ))}
            </motion.ul>
            <motion.div variants={fadeInUp}>
              <Link href="/register" className={cn(btnPrimary, "group mt-10 h-12 gap-2 px-7")}>
                Đăng ký làm đối tác
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-1" />
              </Link>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Final CTA */}
      <section className={sectionPy}>
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={viewport}
          variants={stagger}
          className="mx-auto flex max-w-2xl flex-col items-center px-6 text-center"
        >
          <motion.div variants={fadeInUp}>
            <SectionLabel>Bắt đầu ngay</SectionLabel>
          </motion.div>
          <motion.h2 variants={fadeInUp} className={cn(displayFont, "mt-6 text-3xl leading-[1.15] md:text-[3.25rem]")}>
            Sẵn sàng <span className={gradientText}>chuyển trọ</span>?
          </motion.h2>
          <motion.p variants={fadeInUp} className="mt-4 text-muted-foreground">
            Tạo tài khoản miễn phí và đặt dịch vụ ngay hôm nay.
          </motion.p>
          <motion.div variants={fadeInUp} className="mt-10 flex w-full flex-col gap-4 sm:w-auto sm:flex-row">
            <Link href="/register" className={cn(btnPrimary, "h-14 w-full px-8 sm:w-auto")}>
              Tạo tài khoản — Miễn phí
            </Link>
            <Link href="/login" className={cn(btnOutline, "h-14 w-full px-8 sm:w-auto")}>
              Đã có tài khoản? Đăng nhập
            </Link>
          </motion.div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer id="contact" className="border-t border-border py-12">
        <div className={cn(container, "flex flex-col items-center justify-between gap-6 text-center md:flex-row md:text-left")}>
          <div className="flex items-center gap-2.5">
            <div className={cn("flex h-8 w-8 items-center justify-center rounded-lg text-white", gradientBg)}>
              <Truck size={14} />
            </div>
            <span className={displayFont}>UniMove</span>
          </div>
          <p className="text-sm text-muted-foreground">© 2026 UniMove. Dành cho sinh viên Việt Nam.</p>
          <div className="flex gap-6">
            {["Điều khoản", "Bảo mật", "Liên hệ"].map((item) => (
              <a key={item} href="#" className="text-sm text-muted-foreground transition-colors hover:text-foreground">
                {item}
              </a>
            ))}
          </div>
        </div>
      </footer>
    </div>
  );
}
