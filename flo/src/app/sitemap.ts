import type { MetadataRoute } from "next";

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://flo-theta-gray.vercel.app";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${SITE}/`, changeFrequency: "weekly", priority: 1 },
    { url: `${SITE}/tarif`, changeFrequency: "monthly", priority: 0.8 },
    { url: `${SITE}/mentions-legales`, priority: 0.2 },
    { url: `${SITE}/cgu`, priority: 0.2 },
    { url: `${SITE}/confidentialite`, priority: 0.2 },
  ];
}
