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
