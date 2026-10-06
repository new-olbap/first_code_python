-- Définitions des armes. Ajouter une arme = ajouter une entrée ici
-- (et éventuellement son modèle dans ReplicatedStorage/Assets/Weapons/<Id>).
--
-- Champs communs :
--   name          nom affiché
--   kind          "melee" (arme blanche), "gun" (arme à feu, raycast) ou "bow" (projectile)
--   rarity        clé de Rarities
--   damage        dégâts par coup / par plomb
--   cooldown      secondes minimum entre deux attaques (cadence)
--   maxDurability usure maximale ; chaque utilisation retire wearPerUse
--   noise         rayon (studs) dans lequel monstres et joueurs entendent l'attaque
--   sounds        clés de la table Sounds
--   repairCost    matériaux pour réparer la moitié de l'usure
--   color         couleur principale du placeholder (le modèle est dans WeaponModels)
--
-- Armes blanches : range (portée), arc (largeur du coup : 1 = droit devant, 0 = 180°),
--   windup (délai avant que le coup touche, pour qu'il soit lisible)
-- Armes à feu / arcs : magazine, ammoItem (objet de munitions), reloadTime, range, pellets, automatic,
--   spread = { base, moving, perShot, max, recovery } en degrés,
--   recoil = { vertical, horizontal, recovery } en degrés,
--   aimFov (champ de vision en visant, clic droit)
-- Arcs : projectileSpeed (studs/s), gravity (studs/s²)

local WeaponDefs = {}

WeaponDefs.Rarities = {
	Common = { name = "Commun", color = Color3.fromRGB(190, 190, 190), order = 1 },
	Uncommon = { name = "Peu commun", color = Color3.fromRGB(85, 200, 90), order = 2 },
	Rare = { name = "Rare", color = Color3.fromRGB(70, 140, 255), order = 3 },
	Epic = { name = "Épique", color = Color3.fromRGB(180, 80, 255), order = 4 },
}

WeaponDefs.Weapons = {
	Knife = {
		name = "Couteau",
		kind = "melee",
		rarity = "Common",
		damage = 22,
		cooldown = 0.45,
		windup = 0.12,
		range = 6.5,
		arc = 0.35,
		maxDurability = 120,
		wearPerUse = 1,
		repairCost = { Scrap = 1 }, -- matériaux pour réparer 50 % de l'usure
		harvest = 1, -- bois récolté par coup sur un arbre
		noise = 12,
		sounds = { swing = "MeleeSwing", hit = "MeleeHit" },
		color = Color3.fromRGB(165, 165, 175),
	},
	Bat = {
		name = "Batte",
		kind = "melee",
		rarity = "Common",
		damage = 32,
		cooldown = 0.85,
		windup = 0.25,
		range = 7.5,
		arc = 0.2,
		maxDurability = 80,
		wearPerUse = 1,
		repairCost = { Wood = 4 },
		harvest = 2,
		noise = 15,
		sounds = { swing = "MeleeSwingHeavy", hit = "MeleeHit" },
		color = Color3.fromRGB(140, 95, 55),
	},
	Machete = {
		name = "Machette",
		kind = "melee",
		rarity = "Uncommon",
		damage = 38,
		cooldown = 0.7,
		windup = 0.18,
		range = 8,
		arc = 0.25,
		maxDurability = 100,
		wearPerUse = 1,
		repairCost = { Scrap = 2 },
		harvest = 3,
		noise = 12,
		sounds = { swing = "MeleeSwing", hit = "MeleeHit" },
		color = Color3.fromRGB(120, 125, 130),
	},
	Bow = {
		name = "Arc",
		kind = "bow",
		rarity = "Uncommon",
		damage = 45,
		cooldown = 0.9,
		magazine = 1,
		ammoItem = "Arrow", -- munitions prises dans l'inventaire
		reloadTime = 0.7,
		pellets = 1,
		automatic = false,
		projectileSpeed = 180,
		gravity = 40,
		range = 400,
		spread = { base = 0.3, moving = 1.5, perShot = 0, max = 2, recovery = 10 },
		recoil = { vertical = 0.4, horizontal = 0.1, recovery = 10 },
		aimFov = 55,
		maxDurability = 60,
		wearPerUse = 1,
		repairCost = { Wood = 4, Cloth = 1 },
		noise = 8, -- presque silencieux : c'est tout l'intérêt de l'arc
		sounds = { fire = "BowShot", reload = "BowReload", hit = "ArrowHit" },
		color = Color3.fromRGB(110, 75, 45),
	},
	Pistol = {
		name = "Pistolet",
		kind = "gun",
		rarity = "Uncommon",
		damage = 20,
		cooldown = 0.22,
		magazine = 12,
		ammoItem = "AmmoPistol",
		reloadTime = 1.4,
		pellets = 1,
		automatic = false,
		range = 250,
		spread = { base = 0.6, moving = 2.5, perShot = 0.8, max = 5, recovery = 8 },
		recoil = { vertical = 1.4, horizontal = 0.5, recovery = 12 },
		aimFov = 60,
		maxDurability = 150,
		wearPerUse = 1,
		repairCost = { Scrap = 3 },
		noise = 90,
		sounds = { fire = "PistolShot", reload = "Reload", empty = "DryFire" },
		color = Color3.fromRGB(45, 45, 50),
	},
	Shotgun = {
		name = "Fusil à pompe",
		kind = "gun",
		rarity = "Rare",
		damage = 11,
		cooldown = 0.9,
		magazine = 6,
		ammoItem = "AmmoShotgun",
		reloadTime = 2.4,
		pellets = 8,
		automatic = false,
		range = 70,
		spread = { base = 5, moving = 2, perShot = 1.5, max = 9, recovery = 4 },
		recoil = { vertical = 4.5, horizontal = 1.2, recovery = 8 },
		aimFov = 62,
		maxDurability = 90,
		wearPerUse = 1,
		repairCost = { Scrap = 4, Wood = 2 },
		noise = 130,
		sounds = { fire = "ShotgunShot", reload = "Reload", empty = "DryFire" },
		color = Color3.fromRGB(90, 60, 40),
	},
	AssaultRifle = {
		name = "Fusil d'assaut",
		kind = "gun",
		rarity = "Epic",
		damage = 16,
		cooldown = 0.11,
		magazine = 30,
		ammoItem = "AmmoRifle",
		reloadTime = 2.2,
		pellets = 1,
		automatic = true,
		range = 300,
		spread = { base = 0.8, moving = 3, perShot = 0.35, max = 6, recovery = 6 },
		recoil = { vertical = 0.9, horizontal = 0.6, recovery = 9 },
		aimFov = 55,
		maxDurability = 300,
		wearPerUse = 1,
		repairCost = { Scrap = 6 },
		noise = 150,
		sounds = { fire = "RifleShot", reload = "Reload", empty = "DryFire" },
		color = Color3.fromRGB(55, 65, 50),
	},
}

-- Ordre d'affichage (panneau de debug, zone de test)
WeaponDefs.Order = { "Knife", "Bat", "Machete", "Bow", "Pistol", "Shotgun", "AssaultRifle" }

return WeaponDefs
