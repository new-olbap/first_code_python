"use client";
import { motion } from "motion/react";

export default function Card({ children, className = "", i = 0 }: { children: React.ReactNode; className?: string; i?: number }) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, delay: i * 0.06, ease: "easeOut" }}
      className={`glass p-5 ${className}`}
    >
      {children}
    </motion.section>
  );
}
