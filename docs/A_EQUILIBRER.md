# À équilibrer

Toutes les valeurs que j'ai dû choisir moi-même, faute de chiffre dans le GDD.
Elles sont toutes dans `src/shared/` : il suffit de changer le chiffre, pas le code.

## Armes (`WeaponDefs.luau`)

| Arme | Dégâts | Cadence (s) | Chargeur | Rechargement (s) | Dispersion base → max (°) | Recul vertical (°) | Usure max | Bruit (studs) |
|---|---|---|---|---|---|---|---|---|
| Couteau | 22 | 0,45 | – | – | – | – | 120 | 12 |
| Batte | 32 | 0,85 | – | – | – | – | 80 | 15 |
| Machette | 38 | 0,7 | – | – | – | – | 100 | 12 |
| Arc | 45 | 0,9 | 1 | 0,7 | 0,3 → 2 | 0,4 | 60 | 8 |
| Pistolet | 20 | 0,22 | 12 | 1,4 | 0,6 → 5 | 1,4 | 150 | 90 |
| Fusil à pompe | 11 × 8 plombs | 0,9 | 6 | 2,4 | 5 → 9 | 4,5 | 90 | 130 |
| Fusil d'assaut | 16 | 0,11 | 30 | 2,2 | 0,8 → 6 | 0,9 | 300 | 150 |

Coût de réparation (+50 % d'usure) : Couteau 1 ferraille · Batte 4 bois · Machette 2 ferraille · Arc 4 bois + 1 tissu · Pistolet 3 ferraille · Fusil à pompe 4 ferraille + 2 bois · Fusil d'assaut 6 ferraille.

Bois récolté par coup sur un arbre : Couteau 1 · Batte 2 · Machette 3.

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
| Réapparition des armes au sol | 120 s (6 en forêt, 4 dans la rue + 1 par bâtiment) |
| Sac lâché à la mort | disparaît après 300 s |
| Flèche plantée | ramassable pendant 60 s, 60 au maximum sur la carte |
| Réapparition du joueur | 5 s, puis 3 s d'invincibilité |
| Jour / nuit | 20 min / 10 min |

## Survie (étape 2, `GameConfig.luau`, `ItemDefs.luau`)

| Valeur | Réglage |
|---|---|
| Faim : de 100 à 0 en | 40 min |
| Soif : de 100 à 0 en | 30 min |
| Jauge vide | -1 vie toutes les 2 s |
| Bien nourri (faim **et** soif > 70) | +0,5 vie par seconde |
| Après réapparition | faim et soif à 80 |
| Régénération automatique de Roblox | désactivée |
| Inventaire | 24 cases ; 5 armes au maximum dans la barre |

| Objet | Effet | Durée d'utilisation | Pile max |
|---|---|---|---|
| Baies | +8 faim, +3 soif | 0,4 s | 20 |
| Barre chocolatée | +20 faim | 0,8 s | 10 |
| Conserve | +45 faim | 1,5 s | 5 |
| Bouteille d'eau | +50 soif | 1,2 s | 5 |
| Soda | +25 soif, +5 faim | 0,8 s | 5 |
| Bandage | +25 vie | 2 s | 10 |
| Trousse de soins | +70 vie | 4 s | 3 |

## Conteneurs (`ContainerDefs.luau`)

| Conteneur | Où | Fouille | Se remplit après | Butin principal |
|---|---|---|---|---|
| Caisse | forêt (campements), entrepôts, ruines | 1,2 s | 4 min | bois, tissu, ferraille, flèches |
| Cache de chasseur | tours de chasse | 1,5 s | 5 min | flèches, arc, machette, eau |
| Armoire | maisons, magasins | 1,5 s | 4 min | tissu, ferraille, munitions de pistolet |
| Frigo | maisons, épicerie, bar | 1 s | 4 min | eau, soda, conserves |
| Armoire à pharmacie | pharmacie, immeubles | 1,5 s | 5 min | bandages, trousses |
| Coffre de voiture | voitures de la ville | 2 s | 5 min | ferraille, munitions, pistolet, fusil à pompe |
| Poubelle | à côté de chaque bâtiment | 1 s | 3 min | ferraille, tissu |
| Râtelier d'armes | armurerie, parfois l'entrepôt | 3 s | 8 min | munitions, fusils (dont le fusil d'assaut) |

Ressources de la forêt : un arbre contient 30 bois et repousse en 5 min une fois épuisé. Un buisson donne 2 à 4 baies et repousse en 2 min 30.

## Choix et hypothèses

- **Jour/nuit dès l'étape 1.** Le plan le prévoit à l'étape 2, mais c'est ce qui rend les Rôdeurs tendus (pilier « survivre ensemble ou seul »). On peut le couper avec `GameConfig.DayNight.enabled = false`.
- **Réparation des armes (étape 2).** Elle se fait dans l'inventaire avec du bois, de la ferraille ou du tissu, sans établi (l'établi arrive à l'étape 5).
- **Munitions.** Ce sont des objets de l'inventaire, partagés par toutes les armes du même calibre. Ramasser une arme qu'on a déjà donne les balles de son chargeur.
- **Inventaire.** 24 cases pour les objets, et les armes restent dans la barre d'outils de Roblox (touches 1 à 5). C'est plus simple et plus rapide en combat qu'un inventaire unique.
- **Sac à la mort.** Il contient les armes et tout l'inventaire. N'importe qui peut le fouiller.
- **Butin par zone.** Le butin dépend des conteneurs posés dans chaque zone : la forêt a surtout des caisses et des caches de chasseur, la ville des armoires, frigos, voitures et une armurerie.
- **Température.** Le GDD ne la fait compter qu'en montagne, et il n'y a pas encore de montagne : elle arrivera avec cette zone à l'étape 6.
- **Bois.** On le récolte en frappant un arbre avec une arme blanche. Il sert aux réparations, puis à la construction à l'étape 5.
- **Combat entre joueurs.** Il est activé partout, sans zone sûre pour l'instant (zones sûres : étape 4).
- **Boss** : pas dans l'étape 1. La question « délai de réapparition contre déclencheur » sera tranchée à l'étape 6.
