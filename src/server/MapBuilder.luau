-- Construit la carte à partir des données de ZoneDefs, avec le terrain Roblox
-- (herbe, terre, asphalte, eau) et des objets chargés par nom (AssetLoader) :
-- glisse un vrai modèle dans ReplicatedStorage/Assets/... pour remplacer un placeholder.
-- Une "graine" fixe rend la carte identique à chaque partie.
--
-- Renvoie ce que les autres systèmes doivent animer : emplacements de butin,
-- conteneurs, arbres, buissons, lampadaires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)
local Buildings = require(script.Parent.Buildings)

local MapBuilder = {}

export type MapInfo = {
	lootSpots: { [string]: { Vector3 } },
	containers: { { containerType: string, cframe: CFrame } },
	embeddedContainers: { Attachment },
	trees: { Model },
	bushes: { Model },
	streetLights: { Light },
}

local rng = Random.new(42)
local terrain = workspace.Terrain
local T = Enum.Material

-- Obstacles déjà posés (position + rayon), pour ne pas tout empiler
type Obstacle = { position: Vector3, radius: number }
local obstacles: { Obstacle } = {}

local function randomPointIn(zone, margin: number): Vector3
	local halfX = zone.size.X / 2 - margin
	local halfZ = zone.size.Z / 2 - margin
	return zone.center + Vector3.new(rng:NextNumber(-halfX, halfX), 0, rng:NextNumber(-halfZ, halfZ))
end

local function inRect(point: Vector3, center: Vector3, size: Vector3, margin: number): boolean
	return math.abs(point.X - center.X) < size.X / 2 + margin and math.abs(point.Z - center.Z) < size.Z / 2 + margin
end

local function isFree(point: Vector3, radius: number): boolean
	for _, obstacle in ipairs(obstacles) do
		if (obstacle.position - point).Magnitude < obstacle.radius + radius then
			return false
		end
	end
	return true
end

local function reserve(point: Vector3, radius: number)
	table.insert(obstacles, { position = point, radius = radius })
end

local function place(parent: Instance, category: string, name: string, builder: () -> Instance, cframe: CFrame): Model
	local model = AssetLoader.get(category, name, builder) :: Model
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

local function yaw(angle: number?): CFrame
	return CFrame.Angles(0, angle or rng:NextNumber(0, 2 * math.pi), 0)
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

-- Couleurs du terrain : des tons un peu ternes, ambiance "monde abandonné"
local function setupTerrainColors()
	terrain:SetMaterialColor(T.Grass, Color3.fromRGB(90, 120, 62))
	terrain:SetMaterialColor(T.LeafyGrass, Color3.fromRGB(80, 105, 55))
	terrain:SetMaterialColor(T.Ground, Color3.fromRGB(105, 85, 62))
	terrain:SetMaterialColor(T.Mud, Color3.fromRGB(85, 68, 52))
	terrain:SetMaterialColor(T.Rock, Color3.fromRGB(110, 108, 102))
	terrain:SetMaterialColor(T.Asphalt, Color3.fromRGB(58, 58, 62))
	terrain:SetMaterialColor(T.Concrete, Color3.fromRGB(125, 122, 115))
	terrain:SetMaterialColor(T.Pavement, Color3.fromRGB(140, 136, 128))
	terrain:SetMaterialColor(T.Sand, Color3.fromRGB(175, 160, 120))
	terrain.WaterColor = Color3.fromRGB(45, 75, 80)
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.08
end

-- Bloc de terrain dont le dessus est au niveau du sol (y = 0)
local function ground(center: Vector3, size: Vector2, material: Enum.Material, depth: number?)
	local d = depth or 4
	terrain:FillBlock(CFrame.new(center.X, -d / 2, center.Z), Vector3.new(size.X, d, size.Y), material)
end

-- FORÊT --------------------------------------------------------------------------

local function buildForest(map: Folder, info: MapInfo)
	local zone = ZoneDefs.get("Forest")
	local folder = Instance.new("Folder")
	folder.Name = "Forest"
	folder.Parent = map

	ground(zone.center, Vector2.new(zone.size.X, zone.size.Z), T.Grass, 16)
	-- Taches d'herbe haute, de terre et de boue
	for _ = 1, 30 do
		local point = randomPointIn(zone, 10)
		local material = ({ T.LeafyGrass, T.LeafyGrass, T.Ground, T.Mud })[rng:NextInteger(1, 4)]
		ground(point, Vector2.new(rng:NextNumber(12, 40), rng:NextNumber(12, 40)), material)
	end
	-- Chemin de terre vers la ville
	ground(Vector3.new(0, 0, 0), Vector2.new(10, zone.size.Z), T.Ground)
	for _ = 1, 10 do
		ground(Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-190, 190)), Vector2.new(8, 8), T.Mud)
	end

	-- Étang avec sa plage de sable
	local pond = Vector3.new(-110, 0, 40)
	terrain:FillCylinder(CFrame.new(pond.X, -2, pond.Z), 4, 21, T.Sand)
	terrain:FillCylinder(CFrame.new(pond.X, -4, pond.Z), 8, 16, T.Water)
	reserve(pond, 22)

	-- Affleurements rocheux (on peut grimper dessus pour avoir de la hauteur)
	for _ = 1, 7 do
		local point = randomPointIn(zone, 30)
		if isFree(point, 12) and math.abs(point.X) > 20 then
			local radius = rng:NextNumber(5, 9)
			terrain:FillBall(Vector3.new(point.X, -radius * 0.35, point.Z), radius, T.Rock)
			reserve(point, radius + 2)
		end
	end

	-- Zones à garder libres : départ, chemin, zone de test
	local spawnArea = ZoneDefs.SpawnPosition
	local testZone = ZoneDefs.TestZone
	local function forestFree(point: Vector3, radius: number): boolean
		return isFree(point, radius)
			and math.abs(point.X) > 8 + radius
			and (point - spawnArea).Magnitude > 22 + radius
			and not inRect(point, testZone.center, testZone.size, radius + 4)
	end

	-- Campements abandonnés : tente, feu de camp, caisses
	for _ = 1, 3 do
		for _ = 1, 30 do
			local point = randomPointIn(zone, 30)
			if forestFree(point, 14) then
				reserve(point, 14)
				local facing = rng:NextNumber(0, 2 * math.pi)
				local frame = CFrame.new(point) * yaw(facing)
				place(folder, "Props", "Tent", function()
					return Placeholders.tent(rng)
				end, frame * CFrame.new(-5, 0, 3))
				place(folder, "Props", "Campfire", Placeholders.campfire, frame * CFrame.new(2, 0, -2))
				place(folder, "Props", "Log", function()
					return Placeholders.log(rng)
				end, frame * CFrame.new(6, 0, -1) * yaw(math.rad(80)))
				table.insert(info.containers, { containerType = "Crate", cframe = frame * CFrame.new(-1, 0, 6) * yaw() })
				table.insert(info.containers, { containerType = "Crate", cframe = frame * CFrame.new(3, 0, 6) * yaw() })
				break
			end
		end
	end

	-- Tours de chasse
	for _ = 1, 2 do
		for _ = 1, 30 do
			local point = randomPointIn(zone, 30)
			if forestFree(point, 8) then
				reserve(point, 8)
				place(folder, "Props", "HuntingTower", Placeholders.huntingTower, CFrame.new(point) * yaw())
				break
			end
		end
	end

	-- Arbres (on garde la trace des troncs pour la coupe du bois)
	local attempts = 0
	while #info.trees < (zone.trees or 120) and attempts < 4000 do
		attempts += 1
		local point = randomPointIn(zone, 5)
		if forestFree(point, 4) then
			reserve(point, 4)
			local tree = place(folder, "Props", "Tree", function()
				return Placeholders.tree(rng)
			end, CFrame.new(point) * yaw())
			table.insert(info.trees, tree)
		end
	end

	-- Buissons de baies, rochers, troncs couchés, caisses isolées
	local function scatter(count: number, radius: number, make: (Vector3) -> ())
		local placed, tries = 0, 0
		while placed < count and tries < count * 40 do
			tries += 1
			local point = randomPointIn(zone, 10)
			if forestFree(point, radius) then
				reserve(point, radius)
				make(point)
				placed += 1
			end
		end
	end
	scatter(30, 3, function(point)
		table.insert(info.bushes, place(folder, "Props", "BerryBush", function()
			return Placeholders.berryBush(rng)
		end, CFrame.new(point) * yaw()))
	end)
	scatter(zone.rocks or 20, 4, function(point)
		place(folder, "Props", "Rock", function()
			return Placeholders.rock(rng)
		end, CFrame.new(point) * yaw())
	end)
	scatter(15, 5, function(point)
		place(folder, "Props", "Log", function()
			return Placeholders.log(rng)
		end, CFrame.new(point) * yaw())
	end)
	scatter(6, 3, function(point)
		table.insert(info.containers, { containerType = "Crate", cframe = CFrame.new(point) * yaw() })
	end)

	-- Armes au sol (peu nombreuses : le gros du butin est dans les conteneurs)
	scatter(zone.groundLootSpots, 3, function(point)
		table.insert(info.lootSpots.Forest, point)
	end)
end

-- VILLE ----------------------------------------------------------------------------

local MAIN_ROAD_X = 0
local CROSS_STREETS = { -335, -425 }
local LOTS_X = { -130, -60, 60, 130 }
local LOTS_Z = { -470, -380, -290 }

local function buildTown(map: Folder, info: MapInfo)
	local zone = ZoneDefs.get("Town")
	local folder = Instance.new("Folder")
	folder.Name = "Town"
	folder.Parent = map

	-- Sol : béton, trottoirs, puis l'asphalte des routes par-dessus
	ground(zone.center, Vector2.new(zone.size.X, zone.size.Z), T.Concrete, 16)
	ground(Vector3.new(MAIN_ROAD_X, 0, zone.center.Z), Vector2.new(24, zone.size.Z), T.Pavement)
	ground(Vector3.new(MAIN_ROAD_X, 0, zone.center.Z), Vector2.new(16, zone.size.Z), T.Asphalt)
	for _, z in ipairs(CROSS_STREETS) do
		ground(Vector3.new(0, 0, z), Vector2.new(zone.size.X, 20), T.Pavement)
		ground(Vector3.new(0, 0, z), Vector2.new(zone.size.X, 12), T.Asphalt)
	end
	-- Lignes blanches au milieu de la route principale
	for z = zone.center.Z - zone.size.Z / 2 + 8, zone.center.Z + zone.size.Z / 2 - 8, 12 do
		local line = Placeholders.part(folder, "RoadLine", Vector3.new(0.4, 0.05, 5), CFrame.new(MAIN_ROAD_X, 0.03, z), Color3.fromRGB(220, 215, 190), T.SmoothPlastic)
		line.CanCollide = false
		line.CanQuery = false
	end

	-- Bâtiments : un mélange de types, et chaque magasin est différent
	local types = { "House", "House", "House", "Apartment", "Apartment", "Shop", "Shop", "Shop", "Shop", "Shop", "Warehouse", "Ruin" }
	for i = #types, 2, -1 do
		local j = rng:NextInteger(1, i)
		types[i], types[j] = types[j], types[i]
	end
	local shopKind = 0
	local index = 0
	for _, x in ipairs(LOTS_X) do
		for _, z in ipairs(LOTS_Z) do
			index += 1
			local buildingType = types[index]
			local center = Vector3.new(x, 0, z)
			-- Jardin devant les maisons, cour en terre ailleurs
			ground(center, Vector2.new(46, 36), if buildingType == "House" then T.LeafyGrass else T.Ground)
			if buildingType == "Shop" then
				shopKind += 1
			end
			local kind = shopKind
			place(folder, "Buildings", buildingType, function()
				return Buildings.build(buildingType, rng, kind)
			end, CFrame.new(center) * yaw(math.pi)) -- porte tournée vers +Z
			reserve(center, 22)

			-- Une poubelle sur le côté de chaque bâtiment
			local side = if rng:NextNumber() < 0.5 then -1 else 1
			table.insert(info.containers, { containerType = "Bin", cframe = CFrame.new(x + side * 22, 0, z + 8) * yaw(math.rad(90 * side)) })
		end
	end

	-- Lampadaires le long des routes
	local function streetLight(position: Vector3, facing: number)
		local lamp = place(folder, "Props", "StreetLight", Placeholders.streetLight, CFrame.new(position) * yaw(facing))
		for _, light in ipairs(lamp:GetDescendants()) do
			if light:IsA("Light") then
				table.insert(info.streetLights, light)
			end
		end
	end
	for z = zone.center.Z - zone.size.Z / 2 + 20, zone.center.Z + zone.size.Z / 2 - 10, 45 do
		-- le bras du lampadaire (vers -Z du modèle) doit pencher au-dessus de la route
		streetLight(Vector3.new(MAIN_ROAD_X - 10, 0, z), math.rad(-90))
		streetLight(Vector3.new(MAIN_ROAD_X + 10, 0, z + 22), math.rad(90))
	end
	for _, z in ipairs(CROSS_STREETS) do
		for x = -170, 170, 60 do
			if math.abs(x) > 20 then
				streetLight(Vector3.new(x, 0, z - 8), math.pi)
			end
		end
	end

	-- Voitures abandonnées (leur coffre se fouille)
	local function car(position: Vector3, angle: number)
		place(folder, "Props", "Car", function()
			return Placeholders.car(rng)
		end, CFrame.new(position) * yaw(angle))
	end
	for i = 1, 7 do
		local z = zone.center.Z + zone.size.Z / 2 - i * (zone.size.Z / 8)
		car(Vector3.new(MAIN_ROAD_X + rng:NextNumber(-4, 4), 0, z), rng:NextNumber(-0.6, 0.6) + (if rng:NextNumber() < 0.5 then 0 else math.pi))
	end
	for _, z in ipairs(CROSS_STREETS) do
		for _ = 1, 2 do
			local x = rng:NextNumber(30, 170) * (if rng:NextNumber() < 0.5 then -1 else 1)
			car(Vector3.new(x, 0, z + rng:NextNumber(-3, 3)), math.rad(90) + rng:NextNumber(-0.4, 0.4))
		end
	end

	-- Barricade à l'entrée de la ville
	local entranceZ = zone.center.Z + zone.size.Z / 2 - 8
	for _, x in ipairs({ -14, 14 }) do
		place(folder, "Props", "Barrier", Placeholders.barrier, CFrame.new(x, 0, entranceZ) * yaw(rng:NextNumber(-0.2, 0.2)))
	end
	for _ = 1, 12 do
		place(folder, "Props", "Cone", Placeholders.cone, CFrame.new(rng:NextNumber(-150, 150), 0, rng:NextNumber(-520, -230)) * yaw())
	end
	for _ = 1, 6 do
		local point = Vector3.new(rng:NextNumber(-160, 160), 0, CROSS_STREETS[rng:NextInteger(1, 2)] + rng:NextNumber(-8, 8))
		if isFree(point, 4) and math.abs(point.X) > 12 then
			place(folder, "Props", "Barrier", Placeholders.barrier, CFrame.new(point) * yaw())
			reserve(point, 4)
		end
	end
	for _ = 1, 5 do
		local point = Vector3.new(rng:NextNumber(-180, 180), 0, rng:NextNumber(-540, -230))
		if isFree(point, 3) then
			place(folder, "Props", "Tires", function()
				return Placeholders.tires(rng)
			end, CFrame.new(point))
		end
	end
	for _, z in ipairs({ -250, -300, -360, -410, -460, -510 }) do
		place(folder, "Props", "Bench", Placeholders.bench, CFrame.new(MAIN_ROAD_X - 11, 0, z + 10) * yaw(math.rad(-90)))
	end
	for z = -230, -540, -50 do
		place(folder, "Props", "UtilityPole", Placeholders.utilityPole, CFrame.new(zone.center.X + zone.size.X / 2 - 6, 0, z))
		place(folder, "Props", "UtilityPole", Placeholders.utilityPole, CFrame.new(zone.center.X - zone.size.X / 2 + 6, 0, z))
	end
	-- Quelques arbres morts entre les bâtiments
	for _ = 1, 12 do
		local point = randomPointIn(zone, 10)
		if isFree(point, 4) and math.abs(point.X) > 14 then
			local tree = place(folder, "Props", "Tree", function()
				return Placeholders.tree(rng)
			end, CFrame.new(point) * yaw())
			table.insert(info.trees, tree)
			reserve(point, 4)
		end
	end

	-- Armes au sol dans la rue
	local placed = 0
	for _ = 1, 400 do
		if placed >= zone.groundLootSpots then
			break
		end
		local point = randomPointIn(zone, 15)
		if isFree(point, 3) and math.abs(point.X) > 8 then
			table.insert(info.lootSpots.Town, point)
			reserve(point, 3)
			placed += 1
		end
	end
end

-- Collines autour de la vallée : elles ferment l'horizon
local function buildHills()
	local minX, maxX, minZ, maxZ = -200, 200, -560, 200
	local function hill(x: number, z: number)
		local radius = rng:NextNumber(45, 70)
		terrain:FillBall(Vector3.new(x, -radius * 0.45, z), radius, if rng:NextNumber() < 0.7 then T.Grass else T.Rock)
	end
	for x = minX - 20, maxX + 20, 55 do
		hill(x, minZ - 60)
		hill(x, maxZ + 60)
	end
	for z = minZ, maxZ, 55 do
		hill(minX - 60, z)
		hill(maxX + 60, z)
	end
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
	local height = 150
	local midX, midZ = (minX + maxX) / 2, (minZ + maxZ) / 2
	local sizeX, sizeZ = maxX - minX, maxZ - minZ
	local walls = {
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, minZ - 1) },
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, maxZ + 1) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(minX - 1, height / 2, midZ) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(maxX + 1, height / 2, midZ) },
	}
	for _, wallInfo in ipairs(walls) do
		local wall = Placeholders.part(parent, "Boundary", wallInfo[1], CFrame.new(wallInfo[2]), Color3.new(0, 0, 0))
		wall.Transparency = 1
		wall.CanQuery = false
	end
end

-- Repère les emplacements de conteneurs et de butin placés dans les modèles
local function collectSpots(map: Folder, info: MapInfo)
	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("Attachment") then
			if descendant.Name == "ContainerSpot" then
				local containerType = descendant:GetAttribute("ContainerType")
				if typeof(containerType) == "string" then
					if descendant:GetAttribute("Embedded") then
						table.insert(info.embeddedContainers, descendant)
					else
						table.insert(info.containers, { containerType = containerType, cframe = descendant.WorldCFrame })
					end
				end
			elseif descendant.Name == "LootSpot" then
				local zoneId = if descendant.WorldPosition.Z < -200 then "Town" else "Forest"
				table.insert(info.lootSpots[zoneId], descendant.WorldPosition)
			end
		end
	end
end

function MapBuilder.build(): MapInfo
	removeDefaults()
	terrain:Clear()
	setupTerrainColors()

	local info: MapInfo = {
		lootSpots = { Forest = {}, Town = {} },
		containers = {},
		embeddedContainers = {},
		trees = {},
		bushes = {},
		streetLights = {},
	}

	local map = Instance.new("Folder")
	map.Name = "Map"

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 3
	spawn.Size = Vector3.new(10, 0.6, 10)
	spawn.CFrame = CFrame.new(ZoneDefs.SpawnPosition + Vector3.new(0, 0.3, 0))
	spawn.Color = Color3.fromRGB(105, 80, 55)
	spawn.Material = T.WoodPlanks
	spawn.Parent = map

	buildForest(map, info)
	buildTown(map, info)
	buildHills()
	buildBounds(map)
	collectSpots(map, info)

	map.Parent = workspace
	return info
end

return MapBuilder
