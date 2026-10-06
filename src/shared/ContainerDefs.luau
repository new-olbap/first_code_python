-- Conteneurs à fouiller (armoires, caisses, voitures...).
-- Le butin d'une zone dépend des conteneurs qu'on y place (voir MapBuilder / Buildings) :
-- la forêt a des caisses et des caches de chasseur, la ville des armoires, frigos,
-- coffres de voiture, poubelles et une armurerie.
--
--   name         nom affiché
--   searchTime   secondes à maintenir E pour fouiller
--   respawnTime  secondes avant que le conteneur se remplisse à nouveau
--   rolls        nombre de tirages de butin
--   loot         { item = id, min, max, weight } ou { weapon = id, weight }
--                plus le poids est grand, plus l'entrée sort souvent

local ContainerDefs = {}

ContainerDefs.Containers = {
	Crate = {
		name = "Caisse",
		searchTime = 1.2,
		respawnTime = 240,
		rolls = { min = 1, max = 3 },
		loot = {
			{ item = "Wood", min = 3, max = 8, weight = 20 },
			{ item = "Cloth", min = 2, max = 5, weight = 18 },
			{ item = "Scrap", min = 1, max = 4, weight = 14 },
			{ item = "Bandage", min = 1, max = 2, weight = 10 },
			{ item = "Chocolate", min = 1, max = 1, weight = 8 },
			{ item = "Arrow", min = 3, max = 8, weight = 8 },
			{ item = "AmmoPistol", min = 6, max = 12, weight = 6 },
			{ weapon = "Knife", weight = 4 },
			{ weapon = "Bat", weight = 3 },
		},
	},
	HunterStash = {
		name = "Cache de chasseur",
		searchTime = 1.5,
		respawnTime = 300,
		rolls = { min = 2, max = 3 },
		loot = {
			{ item = "Arrow", min = 5, max = 12, weight = 25 },
			{ item = "Cloth", min = 2, max = 6, weight = 15 },
			{ item = "CannedFood", min = 1, max = 1, weight = 12 },
			{ item = "WaterBottle", min = 1, max = 1, weight = 12 },
			{ item = "Bandage", min = 1, max = 2, weight = 10 },
			{ weapon = "Bow", weight = 8 },
			{ weapon = "Machete", weight = 5 },
		},
	},
	Cabinet = {
		name = "Armoire",
		searchTime = 1.5,
		respawnTime = 240,
		rolls = { min = 1, max = 3 },
		loot = {
			{ item = "Cloth", min = 2, max = 5, weight = 18 },
			{ item = "Scrap", min = 1, max = 4, weight = 16 },
			{ item = "Bandage", min = 1, max = 2, weight = 12 },
			{ item = "AmmoPistol", min = 6, max = 15, weight = 12 },
			{ item = "AmmoShotgun", min = 3, max = 6, weight = 8 },
			{ item = "Chocolate", min = 1, max = 2, weight = 8 },
			{ item = "Soda", min = 1, max = 1, weight = 8 },
			{ weapon = "Pistol", weight = 4 },
			{ weapon = "Machete", weight = 3 },
		},
	},
	Fridge = {
		name = "Frigo",
		searchTime = 1,
		respawnTime = 240,
		rolls = { min = 1, max = 3 },
		loot = {
			{ item = "WaterBottle", min = 1, max = 2, weight = 30 },
			{ item = "Soda", min = 1, max = 2, weight = 25 },
			{ item = "CannedFood", min = 1, max = 2, weight = 25 },
			{ item = "Chocolate", min = 1, max = 2, weight = 15 },
		},
	},
	MedCabinet = {
		name = "Armoire à pharmacie",
		searchTime = 1.5,
		respawnTime = 300,
		rolls = { min = 1, max = 2 },
		loot = {
			{ item = "Bandage", min = 1, max = 3, weight = 45 },
			{ item = "Medkit", min = 1, max = 1, weight = 15 },
			{ item = "WaterBottle", min = 1, max = 1, weight = 15 },
			{ item = "Cloth", min = 2, max = 4, weight = 15 },
		},
	},
	CarTrunk = {
		name = "Coffre de voiture",
		searchTime = 2,
		respawnTime = 300,
		rolls = { min = 1, max = 3 },
		loot = {
			{ item = "Scrap", min = 2, max = 6, weight = 30 },
			{ item = "AmmoPistol", min = 6, max = 15, weight = 14 },
			{ item = "AmmoShotgun", min = 3, max = 8, weight = 12 },
			{ item = "WaterBottle", min = 1, max = 1, weight = 10 },
			{ item = "Bandage", min = 1, max = 2, weight = 8 },
			{ weapon = "Pistol", weight = 5 },
			{ weapon = "Shotgun", weight = 3 },
		},
	},
	Bin = {
		name = "Poubelle",
		searchTime = 1,
		respawnTime = 180,
		rolls = { min = 1, max = 2 },
		loot = {
			{ item = "Scrap", min = 1, max = 3, weight = 35 },
			{ item = "Cloth", min = 1, max = 3, weight = 30 },
			{ item = "Soda", min = 1, max = 1, weight = 15 },
			{ item = "Berries", min = 1, max = 3, weight = 10 },
		},
	},
	WeaponLocker = {
		name = "Râtelier d'armes",
		searchTime = 3,
		respawnTime = 480,
		rolls = { min = 2, max = 3 },
		loot = {
			{ item = "AmmoPistol", min = 12, max = 24, weight = 25 },
			{ item = "AmmoShotgun", min = 6, max = 12, weight = 20 },
			{ item = "AmmoRifle", min = 15, max = 30, weight = 15 },
			{ weapon = "Pistol", weight = 15 },
			{ weapon = "Shotgun", weight = 12 },
			{ weapon = "AssaultRifle", weight = 6 },
		},
	},
}

return ContainerDefs
