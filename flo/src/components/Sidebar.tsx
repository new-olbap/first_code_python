"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { NAV } from "@/lib/nav";
import Shape3D from "@/components/Shape3D";
import type { Role } from "@/lib/supabase/server";

// Ordinateur : colonne collée à gauche. Mobile : barre d'icônes collée en bas.
export default function Sidebar({ orgName, role }: { orgName: string; role: Role }) {
  const path = usePathname();
  return (
    <nav
      aria-label="Navigation principale"
      className="fixed z-20 flex gap-1 overflow-x-auto border-line bg-[#0d0d0d] p-2
        inset-x-0 bottom-0 border-t
        md:inset-x-auto md:bottom-auto md:left-0 md:top-0 md:h-screen md:w-64 md:flex-col md:border-r md:border-t-0 md:p-4"
    >
      <Link href="/" className="hidden md:block px-3 pb-6 pt-2">
        <span className="flex items-center gap-3"><span className="text-3xl font-black tracking-tight">Flo</span><Shape3D /></span>
        <span className="mt-1 block truncate text-xs font-medium text-muted">{orgName}</span>
      </Link>
      {NAV.filter((n) => !n.ownerOnly || role === "owner").map(({ href, label, icon: Icon }) => {
        const active = path === href;
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            title={label}
            className={`flex shrink-0 items-center gap-3 px-3 py-2.5 text-sm font-medium transition
              ${active ? "bg-ink text-bg" : "text-muted hover:bg-surface hover:text-ink"}`}
          >
            <Icon size={20} aria-hidden />
            <span className="hidden md:inline">{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
