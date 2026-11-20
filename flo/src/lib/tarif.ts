// Prix de la licence à vie (paiement unique, en euros). Micro-entreprise : TVA non applicable.
export const TARIF = { normal: 1790, lancement: 1190, places: 20, fois: 3 }; // fois : paiement en plusieurs virements sans frais
export const CONTACT = "ddmpalexandre@gmail.com";
export const eur = (n: number) => `${n.toLocaleString("fr-FR")} €`;
export const mensualite = (n: number) => Math.ceil(n / TARIF.fois); // 1190 → 397 ; le dernier virement ajuste à l'euro près
