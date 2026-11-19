"use client";
import { motion } from "motion/react";

// Carte animée à l'apparition ; `interactive` : se soulève légèrement au survol.
export default function Card({ children, className = "", i = 0, interactive = false }: {
  children: React.ReactNode; className?: string; i?: number; interactive?: boolean;
}) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={interactive ? { y: -3 } : undefined}
      transition={{ duration: 0.4, delay: i * 0.05, ease: "easeOut" }}
      className={`glass p-5 ${interactive ? "transition-colors hover:border-white/25" : ""} ${className}`}
    >
      {children}
    </motion.section>
  );
}
