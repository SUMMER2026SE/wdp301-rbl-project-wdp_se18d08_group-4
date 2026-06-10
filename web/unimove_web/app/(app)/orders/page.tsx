"use client";

import { useEffect, useState } from "react";
import { getStoredUser } from "@/lib/auth";
import CustomerOrdersPage from "./customer-orders";
import ProviderOrdersPage from "./provider-orders";

export default function OrdersPage() {
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => { setRole(getStoredUser()?.role ?? null); }, []);
  if (!role) return null;
  return role === "provider" ? <ProviderOrdersPage /> : <CustomerOrdersPage />;
}
