import { headers } from "next/headers";

// Adresse publique de réservation de l'entreprise, sur le domaine où tourne l'app.
export async function bookingUrl(slug: string) {
  const h = await headers();
  return `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host")}/r/${slug}`;
}
