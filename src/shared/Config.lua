-- Tous les réglages du jeu au même endroit.
-- Pour équilibrer le jeu, on modifie les chiffres ici sans toucher au reste du code.

local Config = {}

-- Raretés (GDD : Commun, Peu commun, Rare, Épique)
Config.Rarities = {
	Commun = { name = "Commun", color = Color3.fromRGB(190, 190, 190) },
	PeuCommun = { name = "Peu commun", color = Color3.fromRGB(85, 200, 90) },
	Rare = { name = "Rare", color = Color3.fromRGB(70, 140, 255) },
	Epique = { name = "Épique", color = Color3.fromRGB(180, 80, 255) },
}

-- Armes
-- kind = "melee" (arme blanche) ou "gun" (arme à feu)
-- cooldown = secondes entre deux attaques, spread = dispersion en degrés
-- noise = distance (en studs) à laquelle les monstres entendent le tir
Config.Weapons = {
	Couteau = {
		name = "Couteau",
		kind = "melee",
		rarity = "Commun",
		damage = 20,
		cooldown = 0.45,
		range = 7,
		size = Vector3.new(0.3, 1.6, 0.3),
		color = Color3.fromRGB(165, 165, 175),
	},
	Batte = {
		name = "Batte",
		kind = "melee",
		rarity = "Commun",
		damage = 28,
		cooldown = 0.8,
		range = 7.5,
		size = Vector3.new(0.4, 3, 0.4),
		color = Color3.fromRGB(140, 95, 55),
	},
	Machette = {
		name = "Machette",
		kind = "melee",
		rarity = "PeuCommun",
		damage = 35,
		cooldown = 0.7,
		range = 8,
		size = Vector3.new(0.2, 2.6, 0.5),
		color = Color3.fromRGB(120, 125, 130),
	},
	Pistolet = {
		name = "Pistolet",
		kind = "gun",
		rarity = "PeuCommun",
		damage = 20,
		pellets = 1,
		spread = 1.5,
		cooldown = 0.3,
		automatic = false,
		range = 250,
		magazine = 12,
		reserve = 36,
		reloadTime = 1.5,
		noise = 90,
		size = Vector3.new(0.35, 1.4, 0.8),
		color = Color3.fromRGB(45, 45, 50),
	},
	FusilAPompe = {
		name = "Fusil à pompe",
		kind = "gun",
		rarity = "Rare",
		damage = 11,
		pellets = 8,
		spread = 7,
		cooldown = 0.9,
		automatic = false,
		range = 70,
		magazine = 6,
		reserve = 18,
		reloadTime = 2.5,
		noise = 130,
		size = Vector3.new(0.4, 3.6, 0.6),
		color = Color3.fromRGB(90, 60, 40),
	},
	FusilAssaut = {
		name = "Fusil d'assaut",
		kind = "gun",
		rarity = "Epique",
		damage = 16,
		pellets = 1,
		spread = 2.5,
		cooldown = 0.11,
		automatic = true,
		range = 300,
		magazine = 30,
		reserve = 90,
		reloadTime = 2.2,
		noise = 150,
		size = Vector3.new(0.4, 3.4, 0.8),
		color = Color3.fromRGB(55, 65, 50),
	},
}

Config.HeadshotMultiplier = 1.5

-- Zones du prototype : la forêt (départ) et une ville.
-- loot = poids de chaque arme : plus le chiffre est grand, plus l'arme est fréquente.
Config.Zones = {
	{
		id = "Foret",
		name = "Forêt",
		center = Vector3.new(0, 0, 0),
		size = Vector3.new(400, 0, 400),
		groundColor = Color3.fromRGB(75, 120, 60),
		groundMaterial = Enum.Material.Grass,
		loot = { Couteau = 40, Batte = 30, Machette = 20, Pistolet = 10 },
		lootSpots = 12,
		monsters = 4,
	},
	{
		id = "Ville",
		name = "Ville",
		center = Vector3.new(0, 0, -380),
		size = Vector3.new(400, 0, 360),
		groundColor = Color3.fromRGB(110, 110, 105),
		groundMaterial = Enum.Material.Concrete,
		loot = { Batte = 10, Machette = 15, Pistolet = 40, FusilAPompe = 22, FusilAssaut = 13 },
		lootSpots = 6, -- en plus d'une arme dans chaque bâtiment
		monsters = 10,
	},
}

-- Une arme ramassée réapparaît au même endroit après ce délai (secondes)
Config.LootRespawnTime = 90

-- Cycle jour/nuit (GDD : environ 20 min de jour, 10 min de nuit)
Config.DayNight = {
	dayLength = 20 * 60,
	nightLength = 10 * 60,
	startClock = 8, -- heure de départ du serveur
}

-- Monstres
Config.Monsters = {
	Rodeur = {
		name = "Rôdeur",
		health = 60,
		walkSpeed = 13,
		wanderSpeed = 6,
		damage = 10,
		attackCooldown = 1.2,
		attackRange = 5,
		detectRange = 45,
		wanderRadius = 30,
		skinColor = Color3.fromRGB(120, 150, 95),
		clothesColor = Color3.fromRGB(70, 60, 50),
	},
}

-- La nuit, les monstres sont plus nombreux et plus forts
Config.Night = {
	countMultiplier = 2,
	healthMultiplier = 1.5,
	damageMultiplier = 1.5,
	speedMultiplier = 1.2,
	detectMultiplier = 1.5,
}

Config.MonsterSpawnInterval = 4 -- secondes entre deux vagues d'apparition
Config.MonsterMinSpawnDistance = 50 -- pas d'apparition sous le nez d'un joueur

Config.RespawnTime = 5

return Config
