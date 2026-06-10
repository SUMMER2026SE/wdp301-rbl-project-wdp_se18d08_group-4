"use client";

import { useEffect, useState } from "react";
import { getStoredUser } from "@/lib/auth";
import CustomerOrderDetailPage from "./customer-order-detail";
import ProviderOrderDetailPage from "./provider-order-detail";

export default function OrderDetailPage() {
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => { setRole(getStoredUser()?.role ?? null); }, []);
  if (!role) return null;
  return role === "provider" ? <ProviderOrderDetailPage /> : <CustomerOrderDetailPage />;
}
