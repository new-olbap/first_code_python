# Mission : construire un jeu de survie multijoueur sur Roblox

Tu es mon développeur principal sur un jeu de survie multijoueur Roblox (Roblox Studio, Luau), inspiré de Rust. Ce document contient le concept, toutes les mécaniques à implémenter et l'ordre de travail. Enregistre-le dans le projet sous `docs/GDD.md` : c'est ta référence d'une session à l'autre.

Mon niveau : je connais les bases de Python et je débute en Luau. Écris le code en anglais (variables, fonctions), commente-le en français et simplement, et explique brièvement tes choix d'architecture importants.

## Tes priorités, dans cet ordre

1. **Le combat et le gameplay.** C'est le cœur du jeu et ce qui décidera s'il est bon. Tir, armes blanches, recul, rechargement, usure, bruit, comportement des monstres et des boss, mort et perte du sac : tout doit être nerveux, lisible et satisfaisant, dès le prototype. Si tu hésites sur où investir ton effort, investis-le ici.
2. **Le concept et les boucles de jeu.** Respecte les piliers et la boucle décrits plus bas. À chaque décision, demande-toi si elle rend le jeu plus tendu, plus riche en choix et plus amusant ; sinon, simplifie. Si une contrainte technique remet le concept en cause, préviens-moi avant de la contourner.
3. **Un code propre, modulaire et facile à équilibrer.**
4. **Le visuel, en dernier.** Aucune modélisation poussée : voir « Assets 3D ».

## Méthode de travail

- **Une étape à la fois.** Suis le plan de développement en fin de document et commence par l'étape 1 uniquement. N'anticipe pas les suivantes et ne code pas les idées bonus avant que le prototype soit validé.
- **Avant de coder une étape :** résume en 10 lignes maximum ce que tu as compris, signale les ambiguïtés ou contradictions que tu vois, et propose l'arborescence des fichiers. Pose au plus 3 questions, seulement si elles bloquent ; sinon décide et note ton hypothèse.
- **Valeurs manquantes** (dégâts, délais, quantités, durées) : choisis une valeur raisonnable, mets-la dans la config et ajoute-la à `docs/A_EQUILIBRER.md`, que tu tiens à jour.
- **Une étape terminée = jouable et testable.** À la fin, dis-moi comment la tester (seul et à plusieurs), ce qui marche, ce qui reste approximatif et ce que tu proposes ensuite. Je la testerai avec des amis avant de passer à la suivante.

## Technique

- **Projet en fichiers texte** (.luau) synchronisable avec Roblox Studio, par exemple avec Rojo : `src/server`, `src/client`, `src/shared`.
- **Pas d'accès à Studio.** Pars du principe que tu ne peux pas piloter Studio (sauf si je t'indique un outil pour ça) : la carte du prototype, les objets et l'interface sont générés par code à partir de données. Si une manipulation manuelle est inévitable, donne-moi la procédure exacte en quelques étapes.
- **Serveur autoritaire.** Dégâts, inventaire, butin, réputation, primes, état des bases : tout est décidé et validé côté serveur. Le client gère l'affichage, les entrées et le ressenti immédiat (effets, sons, marqueurs de touche).
- **Données séparées de la logique.** Armes, monstres, boss, classes, zones et accessoires sont des tables de définitions dans des modules de config. Ajouter une arme ou un monstre = ajouter une entrée, pas réécrire du code.
- **Un module, une responsabilité** (Combat, Inventory, Loot, Monsters, DayNight, Reputation…). Simple et lisible d'abord, mais prévu pour 20 à 40 joueurs : limite le nombre de monstres actifs et évite les boucles lourdes à chaque frame.
- **Une zone de test** (ou des commandes de debug) pour essayer armes, monstres et boss en quelques secondes et régler l'équilibrage.

## Assets 3D : le strict minimum

Je trouverai les vrais modèles sur Internet. Ne perds donc pas de temps à modéliser.

- Tout est un **placeholder** : formes de base (Part, cylindre, wedge), une couleur par type, un nom clair (par exemple un « Loup » en gris sombre).
- Rends le remplacement trivial : chaque objet (arme, monstre, bâtiment, arbre, coffre…) est chargé **par son nom** depuis un dossier d'assets (par exemple `ReplicatedStorage/Assets/Weapons/Pistol`). Si le modèle n'existe pas, le code génère automatiquement le placeholder. Je pourrai ainsi glisser un vrai modèle du même nom sans toucher au code.
- Fournis-moi la liste des noms d'assets attendus, avec les conventions utiles (échelle, orientation, point d'attache d'une arme en main).
- Même logique pour les sons et l'interface : fonctionnels et simples, avec des emplacements faciles à remplacer (par exemple un module qui liste les IDs de sons).

---

# Le jeu

## Concept

Un jeu de survie multijoueur sur Roblox, inspiré de Rust : les joueurs fouillent des villes et bâtiments abandonnés, affrontent animaux et monstres, et choisissent de survivre seuls, en équipe ou en trahissant les autres. Serveurs de 20 à 40 joueurs. Public : joueurs Roblox de 13 ans et plus qui aiment l'action, l'exploration et les jeux d'équipe.

## Piliers

1. **Survivre ensemble ou seul.** Les monstres poussent à coopérer, mais la trahison reste toujours possible.
2. **Chaque choix a un impact.** Trahir ou tuer laisse une trace visible (réputation, prime).
3. **La carte guide le jeu.** Chaque zone a son butin, ses dangers et ses besoins.
4. **Deux classes, des centaines de styles.** Chaque joueur choisit une classe de loot et une classe de combat.

## But du jeu

- **Long terme :** faire de sa guilde la plus puissante de la saison.
- **Court terme :** survivre, s'équiper et grimper au classement.

## Boucle de jeu

Apparaître en forêt → fouiller et chasser → s'équiper → aller en zone dangereuse → combattre ou trahir.

- **Victoire :** le joueur construit ou renforce sa base, puis repart pour une nouvelle sortie.
- **Défaite :** il meurt, perd son sac (tout ce qu'il porte tombe et peut être récupéré par les autres) et retourne au départ.

Chaque sortie finit en butin ramené ou en sac perdu : c'est ce qui donne de la valeur à chaque combat.

---

# Combat (priorité n°1)

## Principes de design

- Les bonus de classe restent faibles (10 à 15 %) : la classe aide, mais c'est le joueur qui gagne le combat. Le combat récompense la visée, le placement, la gestion du bruit, des munitions et de l'usure.
- Toutes les armes sont utilisables par toutes les classes ; chaque classe a une famille de prédilection où ses bonus s'appliquent.
- Le bruit compte : un tir s'entend, des joueurs comme des monstres proches. Tirer sans silencieux attire les monstres.
- La mort fait perdre le sac et renvoie au départ.

## Ce que j'attends du combat dès le prototype

- Chaque tir et chaque touche donnent un retour immédiat : son, effet, marqueur de touche, indicateur de dégâts simple.
- Recul, dispersion, cadence, rechargement et usure sont des paramètres réglables par arme dans la config.
- Détection des touches fiable et validée côté serveur (raycast pour les armes à feu, projectiles pour arcs et arbalètes), avec un tir qui paraît instantané côté client.
- Armes blanches : coups lisibles, portée et rythme clairs.
- Monstres : un comportement clair par type (poursuite, meute, réaction au bruit, fuite pour les cerfs et lapins), sans IA complexe. Boss : schémas d'attaque lisibles.
- Mort propre : le sac tombe, récupérable par les autres ; réapparition au départ.

## Armes

- **Familles :** armes blanches (couteau, machette, batte), pistolets, fusils à pompe, fusils d'assaut, fusils de précision, arcs et arbalètes (silencieux, munitions récupérables), explosifs rares (zone militaire).
- **Rareté :** Commun, Peu commun, Rare, Épique. Plus la zone est dangereuse, plus la rareté monte.
- **Où les trouver :** au sol ou dans les bâtiments (les armes au sol sont en plus petite quantité).
- **Usure :** les armes s'abîment et se réparent avec des matériaux, ce qui garde la fouille utile tout au long de la partie.

## Classes de combat

| Classe | Bonus | Armes de prédilection |
|---|---|---|
| Sniper | Moins de recul, visée plus stable, zoom plus net | Fusils de précision, arbalète lourde (fusil à verrou, semi-automatique, arbalète à lunette) |
| Assaut | Recharge plus rapide, meilleure précision en mouvement | Fusils d'assaut, mitraillettes (fusil d'assaut, mitraillette compacte, carabine) |
| Tank | Plus de vie ou d'armure, mais plus lent | Fusils à pompe, mitrailleuse légère, bouclier (pompe, mitrailleuse, bouclier antiémeute) |
| Éclaireur | Court plus vite, fait moins de bruit, repère les ennemis de plus loin | Pistolets, arcs, couteaux de lancer (pistolet, revolver, arc à poulies) |
| Corps à corps | Dégâts bonus avec les armes blanches, idéal contre les monstres | Armes blanches lourdes et rapides (machette, hache, lance, masse) |

Armes de soutien, utilisables par toutes les classes : grenades, cocktail Molotov, pistolet de détresse, pièges.

## Accessoires

Ils dépendent du lieu, ce qui pousse à voyager, échanger ou voler.

| Accessoire | Effet | Où le trouver |
|---|---|---|
| Silencieux | Tirs moins audibles par les joueurs et les monstres | Zone industrielle |
| Chargeur étendu | Plus de balles avant de recharger | Zone industrielle |
| Lunette de visée | Zoom pour le tir à distance | Zone militaire |
| Poignée | Moins de recul | Commissariat |
| Lampe | Éclaire dans le noir et le brouillard | Commissariat, marais |
| Crosse | Visée plus stable | Ville |

## Animaux et monstres

**Animaux** (source de nourriture et de peaux) : cerfs et lapins qui fuient, loups en meute, ours solitaires et puissants.

**Monstres :**

- **Rôdeurs :** faibles, en groupe, attirés par le bruit des tirs.
- **Mutants :** résistants, dans les zones industrielles et les villes.
- **Traqueurs nocturnes :** n'apparaissent que la nuit, rapides, chassent les joueurs isolés.
- **Boss de zone :** un monstre unique par zone dangereuse, réapparaît toutes les X heures (X à régler en config), garde un butin Épique.

## Boss

Chaque boss apparaît à un moment lié à son comportement, annoncé quelques minutes avant par un signal (cri, sirène, fumée). Ça crée des rendez-vous où guildes et joueurs solo se croisent. Si le délai de réapparition (X heures) et le déclencheur se chevauchent, choisis la combinaison la plus simple et note-la dans `docs/A_EQUILIBRER.md`.

| Boss | Apparition | Zone | Comportement | Butin |
|---|---|---|---|---|
| L'Ours Alpha | À l'aube | Forêt | Charge en ligne droite, appelle des loups | Peau rare, arc Épique |
| Le Yéti | Pendant les tempêtes de neige | Montagnes | Lance des blocs de glace, invisible dans le blizzard | Manteau légendaire, hache |
| Le Colosse | À midi | Zone industrielle | Lent, très résistant, détruit les murs de base | Pièces rares, mitrailleuse |
| La Rôdeuse | À minuit | Ville | Rapide, se cache sur les toits, attaque les joueurs isolés | Lunette Épique, armure légère |
| Le Général | Toutes les 3 heures, avec un largage | Zone militaire | Commande des soldats mutants, utilise des grenades | Meilleur fusil de la saison |
| La Chose du marais | Les nuits de brouillard | Marais | Empoisonne, se téléporte entre les mares | Soins rares, ingrédients |

Un boss tué rapporte des points de guilde. Le dernier coup ne donne pas tout le butin : les dégâts infligés comptent, pour que la coopération reste intéressante (et la trahison tentante).

## Jour, nuit et événements

- **Cycle :** environ 20 minutes de jour, 10 minutes de nuit.
- **La nuit,** les monstres sont plus nombreux et plus forts : c'est là qu'on a besoin des autres, et que la trahison fait le plus mal.
- **Événements :** nuit de sang (monstres doublés, qui attaquent aussi les bases), largage de ravitaillement (attire tout le serveur), tempête de neige en montagne.

---

# Coopération, trahison et réputation

Trahir est toujours possible, mais ça se voit : le jeu ne punit pas le traître, il le rend célèbre et le transforme en cible.

- **Équipes :** jusqu'à 4 joueurs. Les coéquipiers voient leur position et leur vie, et partagent la base.
- **Zones sûres :** un ou deux camps de PNJ où le combat est impossible, pour échanger, vendre et former des équipes.
- **Trahison :** tuer un coéquipier, ou un joueur à qui l'on vient de parler ou d'échanger. Elle donne directement le statut Bandit.
- **Primes :** la prime grandit avec chaque meurtre. Celui qui tue un Bandit la récupère. Un tableau des primes est affiché dans les zones sûres. La réputation remonte lentement en restant pacifique.

La réputation est visible par la couleur du pseudo :

| Niveau | Comment l'obtenir | Effet |
|---|---|---|
| Survivant | Par défaut | Aucun |
| Héros | Aider, soigner, tuer des bandits | Meilleurs prix auprès des PNJ |
| Suspect | Tuer un joueur neutre | Pseudo orange |
| Bandit | Plusieurs meurtres ou une trahison | Pseudo rouge, prime sur sa tête |

---

# Monde et butin

Chaque zone a un butin dominant, un danger propre et un besoin qui oblige à aller ailleurs : c'est ce qui fait bouger les joueurs et provoque les rencontres.

| Zone | Butin dominant | Danger | Besoin pour y survivre |
|---|---|---|---|
| Forêt (zone de départ) | Bois, nourriture, peaux, armes blanches | Loups, ours | Aucun, zone d'apprentissage |
| Montagnes | Grands manteaux, vêtements chauds, cordes, peu d'armures | Froid qui fait perdre de la vie | Vêtements chauds |
| Ville | Armes, munitions, électronique, accessoires | Beaucoup de monstres, joueurs embusqués | Armes et soins |
| Zone industrielle | Métal, pièces mécaniques, silencieux, chargeurs | Monstres mutants, pièges | Outils |
| Commissariat | Lampes, poignées, gilets légers | Monstres en groupe | Équipe de 2 ou plus |
| Zone militaire | Meilleur équipement, lunettes de visée, armures lourdes | Monstres d'élite, gaz toxique | Masque à gaz, équipe |
| Marais | Plantes médicinales, ingrédients rares | Brouillard, créatures cachées | Lampe |

Les conteneurs (armoires, caisses, voitures) réapparaissent après un délai.

**Faim, soif et température** (étape 2, version légère, à tester) : les jauges baissent lentement, un repas ou une boisson suffit pour longtemps, et le froid ne compte qu'en montagne. Si les testeurs trouvent ça pénible, on garde seulement le froid.

## Classes de loot

| Classe | Bonus |
|---|---|
| Fouilleur | Fouille plus rapide, plus de matériaux par conteneur |
| Chasseur | Plus de viande et de peaux, repère les traces d'animaux |
| Ingénieur | Plus de pièces mécaniques, construction et réparation moins chères |
| Médecin | Trouve plus de soins, soigne mieux les autres joueurs |
| Marchand | Meilleurs prix auprès des PNJ, inventaire un peu plus grand |

## Progression des classes (loot et combat)

Chaque classe gagne de l'expérience en jouant (fouiller pour le Fouilleur, toucher de loin pour le Sniper). Des niveaux débloquent des petits bonus ou des apparences, jamais un avantage écrasant. Le changement de classe est possible dans une zone sûre, avec un temps d'attente.

---

# Guildes, territoires et saisons

- **Guildes :** jusqu'à 10 membres, avec un chef, des officiers et des membres. Un nom, un blason et une couleur visibles au-dessus des joueurs.
- **Niveau de guilde :** il monte avec les actions des membres (boss tués, territoires tenus, raids réussis).
- **Alliances et guerres :** les guildes peuvent s'allier ou se déclarer la guerre. Les morts en guerre ne comptent pas dans la réputation.
- **Territoires :** certains lieux clés (zone militaire, usine, tour radio) se capturent en restant dessus. Une guilde qui en tient un gagne des ressources régulières et un bonus de butin, mais devient la cible de tout le serveur.
- **Saisons :** à chaque réinitialisation de la carte, un classement récompense les meilleures guildes et les meilleurs joueurs (titres, blasons, apparences exclusives).

| Classement | Mesure |
|---|---|
| Guildes | Points de territoire, boss tués, raids réussis |
| Chasseurs de primes | Total des primes récupérées |
| Bandits | Plus haute prime atteinte |
| Survivants | Plus longue survie sans mourir |

---

# Construction et raids

Les raids existent comme dans Rust, mais à plus petite échelle et avec des protections, pour que les petits joueurs ne quittent pas le serveur.

- **Construction :** murs, portes, sols et toits en bois, puis en pierre, puis en métal. Un établi permet de fabriquer munitions, soins et réparations. Un coffre à code garde le butin.
- **Raids :** une base se casse avec des explosifs ou des outils lourds, rares et chers à fabriquer.
- **Protection hors ligne :** une base dont tous les membres sont déconnectés est beaucoup plus solide.
- **Protection des débutants :** pas de raid sur un joueur qui vient de commencer (30 premières minutes).
- **Monstres et bases :** pendant une nuit de sang, les monstres attaquent les bases. Les voisins ont intérêt à se défendre ensemble.
- **Réinitialisation :** la carte est remise à zéro régulièrement (par exemple toutes les deux semaines), comme sur Rust. Les niveaux de classe sont conservés.

---

# Idées bonus (après le prototype)

À ne pas implémenter avant que le prototype soit validé.

- **Chat de proximité :** on n'entend que les joueurs proches, à l'écrit comme à la voix (chat vocal Roblox, réservé aux joueurs vérifiés). Négocier face à face rend les trahisons bien plus tendues.
- **PNJ marchands :** échange de matériaux contre de l'équipement dans les zones sûres.
- **Quêtes de zone :** « tue le boss de la zone militaire », « rapporte 10 peaux de loup », pour guider les nouveaux.
- **Apparences cosmétiques :** seule source d'achats Robux, jamais d'avantage en combat (pay-to-win à éviter).
- **Mode serveur privé :** pour jouer entre amis ou tester les mécaniques.

---

# Plan de développement

Commence petit : un prototype jouable avant d'ajouter les systèmes complexes. Chaque étape est testée avec des amis avant de passer à la suivante.

1. **Prototype :** une petite carte (forêt + une ville), ramasser une arme au sol, tirer, un type de monstre (le Rôdeur est le plus simple à rendre intéressant grâce au bruit), la mort et la réapparition. Le combat doit déjà être agréable : c'est lui qu'on teste en premier.
2. **Survie :** inventaire, fouille de conteneurs, butin par zone, faim et soif, cycle jour/nuit.
3. **Classes :** les 2 types de classes avec 2 ou 3 classes chacun pour commencer, puis les autres.
4. **Social :** équipes, réputation, primes, zone sûre.
5. **Construction :** bases simples, établi, coffres.
6. **Raids et contenu :** raids, accessoires, nouvelles zones, boss, événements.
7. **Lancement :** équilibrage, cosmétiques, publication publique.

Les guildes, territoires, classements et saisons ne sont pas dans ces 7 étapes : ils viennent après l'étape 6, car ils reposent sur les boss, les raids et la réinitialisation de la carte. Propose-moi un découpage le moment venu.

---

# Pour commencer

1. Enregistre ce document dans `docs/GDD.md`.
2. Résume ta compréhension du jeu en 10 lignes maximum et signale les ambiguïtés que tu vois.
3. Propose l'arborescence du projet et le découpage de l'étape 1.
4. Implémente l'étape 1, en soignant le combat.
5. Termine par : comment tester, ce qui marche, ce qui reste approximatif, la liste « À équilibrer » et les noms d'assets attendus.
