# À équilibrer

Toutes les valeurs que j'ai dû choisir moi-même, faute de chiffre dans le GDD.
Elles sont toutes dans `src/shared/` : il suffit de changer le chiffre, pas le code.

## Armes (`WeaponDefs.luau`)

| Arme | Dégâts | Cadence (s) | Chargeur / réserve | Rechargement (s) | Dispersion base → max (°) | Recul vertical (°) | Usure max | Bruit (studs) |
|---|---|---|---|---|---|---|---|---|
| Couteau | 22 | 0,45 | – | – | – | – | 120 | 12 |
| Batte | 32 | 0,85 | – | – | – | – | 80 | 15 |
| Machette | 38 | 0,7 | – | – | – | – | 100 | 12 |
| Arc | 45 | 0,9 | 1 / 12 | 0,7 | 0,3 → 2 | 0,4 | 60 | 8 |
| Pistolet | 20 | 0,22 | 12 / 36 | 1,4 | 0,6 → 5 | 1,4 | 150 | 90 |
| Fusil à pompe | 11 × 8 plombs | 0,9 | 6 / 18 | 2,4 | 5 → 9 | 4,5 | 90 | 130 |
| Fusil d'assaut | 16 | 0,11 | 30 / 90 | 2,2 | 0,8 → 6 | 0,9 | 300 | 150 |

Autres réglages d'armes à vérifier en jeu :

- **Élan des armes blanches** (délai avant que le coup touche) : couteau 0,12 s, machette 0,18 s, batte 0,25 s.
- **Portée et largeur des coups** : de 6,5 à 8 studs ; `arc` de 0,2 (batte, coup étroit) à 0,35 (couteau).
- **Dispersion en mouvement** : de +1,5° (arc) à +3° (fusil d'assaut), ajoutée quand on bouge ou qu'on saute.
- **Visée (clic droit)** : la dispersion est multipliée par 0,6 et le recul par 0,7. Le champ de vision passe de 70 à 55-62.
- **Tir à la tête** : dégâts × 1,5 (`GameConfig.HeadshotMultiplier`).
- **Arc** : vitesse de la flèche 180 studs/s, gravité 40.
- **Usure** : 1 point par tir ou par coup. Sous 30 % (`WornThreshold`), la dispersion est multipliée par 1,6. À 0, l'arme est cassée et inutilisable.
- **État des armes trouvées au sol** : entre 55 % et 100 % (`LootDurability`).

## Rôdeur (`MonsterDefs.luau`)

| Valeur | Réglage |
|---|---|
| Vie | 60 (le pistolet tue en 3 balles, ou 2 tirs à la tête) |
| Vitesse en poursuite / en errance | 15 / 5 (le joueur court à 16 : on peut fuir, de justesse) |
| Dégâts | 12 par coup |
| Élan avant le coup | 0,45 s (on peut reculer pour l'esquiver) |
| Portée de déclenchement / de touche | 4,5 / 6 studs |
| Temps entre deux coups | 1,3 s |
| Vue | 35 studs, sans mur entre lui et le joueur |
| Ouïe | rayon de bruit de l'arme × 1 |
| Alerte du groupe | 40 studs |
| Abandon de la poursuite | à 90 studs |
| Taille d'un groupe | 2 à 4 |

## Monde (`ZoneDefs.luau`, `GameConfig.luau`)

| Valeur | Réglage |
|---|---|
| Groupes de Rôdeurs de jour | forêt 2, ville 4 |
| Nuit | groupes × 2, vie × 1,5, dégâts × 1,4, vitesse × 1,15, vue × 1,3 |
| Monstres actifs au maximum | 40 sur tout le serveur |
| Veille des monstres | au-delà de 250 studs de tout joueur |
| Réapparition du butin | 90 s |
| Sac lâché à la mort | disparaît après 300 s |
| Flèche plantée | ramassable pendant 60 s, 60 au maximum sur la carte |
| Réapparition du joueur | 5 s, puis 3 s d'invincibilité |
| Jour / nuit | 20 min / 10 min |

## Choix et hypothèses

- **Jour/nuit dès l'étape 1.** Le plan le prévoit à l'étape 2, mais c'est ce qui rend les Rôdeurs tendus (pilier « survivre ensemble ou seul »). On peut le couper avec `GameConfig.DayNight.enabled = false`.
- **Réparation des armes.** Le GDD dit qu'on répare avec des matériaux, mais les matériaux arrivent avec la fouille à l'étape 2. En attendant, l'usure est active et la réparation passe par le panneau de debug.
- **Inventaire.** L'inventaire complet est à l'étape 2. Pour l'instant, la barre d'outils de Roblox sert d'inventaire. Ramasser une arme qu'on a déjà ne donne que ses munitions.
- **Sac à la mort.** Il contient toutes les armes portées, avec leurs munitions et leur usure. N'importe qui peut le fouiller.
- **Combat entre joueurs.** Il est activé partout, sans zone sûre pour l'instant (zones sûres : étape 4).
- **Boss** : pas dans l'étape 1. La question « délai de réapparition contre déclencheur » sera tranchée à l'étape 6.
