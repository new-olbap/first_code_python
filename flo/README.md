# FLO — prototype du dashboard

Étape 02 du plan : dashboard interactif avec données fictives (style **Coral Glass**).

```bash
cd flo
npm install
npm run dev   # http://localhost:3000
```

- Couleurs : tokens dans `src/app/globals.css` (`:root`) — changer `--accent`, `--accent-2`, `--bg` pour tester une autre direction.
- Données de démo du dashboard : `src/lib/demo.ts` (remplacées à l’étape 04).
- Menu / pages : `src/lib/nav.ts`. Les pages autres que le dashboard affichent pour l’instant leurs actions prévues.

Stack : Next.js 15 (App Router) · Tailwind CSS 4 · Motion · Lucide · Recharts.

## Comptes et entreprises (étape 03)

1. Supabase > **SQL Editor** : coller et exécuter `supabase/migrations/0001_comptes.sql`.
2. Puis exécuter `supabase/tests/isolation.sql` : doit afficher `OK : isolation vérifiée` (tout est annulé ensuite).
3. Supabase > **Authentication > URL Configuration** : Site URL `http://localhost:3000`, Redirect URLs `http://localhost:3000/**`.
4. Créer `flo/.env.local` :
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://<projet>.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=<clé anon / publishable>
   ```

Rôles : `owner` (tout, dont l’abonnement), `admin` (entreprise + équipe sauf propriétaires), `member` (lecture de l’entreprise).
Les règles d’accès sont dans la base (RLS), pas seulement dans l’interface.

Test d’isolation sur le vrai projet (crée 2 comptes test-flo-…@mailinator.com, « Confirm email » doit être désactivé) :
```bash
node --env-file=.env.local scripts/check-isolation.mjs
```

Test d’isolation sur un PostgreSQL local (sans Supabase) :
```bash
psql -d <base_vide> -v ON_ERROR_STOP=1 -f supabase/tests/local_stub.sql \
  -f supabase/migrations/0001_comptes.sql -f supabase/tests/isolation.sql
```

## Synchronisation avec l’agenda du téléphone (migration 0009)

1. Supabase > **SQL Editor** : coller et exécuter `supabase/migrations/0009_calendrier.sql`.
2. Vérifier avec `supabase/tests/calendrier.sql` (tout est annulé ensuite) : doit afficher `OK : synchronisation d'agenda vérifiée`.
3. Dans FLO : **Paramètres > Mes rendez-vous dans l’agenda de mon téléphone** → « Ajouter à Google Agenda » ou « Ajouter à l’iPhone ».

Chaque personne a un lien secret `/cal/<jeton>.ics` (lecture seule, sans les rendez-vous annulés, 60 jours passés et 1 an à venir).
Google relit le lien toutes les quelques heures, Apple environ toutes les heures. Test du format : `node scripts/test-ics.mjs`.

## Page de présentation (site public)

- Un visiteur non connecté qui ouvre l’adresse principale (`/`) voit la page de présentation (`src/app/decouvrir`) ; un artisan connecté arrive sur son tableau de bord.
- Référencement : `robots.txt` et `sitemap.xml` sont générés (`src/app/robots.ts`, `src/app/sitemap.ts`), avec des données structurées « logiciel » dans la page.
- Quand Flo aura son nom de domaine, ajouter sur Vercel la variable `NEXT_PUBLIC_SITE_URL` (ex. `https://getflo.app`), puis redéployer.
- Images : `public/decouvrir/` (vraies captures de Flo avec les données de démonstration, photos Unsplash).
- Partie « cinéma » (`Cinema.tsx`) : un film piloté par le défilement (119 images WebP dans `public/decouvrir/film/`, tirées d’une vidéo libre Pexels), puis l’écran de Flo qui se redresse en 3D, les fonctions en défilement horizontal et les téléphones en parallaxe. GSAP (ScrollTrigger) et Lenis. Si le système demande moins d’animations, tout s’affiche sans effet.
