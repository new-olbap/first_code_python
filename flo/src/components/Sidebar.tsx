"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { NAV } from "@/lib/nav";

// Desktop: vertical glass sidebar. Mobile: compact bottom bar (icons only).
export default function Sidebar() {
  const path = usePathname();
  return (
    <nav
      aria-label="Navigation principale"
      className="glass max-md:bg-white/90 fixed z-20 flex gap-1 p-2
        bottom-3 inset-x-3 overflow-x-auto
        md:inset-x-auto md:bottom-auto md:top-4 md:left-4 md:h-[calc(100vh-2rem)] md:w-60 md:flex-col md:p-4"
    >
      <Link href="/" className="hidden md:block px-3 pb-6 pt-2 text-3xl font-black tracking-tight">
        flo<span className="text-accent-2">.</span>
      </Link>
      {NAV.map(({ href, label, icon: Icon }) => {
        const active = path === href;
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            title={label}
            className={`flex shrink-0 items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-medium transition
              ${active ? "bg-gradient-to-r from-accent-ink to-accent-2 text-white shadow-lg shadow-accent/30" : "text-muted hover:bg-white/70 hover:text-ink"}`}
          >
            <Icon size={20} aria-hidden />
            <span className="hidden md:inline">{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
