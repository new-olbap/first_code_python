-- Construit la carte du prototype avec du code : la forêt de départ, une route,
-- et une ville avec des bâtiments à fouiller et des voitures pour se cacher.
-- On utilise une "graine" fixe pour que la carte soit la même à chaque partie.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local rng = Random.new(42)

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function getZone(id)
	for _, zone in ipairs(Config.Zones) do
		if zone.id == id then
			return zone
		end
	end
	error("Zone inconnue : " .. id)
end

local function randomPointIn(zone, margin)
	local halfX = zone.size.X / 2 - margin
	local halfZ = zone.size.Z / 2 - margin
	return zone.center + Vector3.new(rng:NextNumber(-halfX, halfX), 0, rng:NextNumber(-halfZ, halfZ))
end

local function isFarFrom(point, points, minDistance)
	for _, other in ipairs(points) do
		if (other - point).Magnitude < minDistance then
			return false
		end
	end
	return true
end

-- Supprime la plaque et le point d'apparition du modèle "Baseplate" de Roblox Studio
local function removeDefaults()
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local default = workspace:FindFirstChild(name)
		if default then
			default:Destroy()
		end
	end
end

local function buildGround(parent, zone)
	makePart(
		parent,
		"Terrain_" .. zone.id,
		Vector3.new(zone.size.X, 4, zone.size.Z),
		CFrame.new(zone.center - Vector3.new(0, 2, 0)),
		zone.groundColor,
		zone.groundMaterial
	)
end

local function makeTree(parent, position)
	local height = rng:NextNumber(14, 24)
	local tree = Instance.new("Model")
	tree.Name = "Arbre"

	local trunk = makePart(
		tree,
		"Tronc",
		Vector3.new(height, 2, 2),
		CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(95, 65, 40),
		Enum.Material.Wood
	)
	trunk.Shape = Enum.PartType.Cylinder

	local leavesSize = rng:NextNumber(9, 14)
	local leaves = makePart(
		tree,
		"Feuilles",
		Vector3.new(leavesSize, leavesSize, leavesSize),
		CFrame.new(position + Vector3.new(0, height, 0)),
		Color3.fromRGB(50, rng:NextInteger(95, 130), 45),
		Enum.Material.Grass
	)
	leaves.Shape = Enum.PartType.Ball
	leaves.CanCollide = false

	tree.Parent = parent
end

local function buildForest(parent, spawnPosition)
	local zone = getZone("Foret")
	buildGround(parent, zone)

	local trees = {}
	local folder = Instance.new("Folder")
	folder.Name = "Arbres"
	folder.Parent = parent

	local attempts = 0
	while #trees < 120 and attempts < 2000 do
		attempts += 1
		local point = randomPointIn(zone, 6)
		local onRoad = math.abs(point.X) < 12
		local nearSpawn = (point - spawnPosition).Magnitude < 25
		if not onRoad and not nearSpawn and isFarFrom(point, trees, 9) then
			table.insert(trees, point)
			makeTree(folder, point)
		end
	end

	-- Quelques rochers pour se mettre à couvert
	for _ = 1, 25 do
		local point = randomPointIn(zone, 10)
		if math.abs(point.X) > 12 and isFarFrom(point, trees, 6) then
			local size = rng:NextNumber(3, 7)
			makePart(
				folder,
				"Rocher",
				Vector3.new(size * 1.3, size, size),
				CFrame.new(point + Vector3.new(0, size / 3, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
				Color3.fromRGB(115, 115, 110),
				Enum.Material.Slate
			)
			table.insert(trees, point)
		end
	end

	-- Emplacements de butin au sol, loin des arbres et rochers
	local spots = {}
	attempts = 0
	while #spots < zone.lootSpots and attempts < 1000 do
		attempts += 1
		local point = randomPointIn(zone, 15)
		if isFarFrom(point, trees, 5) and isFarFrom(point, spots, 25) then
			table.insert(spots, point)
		end
	end
	return spots
end

-- Un bâtiment creux avec une porte côté +Z. Renvoie un point au sol à l'intérieur.
local function makeBuilding(parent, center, width, depth, height, color)
	local building = Instance.new("Model")
	building.Name = "Batiment"
	local wall = 1
	local doorWidth, doorHeight = 6, 8
	local brick = Enum.Material.Brick

	-- Mur du fond, murs de gauche et de droite
	makePart(building, "Mur", Vector3.new(width, height, wall), CFrame.new(center + Vector3.new(0, height / 2, -depth / 2 + wall / 2)), color, brick)
	makePart(building, "Mur", Vector3.new(wall, height, depth), CFrame.new(center + Vector3.new(-width / 2 + wall / 2, height / 2, 0)), color, brick)
	makePart(building, "Mur", Vector3.new(wall, height, depth), CFrame.new(center + Vector3.new(width / 2 - wall / 2, height / 2, 0)), color, brick)

	-- Façade avec l'ouverture de la porte
	local side = (width - doorWidth) / 2
	local frontZ = depth / 2 - wall / 2
	makePart(building, "Mur", Vector3.new(side, height, wall), CFrame.new(center + Vector3.new(-width / 2 + side / 2, height / 2, frontZ)), color, brick)
	makePart(building, "Mur", Vector3.new(side, height, wall), CFrame.new(center + Vector3.new(width / 2 - side / 2, height / 2, frontZ)), color, brick)
	makePart(
		building,
		"Linteau",
		Vector3.new(doorWidth, height - doorHeight, wall),
		CFrame.new(center + Vector3.new(0, doorHeight + (height - doorHeight) / 2, frontZ)),
		color,
		brick
	)

	makePart(building, "Toit", Vector3.new(width + 2, 1, depth + 2), CFrame.new(center + Vector3.new(0, height + 0.5, 0)), color:Lerp(Color3.new(0, 0, 0), 0.4))
	makePart(
		building,
		"Sol",
		Vector3.new(width - 2 * wall, 0.2, depth - 2 * wall),
		CFrame.new(center + Vector3.new(0, 0.1, 0)),
		Color3.fromRGB(120, 90, 60),
		Enum.Material.WoodPlanks
	)

	building.Parent = parent
	return center + Vector3.new(rng:NextNumber(-width / 4, width / 4), 0.2, -depth / 4)
end

local function makeCar(parent, position, angle)
	local car = Instance.new("Model")
	car.Name = "Voiture"
	local base = CFrame.new(position) * CFrame.Angles(0, angle, 0)
	local paint = Color3.fromHSV(rng:NextNumber(), 0.4, 0.45)
	makePart(car, "Carrosserie", Vector3.new(6, 2.5, 12), base * CFrame.new(0, 1.75, 0), paint, Enum.Material.Metal)
	makePart(car, "Habitacle", Vector3.new(5.5, 2, 6), base * CFrame.new(0, 4, 1), paint:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Metal)
	car.Parent = parent
end

local function buildTown(parent)
	local zone = getZone("Ville")
	buildGround(parent, zone)

	local asphalt = Color3.fromRGB(50, 50, 55)
	makePart(parent, "Route", Vector3.new(16, 0.2, zone.size.Z), CFrame.new(zone.center + Vector3.new(0, 0.1, 0)), asphalt, Enum.Material.Asphalt)
	for _, z in ipairs({ -335, -425 }) do
		makePart(parent, "Route", Vector3.new(zone.size.X, 0.2, 12), CFrame.new(Vector3.new(0, 0.1, z)), asphalt, Enum.Material.Asphalt)
	end

	local folder = Instance.new("Folder")
	folder.Name = "Batiments"
	folder.Parent = parent

	local spots = {}
	local buildingRects = {}
	local width, depth = 40, 30
	for _, x in ipairs({ -130, -60, 60, 130 }) do
		for _, z in ipairs({ -470, -380, -290 }) do
			local color = Color3.fromHSV(rng:NextNumber(0.02, 0.12), 0.35, rng:NextNumber(0.45, 0.7))
			local height = rng:NextInteger(12, 18)
			local center = Vector3.new(x, 0, z)
			table.insert(spots, makeBuilding(folder, center, width, depth, height, color))
			table.insert(buildingRects, center)
		end
	end

	local function insideBuilding(point)
		for _, center in ipairs(buildingRects) do
			if math.abs(point.X - center.X) < width / 2 + 4 and math.abs(point.Z - center.Z) < depth / 2 + 4 then
				return true
			end
		end
		return false
	end

	-- Voitures abandonnées sur la route principale
	for i = 1, 8 do
		local z = zone.center.Z + zone.size.Z / 2 - i * (zone.size.Z / 9)
		makeCar(folder, Vector3.new(rng:NextNumber(-4, 4), 0.2, z), rng:NextNumber(-0.5, 0.5))
	end

	-- Quelques armes dans la rue, en dehors des bâtiments
	local streetSpots = {}
	local attempts = 0
	while #streetSpots < zone.lootSpots and attempts < 1000 do
		attempts += 1
		local point = randomPointIn(zone, 15)
		if not insideBuilding(point) and math.abs(point.X) > 8 and isFarFrom(point, streetSpots, 25) then
			table.insert(streetSpots, point)
		end
	end
	for _, point in ipairs(streetSpots) do
		table.insert(spots, point)
	end
	return spots
end

local function buildBounds(parent)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, zone in ipairs(Config.Zones) do
		minX = math.min(minX, zone.center.X - zone.size.X / 2)
		maxX = math.max(maxX, zone.center.X + zone.size.X / 2)
		minZ = math.min(minZ, zone.center.Z - zone.size.Z / 2)
		maxZ = math.max(maxZ, zone.center.Z + zone.size.Z / 2)
	end
	local height = 80
	local midX, midZ = (minX + maxX) / 2, (minZ + maxZ) / 2
	local sizeX, sizeZ = maxX - minX, maxZ - minZ
	local walls = {
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, minZ - 1) },
		{ Vector3.new(sizeX, height, 2), Vector3.new(midX, height / 2, maxZ + 1) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(minX - 1, height / 2, midZ) },
		{ Vector3.new(2, height, sizeZ), Vector3.new(maxX + 1, height / 2, midZ) },
	}
	for _, info in ipairs(walls) do
		local wallPart = makePart(parent, "Limite", info[1], CFrame.new(info[2]), Color3.new(0, 0, 0))
		wallPart.Transparency = 1
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

-- Construit toute la carte et renvoie les emplacements de butin par zone
function MapBuilder.build()
	removeDefaults()
	setupLighting()

	local map = Instance.new("Folder")
	map.Name = "Carte"

	local spawnPosition = Vector3.new(0, 0, 170)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PointDeDepart"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 3 -- quelques secondes d'invincibilité à l'apparition
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 0.5, 0))
	spawn.Color = Color3.fromRGB(90, 70, 50)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Parent = map

	local forestSpots = buildForest(map, spawnPosition)
	local townSpots = buildTown(map)

	-- Route de terre qui relie la forêt à la ville
	local forest = getZone("Foret")
	makePart(
		map,
		"Chemin",
		Vector3.new(10, 0.2, forest.size.Z),
		CFrame.new(forest.center + Vector3.new(0, 0.1, 0)),
		Color3.fromRGB(120, 95, 65),
		Enum.Material.Ground
	)

	buildBounds(map)
	map.Parent = workspace

	return {
		lootSpots = {
			Foret = forestSpots,
			Ville = townSpots,
		},
	}
end

return MapBuilder
