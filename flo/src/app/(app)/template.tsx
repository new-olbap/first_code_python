"use client";
import { MotionConfig, motion } from "motion/react";

// Transition douce à chaque changement de page (désactivée si l'utilisateur réduit les animations).
export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <MotionConfig reducedMotion="user">
      <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25, ease: "easeOut" }}>
        {children}
      </motion.div>
    </MotionConfig>
  );
}
