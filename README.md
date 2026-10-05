# Jeu de survie Roblox (prototype)

Prototype d'un jeu de survie multijoueur inspiré de Rust, d'après le Game Design Document.
Il correspond à l'**étape 1 du plan de développement** : une petite carte (forêt + ville),
ramasser une arme au sol, tirer, un type de monstre, la mort et la réapparition.
Le cycle jour/nuit (étape 2) est déjà inclus.

## Contenu du prototype

| Système | Ce qui marche |
| --- | --- |
| Carte | Forêt de départ (arbres, rochers), chemin, ville avec 12 bâtiments à visiter et des voitures pour se cacher. Tout est généré par le code. |
| Armes | Couteau, Batte, Machette (corps à corps), Pistolet, Fusil à pompe, Fusil d'assaut. 4 raretés avec leur couleur. Chargeur, réserve, rechargement, dispersion, tir automatique, bonus de dégâts à la tête. |
| Butin | Armes posées au sol (forêt : surtout des armes blanches ; ville : des armes à feu). Elles réapparaissent après 90 s. Ramasser une arme qu'on a déjà donne des munitions. |
| Monstres | Rôdeurs : ils errent, chassent les joueurs proches et sont **attirés par le bruit des tirs**. |
| Jour/nuit | 20 min de jour et 10 min de nuit. La nuit, il y a deux fois plus de monstres, plus forts et plus rapides. Ils disparaissent à l'aube s'ils ne chassent personne. |
| Mort | Écran « Tu es mort », qui affiche par qui on a été tué, puis réapparition après 5 s dans la forêt. On perd ses armes. |
| Combat entre joueurs | Activé, comme dans Rust. Le serveur vérifie chaque tir (anti-triche). |

**Commandes :** clic pour attaquer (maintenir pour le fusil d'assaut), `R` pour recharger,
`E` pour ramasser, `1` à `9` pour changer d'arme. Sur mobile, on touche l'écran et un bouton « Recharger » apparaît.

## Organisation du code

```
default.project.json          projet Rojo (relie les fichiers à Roblox Studio)
src/
  shared/                     -> ReplicatedStorage.Shared (utilisé par serveur ET client)
    Config.lua                tous les chiffres d'équilibrage : armes, zones, monstres, jour/nuit
    Remotes.lua               communication client <-> serveur
  server/                     -> ServerScriptService.Server
    init.server.lua           démarrage du serveur
    MapBuilder.lua            construction de la carte
    DayNight.lua              cycle jour/nuit
    WeaponService.lua         armes, tirs, rechargement
    LootService.lua           armes au sol à ramasser
    MonsterService.lua        apparition et intelligence des Rôdeurs
    Combat.lua                dégâts et recherche de cibles
  client/                     -> StarterPlayerScripts.Client
    init.client.lua           démarrage du client
    WeaponController.lua      clic, tir automatique, rechargement
    Effects.lua               traînées de balles, flash du canon
    Hud.lua                   vie, munitions, heure, messages, écran de mort
```

Pour équilibrer le jeu (dégâts, nombre de monstres, durée de la nuit...), il suffit de modifier `src/shared/Config.lua`.

## Lancer le jeu dans Roblox Studio

### Méthode recommandée : Rojo

[Rojo](https://rojo.space) synchronise les fichiers de ce dossier avec Roblox Studio.

1. Installe l'extension **Rojo** dans VS Code et le **plugin Rojo** dans Roblox Studio.
2. Dans Roblox Studio, crée une nouvelle place à partir du modèle **Baseplate**.
3. Dans VS Code, ouvre ce dossier, puis lance la commande « Rojo: Open menu » et clique sur **Start** pour `default.project.json`.
4. Dans Studio, ouvre le plugin Rojo et clique sur **Connect**.
5. Appuie sur **Play**.

### Méthode sans outil : copier-coller

Recrée cette arborescence dans l'Explorateur de Studio, en respectant **exactement** les noms, puis colle le contenu de chaque fichier :

- `ReplicatedStorage` > **Folder** `Shared`
  - **ModuleScript** `Config` ← `src/shared/Config.lua`
  - **ModuleScript** `Remotes` ← `src/shared/Remotes.lua`
- `ServerScriptService` > **Script** `Server` ← `src/server/init.server.lua`
  - dedans, un **ModuleScript** par fichier : `MapBuilder`, `DayNight`, `WeaponService`, `LootService`, `MonsterService`, `Combat`
- `StarterPlayer` > `StarterPlayerScripts` > **LocalScript** `Client` ← `src/client/init.client.lua`
  - dedans, un **ModuleScript** par fichier : `Hud`, `Effects`, `WeaponController`

> Au démarrage, le script supprime la `Baseplate` et la `SpawnLocation` du modèle de base de Studio pour les remplacer par sa propre carte.

Pour tester à plusieurs : onglet **Test** > **Clients and Servers** > 2 joueurs > **Start**.

## Prochaines étapes (plan du GDD)

- [x] 1. Prototype : petite carte, ramasser une arme, tirer, un monstre, mort et réapparition
- [ ] 2. Survie : inventaire, fouille de conteneurs, butin par zone, faim et soif (jour/nuit déjà fait)
- [ ] 3. Classes : classes de loot et de combat
- [ ] 4. Social : équipes, réputation, primes, zone sûre
- [ ] 5. Construction : bases simples, établi, coffres
- [ ] 6. Raids et contenu : raids, accessoires, nouvelles zones, boss, événements
- [ ] 7. Lancement : équilibrage, cosmétiques, publication

Améliorations possibles pour le prototype : animations et sons pour les monstres et les armes
(il faut des ID d'assets Roblox), modèles 3D pour les armes, et le PathfindingService
pour que les monstres contournent les murs au lieu de foncer droit dessus.
