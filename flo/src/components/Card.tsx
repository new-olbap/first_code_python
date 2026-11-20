"use client";
import { motion } from "motion/react";

// Carte ; `interactive` : se soulève légèrement au survol. (L'apparition est gérée par la transition de page.)
export default function Card({ children, className = "", interactive = false }: {
  children: React.ReactNode; className?: string; interactive?: boolean;
}) {
  return (
    <motion.section
      whileHover={interactive ? { y: -3 } : undefined}
      transition={{ duration: 0.2, ease: "easeOut" }}
      className={`glass p-5 ${interactive ? "transition-colors hover:border-white/25" : ""} ${className}`}
    >
      {children}
    </motion.section>
  );
}
