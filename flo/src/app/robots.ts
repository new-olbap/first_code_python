import type { MetadataRoute } from "next";

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://flo-theta-gray.vercel.app";

// Seules les pages publiques sont référencées ; l'espace client et les liens privés ne le sont pas.
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: ["/", "/tarif", "/cgu", "/mentions-legales", "/confidentialite"], disallow: ["/cal/", "/r/", "/invitation/", "/auth/", "/decouvrir"] },
    sitemap: `${SITE}/sitemap.xml`,
  };
}
