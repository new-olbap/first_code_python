# Jeu de survie Roblox

Jeu de survie multijoueur inspiré de Rust, en Luau pour Roblox Studio.
Le document de référence est [`docs/GDD.md`](docs/GDD.md).

**État actuel : étape 2, la survie.**
- **Étape 1 (combat) :** armes blanches, armes à feu et arc, Rôdeurs, mort avec le sac qui tombe.
- **Étape 2 :** inventaire, conteneurs à fouiller, butin par zone, faim et soif, soins, réparation des armes, bois et baies.
- **Graphismes refaits :** terrain, bâtiments variés, armes détaillées, éclairage.

Une zone de test et un panneau de debug servent à régler l'équilibrage.

## Importer le jeu dans Roblox Studio

Les fichiers prêts à l'emploi sont dans le dossier [`build/`](build/).

### Option 1 : ouvrir le jeu complet (le plus simple)

1. Télécharge `build/JeuDeSurvie.rbxl`.
2. Dans Roblox Studio : **File → Open from File…** et choisis ce fichier.
3. Appuie sur **Play** (F5).

### Option 2 : ajouter le jeu dans une place existante

Télécharge les 3 fichiers `.rbxm`, puis dans l'Explorateur de Studio, **clic droit sur le service → Insert from File…** :

| Fichier | À insérer dans |
|---|---|
| `build/Shared.rbxm` | `ReplicatedStorage` |
| `build/Server.rbxm` | `ServerScriptService` |
| `build/Client.rbxm` | `StarterPlayer → StarterPlayerScripts` |

> Au démarrage, le jeu supprime la `Baseplate` et la `SpawnLocation` du modèle de base de Studio pour construire sa propre carte.

### Option 3 : Rojo (pour continuer à coder)

Le dossier `src/` se synchronise avec Studio grâce à [Rojo](https://rojo.space) (extension VS Code + plugin Studio) et au fichier `default.project.json`. Pour régénérer les fichiers de `build/` : `rojo build default.project.json -o build/JeuDeSurvie.rbxl`.

## Tester

**Seul :** appuie sur **Play**. Tu apparais dans la forêt. La **zone de test** est l'enclos jaune à droite du départ ; le bouton « TP zone de test » du panneau de debug t'y emmène directement.
- Un râtelier propose toutes les armes, qui reviennent 3 s après avoir été prises.
- Des mannequins sont placés à 10, 25, 50 et 80 studs. Ils affichent les dégâts et se soignent tout seuls.
- Un bouton fait venir 3 Rôdeurs, un autre supprime les monstres.

**À plusieurs dans Studio :** onglet **Test → Clients and Servers**, 2 à 4 joueurs, **Start**.
**Avec des amis en ligne :** publie le jeu (**File → Publish to Roblox**), puis ajoute leurs UserId dans `GameConfig.Debug.adminUserIds` s'ils doivent avoir le panneau de debug.

**Commandes :** clic pour attaquer (maintenir pour le fusil d'assaut), clic droit pour viser, `R` pour recharger, `E` (maintenir) pour ramasser ou fouiller, `I` pour l'inventaire, `H` pour se soigner, `1` à `5` pour changer d'arme, `F2` pour le panneau de debug.

**Pour tester l'étape 2 :**
- **Fouiller :** maintiens `E` devant une armoire, un frigo, une caisse ou le coffre d'une voiture, puis prends les objets dans la fenêtre qui s'ouvre.
- **Manger et se soigner :** `I` ouvre l'inventaire ; clique sur un objet, puis sur « Utiliser ». `H` utilise un bandage.
- **Réparer :** dans l'inventaire, à côté de chaque arme. Il faut du bois, de la ferraille ou du tissu.
- **Bois :** frappe un arbre avec une arme blanche. **Baies :** maintiens `E` devant un buisson rouge.
- **Debug (`F2`) :** « Kit de survie » remplit l'inventaire ; « Faim/soif au minimum » montre les dégâts de la faim.

## Organisation du code

```
docs/
  GDD.md             le game design document (la référence)
  A_EQUILIBRER.md    toutes les valeurs choisies sans chiffre dans le GDD
  ASSETS.md          noms et conventions pour remplacer les placeholders
build/               fichiers à importer dans Studio (.rbxl / .rbxm)
src/shared/          -> ReplicatedStorage.Shared (serveur ET client)
  GameConfig         réglages généraux (réapparition, nuit, limites, debug)
  WeaponDefs         armes et raretés          <- ajouter une arme = une entrée
  MonsterDefs        monstres                  <- ajouter un monstre = une entrée
  ZoneDefs           zones, armes au sol par zone, zone de test
  ItemDefs           objets : ressources, munitions, nourriture, soins
  ContainerDefs      conteneurs à fouiller et leur butin
  WeaponModels       modèles des armes (placeholders détaillés)
  Sounds             IDs des sons (à remplir)
  Animations         IDs des animations des monstres
  AssetLoader        charge un modèle par son nom, sinon un placeholder
  Placeholders       les placeholders du décor (arbres, voitures, conteneurs...)
  Ballistics         dispersion et trajectoire des flèches (mêmes calculs client/serveur)
  SoundPlayer        joue les sons
  Remotes            communication client <-> serveur
src/server/          -> ServerScriptService.Server
  init.server        démarrage, relie les modules
  WeaponService      armes : tirs, coups, rechargement, usure (le serveur décide)
  Projectiles        flèches simulées par le serveur
  Combat             dégâts (un seul point d'entrée) et cibles
  MonsterService     Rôdeurs : apparition par groupes, IA, bruit, nuit
  LootService        armes au sol, flèches plantées
  InventoryService   inventaire (24 cases), jeter, réparer
  ContainerService   conteneurs à fouiller, sacs des morts, objets jetés
  SurvivalService    faim, soif, soins, utilisation des objets
  ResourceService    bois des arbres, baies des buissons
  PlayerService      mort -> le sac tombe ; réapparition
  MapBuilder         carte : terrain, forêt, ville, collines
  Buildings          bâtiments (maison, immeuble, magasins, entrepôt, ruine)
  DayNight           cycle jour/nuit
  TestZone           zone de test
  DebugService       commandes du panneau de debug (vérifiées par le serveur)
  Rigs               personnages placeholder (Rôdeur, mannequins)
src/client/          -> StarterPlayerScripts.Client
  WeaponController   visée, tir instantané, recul, dispersion, caméra d'épaule
  Effects            traînées, impacts, flèches, chiffres de dégâts
  Hud                vie, faim, soif, munitions, usure, réticule, marqueur de touche, mort
  InventoryClient    copie locale de l'inventaire
  InventoryUI        fenêtres d'inventaire et de fouille, barre de progression
  DebugPanel         panneau F2
```

## Plan de développement

- [x] 1. Prototype : carte, ramasser une arme, tirer, Rôdeurs, mort et réapparition
- [x] 2. Survie : inventaire, fouille de conteneurs, butin par zone, faim et soif, jour/nuit
- [ ] 3. Classes : classes de loot et de combat
- [ ] 4. Social : équipes, réputation, primes, zone sûre
- [ ] 5. Construction : bases, établi, coffres
- [ ] 6. Raids et contenu : raids, accessoires, nouvelles zones, boss, événements
- [ ] 7. Lancement : équilibrage, cosmétiques, publication
