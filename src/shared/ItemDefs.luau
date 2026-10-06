-- Objets de l'inventaire (tout ce qui n'est pas une arme).
-- Ajouter un objet = ajouter une entrée ici.
--
--   name      nom affiché
--   short     texte court affiché dans la case d'inventaire
--   category  resource, ammo, food, drink ou medical
--   maxStack  quantité maximum par case
--   color     couleur de la case
--   use       effet quand on l'utilise : hunger, thirst (points rendus), heal (vie)
--   useTime   secondes pour l'utiliser (on ne peut pas tirer pendant ce temps)

local ItemDefs = {}

ItemDefs.Categories = {
	resource = { name = "Ressource", order = 4 },
	ammo = { name = "Munitions", order = 3 },
	food = { name = "Nourriture", order = 1 },
	drink = { name = "Boisson", order = 1 },
	medical = { name = "Soin", order = 2 },
}

ItemDefs.Items = {
	-- Ressources (réparer les armes, et plus tard construire)
	Wood = { name = "Bois", short = "BOIS", category = "resource", maxStack = 100, color = Color3.fromRGB(150, 105, 60) },
	Scrap = { name = "Ferraille", short = "FER", category = "resource", maxStack = 50, color = Color3.fromRGB(130, 135, 145) },
	Cloth = { name = "Tissu", short = "TISSU", category = "resource", maxStack = 50, color = Color3.fromRGB(190, 175, 140) },

	-- Munitions
	AmmoPistol = { name = "Balles de pistolet", short = "9MM", category = "ammo", maxStack = 60, color = Color3.fromRGB(200, 170, 60) },
	AmmoShotgun = { name = "Cartouches", short = "CAL.12", category = "ammo", maxStack = 30, color = Color3.fromRGB(200, 60, 50) },
	AmmoRifle = { name = "Balles de fusil", short = "5.56", category = "ammo", maxStack = 90, color = Color3.fromRGB(170, 140, 50) },
	Arrow = { name = "Flèche", short = "FLÈCHE", category = "ammo", maxStack = 30, color = Color3.fromRGB(140, 110, 70) },

	-- Nourriture et boissons
	Berries = {
		name = "Baies",
		short = "BAIES",
		category = "food",
		maxStack = 20,
		color = Color3.fromRGB(170, 40, 70),
		use = { hunger = 8, thirst = 3 },
		useTime = 0.4,
	},
	Chocolate = {
		name = "Barre chocolatée",
		short = "CHOCO",
		category = "food",
		maxStack = 10,
		color = Color3.fromRGB(110, 70, 40),
		use = { hunger = 20 },
		useTime = 0.8,
	},
	CannedFood = {
		name = "Conserve",
		short = "CONSERVE",
		category = "food",
		maxStack = 5,
		color = Color3.fromRGB(180, 120, 60),
		use = { hunger = 45 },
		useTime = 1.5,
	},
	WaterBottle = {
		name = "Bouteille d'eau",
		short = "EAU",
		category = "drink",
		maxStack = 5,
		color = Color3.fromRGB(70, 150, 230),
		use = { thirst = 50 },
		useTime = 1.2,
	},
	Soda = {
		name = "Soda",
		short = "SODA",
		category = "drink",
		maxStack = 5,
		color = Color3.fromRGB(220, 60, 60),
		use = { thirst = 25, hunger = 5 },
		useTime = 0.8,
	},

	-- Soins
	Bandage = {
		name = "Bandage",
		short = "BANDAGE",
		category = "medical",
		maxStack = 10,
		color = Color3.fromRGB(235, 235, 225),
		use = { heal = 25 },
		useTime = 2,
	},
	Medkit = {
		name = "Trousse de soins",
		short = "TROUSSE",
		category = "medical",
		maxStack = 3,
		color = Color3.fromRGB(220, 50, 50),
		use = { heal = 70 },
		useTime = 4,
	},
}

-- Ordre d'affichage (panneau de debug)
ItemDefs.Order = {
	"Wood",
	"Scrap",
	"Cloth",
	"AmmoPistol",
	"AmmoShotgun",
	"AmmoRifle",
	"Arrow",
	"Berries",
	"Chocolate",
	"CannedFood",
	"WaterBottle",
	"Soda",
	"Bandage",
	"Medkit",
}

return ItemDefs
