"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { CalendarDays, LayoutDashboard, LogOut, Menu, Plus, Users, X } from "lucide-react";
import { NAV } from "@/lib/nav";
import { signOut } from "@/lib/actions";
import Shape3D from "@/components/Shape3D";
import type { Role } from "@/lib/supabase/server";

const isActive = (path: string, href: string) => (href === "/" ? path === "/" : path === href || path.startsWith(href + "/"));

// Ordinateur : colonne collée à gauche. Mobile : barre de 5 boutons en bas + panneau « Plus ».
export default function Sidebar({ orgName, role }: { orgName: string; role: Role }) {
  const path = usePathname();
  const [open, setOpen] = useState(false);
  useEffect(() => setOpen(false), [path]); // referme le panneau après navigation
  const nav = NAV.filter((n) => !n.ownerOnly || role === "owner");
  const more = nav.filter((n) => !["/", "/agenda", "/clients"].includes(n.href));

  return (
    <>
      <nav aria-label="Navigation principale" className="fixed left-0 top-0 z-20 hidden h-screen w-64 flex-col gap-1 overflow-y-auto border-r border-line bg-[#0d0d0d] p-4 md:flex">
        <Link href="/" className="px-3 pb-6 pt-2">
          <span className="flex items-center gap-3"><span className="text-3xl font-black tracking-tight">Flo</span><Shape3D /></span>
          <span className="mt-1 block truncate text-xs font-medium text-muted">{orgName}</span>
        </Link>
        {nav.map(({ href, label, icon: Icon }) => {
          const active = isActive(path, href);
          return (
            <Link key={href} href={href} aria-current={active ? "page" : undefined}
              className={`group flex items-center gap-3 px-3 py-2.5 text-sm font-medium transition-colors ${active ? "bg-ink text-bg" : "text-muted hover:bg-surface hover:text-ink"}`}>
              <Icon size={20} aria-hidden className="transition-transform motion-safe:group-hover:translate-x-0.5" />
              {label}
            </Link>
          );
        })}
      </nav>

      <nav aria-label="Navigation principale" className="fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 border-t border-line bg-[#0d0d0d]/95 pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden">
        {[{ href: "/", label: "Accueil", icon: LayoutDashboard }, { href: "/agenda", label: "Agenda", icon: CalendarDays }].map(({ href, label, icon: Icon }) => (
          <MobileItem key={href} href={href} label={label} active={isActive(path, href)}><Icon size={22} aria-hidden /></MobileItem>
        ))}
        <Link href="/agenda/nouveau" aria-label="Nouveau rendez-vous" className="flex items-center justify-center py-2">
          <span className="grid h-11 w-11 place-items-center bg-ink text-bg active:scale-95"><Plus size={24} aria-hidden /></span>
        </Link>
        <MobileItem href="/clients" label="Clients" active={isActive(path, "/clients")}><Users size={22} aria-hidden /></MobileItem>
        <button onClick={() => setOpen(true)} aria-expanded={open} aria-controls="menu-plus"
          className={`flex flex-col items-center gap-0.5 py-2 text-[11px] font-medium ${more.some((n) => isActive(path, n.href)) ? "text-ink" : "text-muted"}`}>
          <Menu size={22} aria-hidden /> Plus
        </button>
      </nav>

      {open && (
        <div className="fixed inset-0 z-40 md:hidden" role="dialog" aria-modal="true" aria-label="Menu">
          <button aria-label="Fermer le menu" onClick={() => setOpen(false)} className="absolute inset-0 bg-black/70" />
          <div id="menu-plus" className="absolute inset-x-0 bottom-0 border-t border-line bg-[#111] p-4 pb-[calc(1rem+env(safe-area-inset-bottom))] motion-safe:animate-[modal-in_.2s_ease-out]">
            <div className="mb-3 flex items-center justify-between">
              <span className="flex items-center gap-3"><span className="text-2xl font-black">Flo</span><span className="truncate text-sm text-muted">{orgName}</span></span>
              <button onClick={() => setOpen(false)} aria-label="Fermer" className="p-2 text-muted hover:text-ink"><X size={20} /></button>
            </div>
            <div className="grid grid-cols-2 gap-2">
              {more.map(({ href, label, icon: Icon }) => (
                <Link key={href} href={href} className={`flex items-center gap-3 px-3 py-3 text-sm font-medium ${isActive(path, href) ? "bg-ink text-bg" : "bg-surface text-ink"}`}>
                  <Icon size={18} aria-hidden />{label}
                </Link>
              ))}
            </div>
            <form action={signOut} className="mt-3">
              <button className="flex w-full items-center justify-center gap-2 border border-line px-3 py-3 text-sm font-medium text-muted hover:text-ink">
                <LogOut size={18} aria-hidden /> Se déconnecter
              </button>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

function MobileItem({ href, label, active, children }: { href: string; label: string; active: boolean; children: React.ReactNode }) {
  return (
    <Link href={href} aria-current={active ? "page" : undefined}
      className={`flex flex-col items-center gap-0.5 py-2 text-[11px] font-medium ${active ? "text-ink" : "text-muted"}`}>
      {children}{label}
      <span className={`h-0.5 w-5 ${active ? "bg-ink" : "bg-transparent"}`} />
    </Link>
  );
}
