-- Construit la carte du prototype à partir des données de ZoneDefs :
-- la forêt de départ, un chemin, et la ville avec ses bâtiments et ses voitures.
-- Arbres, rochers, voitures et bâtiments sont chargés par nom (AssetLoader) :
-- glisse un vrai modèle dans ReplicatedStorage/Assets/Props ou /Buildings pour
-- remplacer le placeholder. Une "graine" fixe rend la carte identique à chaque partie.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)

local MapBuilder = {}

local rng = Random.new(42)
local makePart = Placeholders.part

local function randomPointIn(zone, margin: number): Vector3
	local halfX = zone.size.X / 2 - margin
	local halfZ = zone.size.Z / 2 - margin
	return zone.center + Vector3.new(rng:NextNumber(-halfX, halfX), 0, rng:NextNumber(-halfZ, halfZ))
end

local function isFarFrom(point: Vector3, points: { Vector3 }, minDistance: number): boolean
	for _, other in ipairs(points) do
		if (other - point).Magnitude < minDistance then
			return false
		end
	end
	return true
end

local function inRect(point: Vector3, center: Vector3, size: Vector3, margin: number): boolean
	return math.abs(point.X - center.X) < size.X / 2 + margin and math.abs(point.Z - center.Z) < size.Z / 2 + margin
end

local function placeAsset(parent: Instance, category: string, name: string, builder: () -> Instance, cframe: CFrame): Model
	local model = AssetLoader.get(category, name, builder) :: Model
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

-- Supprime la plaque et le point d'apparition du modèle "Baseplate" de Studio
local function removeDefaults()
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local default = workspace:FindFirstChild(name)
		if default then
			default:Destroy()
		end
	end
end

local function buildGround(parent: Instance, zone)
	makePart(
		parent,
		"Ground_" .. zone.id,
		Vector3.new(zone.size.X, 4, zone.size.Z),
		CFrame.new(zone.center - Vector3.new(0, 2, 0)),
		zone.groundColor,
		zone.groundMaterial
	)
end

local function buildForest(parent: Instance): { Vector3 }
	local zone = ZoneDefs.get("Forest")
	local testZone = ZoneDefs.TestZone
	buildGround(parent, zone)

	local folder = Instance.new("Folder")
	folder.Name = "Forest"
	folder.Parent = parent

	local function isFree(point: Vector3, margin: number): boolean
		local onPath = math.abs(point.X) < 12
		local nearSpawn = (point - ZoneDefs.SpawnPosition).Magnitude < 25
		return not onPath and not nearSpawn and not inRect(point, testZone.center, testZone.size, margin)
	end

	local obstacles = {}
	local attempts = 0
	while #obstacles < zone.trees and attempts < 3000 do
		attempts += 1
		local point = randomPointIn(zone, 6)
		if isFree(point, 6) and isFarFrom(point, obstacles, 9) then
			table.insert(obstacles, point)
			placeAsset(folder, "Props", "Tree", function()
				return Placeholders.tree(rng)
			end, CFrame.new(point) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
		end
	end

	-- Rochers : de quoi se mettre à couvert
	local rocks = 0
	attempts = 0
	while rocks < zone.rocks and attempts < 1000 do
		attempts += 1
		local point = randomPointIn(zone, 10)
		if isFree(point, 4) and isFarFrom(point, obstacles, 6) then
			rocks += 1
			table.insert(obstacles, point)
			placeAsset(folder, "Props", "Rock", function()
				return Placeholders.rock(rng)
			end, CFrame.new(point) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0))
		end
	end

	-- Emplacements de butin au sol, loin des arbres et des rochers
	local spots = {}
	attempts = 0
	while #spots < zone.groundLootSpots and attempts < 1000 do
		attempts += 1
		local point = randomPointIn(zone, 15)
		if isFree(point, 4) and isFarFrom(point, obstacles, 5) and isFarFrom(point, spots, 30) then
			table.insert(spots, point)
		end
	end
	return spots
end

local function buildTown(parent: Instance): { Vector3 }
	local zone = ZoneDefs.get("Town")
	buildGround(parent, zone)

	local asphalt = Color3.fromRGB(50, 50, 55)
	makePart(parent, "Road", Vector3.new(16, 0.2, zone.size.Z), CFrame.new(zone.center + Vector3.new(0, 0.1, 0)), asphalt, Enum.Material.Asphalt)
	for _, z in ipairs({ -335, -425 }) do
		makePart(parent, "Road", Vector3.new(zone.size.X, 0.2, 12), CFrame.new(0, 0.1, z), asphalt, Enum.Material.Asphalt)
	end

	local folder = Instance.new("Folder")
	folder.Name = "Town"
	folder.Parent = parent

	-- 12 bâtiments, porte tournée vers la forêt (+Z)
	local spots = {}
	local houses = {}
	local width, depth = 40, 30
	for _, x in ipairs({ -130, -60, 60, 130 }) do
		for _, z in ipairs({ -470, -380, -290 }) do
			local center = Vector3.new(x, 0, z)
			local house = placeAsset(folder, "Buildings", "House", function()
				return Placeholders.house(rng)
			end, CFrame.new(center) * CFrame.Angles(0, math.pi, 0))
			table.insert(houses, center)
			for _, descendant in ipairs(house:GetDescendants()) do
				if descendant:IsA("Attachment") and descendant.Name == "LootSpot" then
					table.insert(spots, descendant.WorldPosition)
				end
			end
		end
	end

	local function insideHouse(point: Vector3): boolean
		for _, center in ipairs(houses) do
			if inRect(point, center, Vector3.new(width, 0, depth), 4) then
				return true
			end
		end
		return false
	end

	-- Voitures abandonnées sur la route principale : du couvert pour les fusillades
	for i = 1, 8 do
		local z = zone.center.Z + zone.size.Z / 2 - i * (zone.size.Z / 9)
		placeAsset(folder, "Props", "Car", function()
			return Placeholders.car(rng)
		end, CFrame.new(rng:NextNumber(-4, 4), 0.2, z) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0))
	end

	-- Quelques armes dans la rue
	local street = {}
	local attempts = 0
	while #street < zone.groundLootSpots and attempts < 1000 do
		attempts += 1
		local point = randomPointIn(zone, 15)
		if not insideHouse(point) and math.abs(point.X) > 8 and isFarFrom(point, street, 30) then
			table.insert(street, point)
			table.insert(spots, point)
		end
	end
	return spots
end

-- Murs invisibles autour de la carte
local function buildBounds(parent: Instance)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, zone in ipairs(ZoneDefs.Zones) do
		minX = math.min(minX, zone.center.X - zone.size.X / 2)
		maxX = math.max(maxX, zone.center.X + zone.size.X / 2)
		minZ = math.min(minZ, zone.center.Z - zone.size.Z / 2)
		maxZ = math.max(maxZ, zone.center.Z + zone.size.Z / 2)
	end
	local height = 100
	local midX, midZ = (minX + maxX) / 2, (minZ + maxZ) / 2
	local sizeX, sizeZ = maxX - minX, maxZ - minZ
	local walls = {
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, minZ - 1) },
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, maxZ + 1) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(minX - 1, height / 2, midZ) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(maxX + 1, height / 2, midZ) },
	}
	for _, info in ipairs(walls) do
		local wall = makePart(parent, "Boundary", info[1], CFrame.new(info[2]), Color3.new(0, 0, 0))
		wall.Transparency = 1
		wall.CanQuery = false
	end
end

local function setupLighting()
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Haze = 1
		atmosphere.Parent = Lighting
	end
end

-- Construit la carte et renvoie les emplacements de butin par zone
function MapBuilder.build(): { [string]: { Vector3 } }
	removeDefaults()
	setupLighting()

	local map = Instance.new("Folder")
	map.Name = "Map"

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 3
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(ZoneDefs.SpawnPosition + Vector3.new(0, 0.5, 0))
	spawn.Color = Color3.fromRGB(90, 70, 50)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Parent = map

	local lootSpots = {
		Forest = buildForest(map),
		Town = buildTown(map),
	}

	-- Chemin de terre qui relie la forêt à la ville
	local forest = ZoneDefs.get("Forest")
	makePart(map, "Path", Vector3.new(10, 0.2, forest.size.Z), CFrame.new(forest.center + Vector3.new(0, 0.1, 0)), Color3.fromRGB(120, 95, 65), Enum.Material.Ground)

	buildBounds(map)
	map.Parent = workspace
	return lootSpots
end

return MapBuilder
