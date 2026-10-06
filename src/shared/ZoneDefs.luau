-- Zones de la carte du prototype : la forêt (départ) et une ville.
-- loot = poids de chaque arme : plus le chiffre est grand, plus l'arme est fréquente.
-- prowlerGroups = nombre de groupes de Rôdeurs de jour (doublé la nuit).

local ZoneDefs = {}

ZoneDefs.Zones = {
	{
		id = "Forest",
		name = "Forêt",
		center = Vector3.new(0, 0, 0),
		size = Vector3.new(400, 0, 400),
		groundColor = Color3.fromRGB(75, 120, 60),
		groundMaterial = Enum.Material.Grass,
		loot = { Knife = 35, Bat = 25, Machete = 15, Bow = 15, Pistol = 10 },
		groundLootSpots = 10,
		prowlerGroups = 2,
		trees = 120,
		rocks = 25,
	},
	{
		id = "Town",
		name = "Ville",
		center = Vector3.new(0, 0, -380),
		size = Vector3.new(400, 0, 360),
		groundColor = Color3.fromRGB(110, 110, 105),
		groundMaterial = Enum.Material.Concrete,
		loot = { Bat = 10, Machete = 10, Bow = 5, Pistol = 40, Shotgun = 22, AssaultRifle = 13 },
		groundLootSpots = 5, -- dans la rue ; les bâtiments ont leurs propres emplacements
		prowlerGroups = 4,
	},
}

-- Point de départ des joueurs (dans la forêt)
ZoneDefs.SpawnPosition = Vector3.new(0, 0, 170)

-- Zone de test : un enclos près du départ avec toutes les armes et des mannequins
ZoneDefs.TestZone = {
	center = Vector3.new(150, 0, 140),
	size = Vector3.new(70, 0, 110),
}

function ZoneDefs.get(id)
	for _, zone in ipairs(ZoneDefs.Zones) do
		if zone.id == id then
			return zone
		end
	end
	error("Zone inconnue : " .. tostring(id))
end

return ZoneDefs
