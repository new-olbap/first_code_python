# FLO — prototype du dashboard

Étape 02 du plan : dashboard interactif avec données fictives (style **Coral Glass**).

```bash
cd flo
npm install
npm run dev   # http://localhost:3000
```

- Couleurs : tokens dans `src/app/globals.css` (`:root`) — changer `--accent`, `--accent-2`, `--bg` pour tester une autre direction.
- Données de démo : `src/lib/demo.ts` (remplacées par Supabase à l’étape 03).
- Menu / pages : `src/lib/nav.ts`. Les pages autres que le dashboard affichent pour l’instant leurs actions prévues.

Stack : Next.js 15 (App Router) · Tailwind CSS 4 · Motion · Lucide · Recharts.
