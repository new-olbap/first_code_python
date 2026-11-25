import { NextResponse, type NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";

const PUBLIC = ["/connexion", "/inscription", "/mot-de-passe-oublie", "/auth/", "/r/", "/invitation/", "/mentions-legales", "/cgu", "/confidentialite", "/tarif", "/cal/", "/decouvrir", "/robots.txt", "/sitemap.xml"]; // /r/… : réservation publique ; /cal/… : flux d’agenda (jeton secret)

// Rafraîchit la session Supabase et renvoie vers /connexion si on n'est pas connecté.
export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });
  const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (list) => {
        list.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        list.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
      },
    },
  });
  // getClaims : rafraîchit la session si besoin et vérifie le jeton localement (plus rapide que getUser).
  const { data } = await supabase.auth.getClaims();
  const user = data?.claims?.sub;

  const path = request.nextUrl.pathname;
  const isPublic = PUBLIC.some((p) => path === p || path.startsWith(p));
  const redirect = (to: string) => NextResponse.redirect(new URL(to, request.url));

  // Visiteur non connecté sur l'adresse principale : la page de présentation (même URL, bonne pour le référencement).
  if (!user && path === "/") return NextResponse.rewrite(new URL("/decouvrir", request.url));
  if (!user && !isPublic) return redirect("/connexion");
  if (user && (path === "/connexion" || path === "/inscription")) return redirect("/");
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)"],
};
