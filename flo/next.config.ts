import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Import de fichiers clients jusqu'à 2 Mo (limite par défaut des actions serveur : 1 Mo).
  experimental: { serverActions: { bodySizeLimit: "3mb" } },
};

export default nextConfig;
