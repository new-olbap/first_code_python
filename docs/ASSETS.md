# Assets attendus

Tout ce que tu vois dans le prototype est un **placeholder** fait de formes simples.
Pour le remplacer par un vrai modèle :

1. Dans l'Explorateur de Studio, crée le dossier `ReplicatedStorage > Assets`, puis le sous-dossier de la catégorie (par exemple `Weapons`).
2. Glisse ton modèle dedans et donne-lui **exactement** le nom de la liste ci-dessous.
3. Lance le jeu : le code le trouve tout seul. S'il n'existe pas, le placeholder est généré, et la fenêtre Output affiche `[Assets] Placeholder utilisé pour ...`.

## Liste des noms

| Dossier | Noms | Type attendu |
|---|---|---|
| `Weapons` | `Knife` (couteau), `Bat` (batte), `Machete` (machette), `Bow` (arc), `Pistol` (pistolet), `Shotgun` (fusil à pompe), `AssaultRifle` (fusil d'assaut) | Tool (ou Model) avec une pièce `Handle` |
| `Monsters` | `Prowler` (Rôdeur) | Model avec `Humanoid` et `HumanoidRootPart` |
| `Characters` | `Dummy` (mannequin de la zone de test) | Model avec `Humanoid` et `HumanoidRootPart` |
| `Buildings` | `House` (maison à étage), `Apartment` (immeuble), `Shop` (magasin), `Warehouse` (entrepôt), `Ruin` (ruine) | Model |
| `Containers` | `Crate` (caisse), `HunterStash` (cache de chasseur), `Cabinet` (armoire), `Fridge` (frigo), `MedCabinet` (armoire à pharmacie), `Bin` (poubelle), `WeaponLocker` (râtelier d'armes) | Model |
| `Props` | `Tree` (arbre), `BerryBush` (buisson de baies), `Rock` (rocher), `Log` (tronc couché), `Tent` (tente), `Campfire` (feu de camp), `HuntingTower` (tour de chasse) | Model |
| `Props` | `Car` (voiture), `StreetLight` (lampadaire), `Bench` (banc), `Barrier` (barrière en béton), `Cone` (plot), `Tires` (pneus), `UtilityPole` (poteau électrique) | Model |
| `Props` | `Bag` (sac lâché à la mort), `Pouch` (petit sac d'objets jetés), `Arrow` (flèche en vol et plantée) | Model |

> Un seul modèle par nom : si tu fournis `Tree`, tous les arbres seront ce modèle. Les placeholders, eux, varient (pins, chênes, bouleaux, arbres morts ; 5 enseignes de magasin...).

## Conventions

**Pour tous les modèles :**
- **Échelle Roblox normale** : un personnage mesure environ 5 studs de haut, une porte 8 studs.
- **Pivot posé au sol, au centre de la base.** Le code place l'objet par son pivot : dans Studio, sélectionne le modèle, puis **Model > Pivot > Edit Pivot**.
- **L'avant regarde vers -Z** (la face « Front » dans Studio).

**Armes (`Weapons`) :**
- La pièce principale s'appelle **`Handle`**, avec sa **longueur sur l'axe Z**, le **canon (ou la lame) vers -Z** et le **haut de l'arme vers +Y** (la poignée pend vers -Y).
- Les autres pièces sont **soudées** à `Handle` (WeldConstraint) et **non ancrées**. Le code règle lui-même les collisions et la masse.
- Mets une **Attachment `Muzzle`** dans `Handle`, au bout du canon : c'est de là que partent le flash et les traînées des balles.
- **Point d'attache en main** : si tu fournis un **Tool**, son `Grip` est gardé tel quel. Si tu fournis un **Model**, le code tient l'arme à 0,4 stud de l'arrière de `Handle`.

**Monstres et mannequins (`Monsters`, `Characters`) :**
- C'est un rig de personnage (R15 de préférence) avec `Humanoid`, `HumanoidRootPart` et une `Head`. La tête compte pour les tirs à la tête.
- Les animations du Rôdeur se changent dans `src/shared/Animations.luau`.

**Bâtiments (`Buildings`) :**
- La porte est sur la face avant (-Z). Le code tourne les bâtiments pour que la porte donne sur la rue.
- **Le pivot (PrimaryPart) est le sol du rez-de-chaussée.**
- Place des **Attachments nommées `LootSpot`** à l'intérieur, au niveau du sol : une arme apparaîtra sur chacune.
- Place des **Attachments nommées `ContainerSpot`** avec un attribut texte **`ContainerType`** (par exemple `Fridge`) : le conteneur sera posé là, son avant (-Z) dans le sens de l'Attachment.
- Les bâtiments font au plus 40 × 30 studs au sol. Garde à peu près cette taille, sinon les rues seront bouchées.

**Conteneurs et objets fouillables :**
- Un modèle de `Containers` est rendu fouillable automatiquement ; son avant (-Z) fait face au joueur.
- Pour qu'un objet du décor se fouille lui-même (comme le coffre de la voiture), ajoute-lui une Attachment `ContainerSpot` avec les attributs `ContainerType` = `CarTrunk` et `Embedded` = vrai.

**Arbres et buissons :**
- Tous les arbres (`Tree`) donnent du bois quand on les frappe ; il n'y a rien à ajouter.
- Un buisson (`BerryBush`) doit contenir un Model ou Folder nommé `Berries` : ces pièces disparaissent quand on cueille.

**Feuillage :**
- Les pièces que les balles doivent traverser (feuillage) doivent avoir `CanQuery = false`.

## Sons

Les sons sont listés dans `src/shared/Sounds.luau`. Pour chacun, colle un ID de la forme `rbxassetid://123456`, trouvé dans **Toolbox > Audio**. Un son vide est ignoré. Les plus importants pour le ressenti du combat :

`PistolShot`, `ShotgunShot`, `RifleShot`, `HitMarker`, `KillMarker`, `Reload`, `DryFire`, `ProwlerAlert`, `ProwlerAttack`.
