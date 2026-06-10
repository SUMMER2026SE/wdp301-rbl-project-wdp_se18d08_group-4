"use client";

import { useEffect, useState } from "react";
import { getStoredUser } from "@/lib/auth";
import CustomerProfilePage from "./customer-profile";
import ProviderProfilePage from "./provider-profile";

export default function ProfilePage() {
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => { setRole(getStoredUser()?.role ?? null); }, []);
  if (!role) return null;
  return role === "provider" ? <ProviderProfilePage /> : <CustomerProfilePage />;
}
