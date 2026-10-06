# Assets attendus

Tout ce que tu vois dans le prototype est un **placeholder** fait de formes simples.
Pour le remplacer par un vrai modèle :

1. Dans l'Explorateur de Studio, crée le dossier `ReplicatedStorage > Assets`, puis le sous-dossier de la catégorie (par exemple `Weapons`).
2. Glisse ton modèle dedans et donne-lui **exactement** le nom de la liste ci-dessous.
3. Lance le jeu : le code le trouve tout seul. S'il n'existe pas, le placeholder est généré, et la fenêtre Output affiche `[Assets] Placeholder utilisé pour ...`.

## Liste des noms

| Dossier | Nom | Ce que c'est | Type attendu |
|---|---|---|---|
| `Weapons` | `Knife` | Couteau | Tool (ou Model) avec une pièce `Handle` |
| `Weapons` | `Bat` | Batte | idem |
| `Weapons` | `Machete` | Machette | idem |
| `Weapons` | `Bow` | Arc | idem |
| `Weapons` | `Pistol` | Pistolet | idem |
| `Weapons` | `Shotgun` | Fusil à pompe | idem |
| `Weapons` | `AssaultRifle` | Fusil d'assaut | idem |
| `Monsters` | `Prowler` | Rôdeur | Model avec `Humanoid` et `HumanoidRootPart` |
| `Characters` | `Dummy` | Mannequin de la zone de test | Model avec `Humanoid` et `HumanoidRootPart` |
| `Props` | `Tree` | Arbre | Model |
| `Props` | `Rock` | Rocher | Model |
| `Props` | `Car` | Voiture abandonnée | Model |
| `Props` | `Bag` | Sac lâché à la mort | Model |
| `Props` | `Arrow` | Flèche (en vol et plantée) | Model |
| `Buildings` | `House` | Bâtiment de la ville | Model |

## Conventions

**Pour tous les modèles :**
- **Échelle Roblox normale** : un personnage mesure environ 5 studs de haut, une porte 8 studs.
- **Pivot posé au sol, au centre de la base.** Le code place l'objet par son pivot : dans Studio, sélectionne le modèle, puis **Model > Pivot > Edit Pivot**.
- **L'avant regarde vers -Z** (la face « Front » dans Studio).

**Armes (`Weapons`) :**
- La pièce principale s'appelle **`Handle`**, avec sa **longueur sur l'axe Z** et le **canon (ou la lame) vers -Z**.
- Les autres pièces sont **soudées** à `Handle` (WeldConstraint) et **non ancrées**. Le code règle lui-même les collisions et la masse.
- Mets une **Attachment `Muzzle`** dans `Handle`, au bout du canon : c'est de là que partent le flash et les traînées des balles.
- **Point d'attache en main** : si tu fournis un **Tool**, son `Grip` est gardé tel quel. Si tu fournis un **Model**, le code tient l'arme à 0,4 stud de l'arrière de `Handle`.

**Monstres et mannequins (`Monsters`, `Characters`) :**
- C'est un rig de personnage (R15 de préférence) avec `Humanoid`, `HumanoidRootPart` et une `Head`. La tête compte pour les tirs à la tête.
- Les animations du Rôdeur se changent dans `src/shared/Animations.luau`.

**Bâtiments (`Buildings`) :**
- La porte est sur la face avant (-Z). Le code tourne les bâtiments pour que la porte donne sur la rue.
- Place des **Attachments nommées `LootSpot`** à l'intérieur, au niveau du sol : une arme apparaîtra sur chacune.
- Le placeholder mesure 40 × 30 studs au sol. Garde à peu près cette taille, sinon les rues seront bouchées.

**Arbres et décor :**
- Les pièces que les balles doivent traverser (feuillage) doivent avoir `CanQuery = false`.

## Sons

Les sons sont listés dans `src/shared/Sounds.luau`. Pour chacun, colle un ID de la forme `rbxassetid://123456`, trouvé dans **Toolbox > Audio**. Un son vide est ignoré. Les plus importants pour le ressenti du combat :

`PistolShot`, `ShotgunShot`, `RifleShot`, `HitMarker`, `KillMarker`, `Reload`, `DryFire`, `ProwlerAlert`, `ProwlerAttack`.
