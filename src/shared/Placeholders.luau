-- Placeholders : des objets faits de formes simples, avec une couleur par type.
-- Conventions (les mêmes que pour les vrais modèles, voir docs/ASSETS.md) :
--   - le pivot du modèle est posé au sol, au centre de sa base
--   - l'avant d'un objet regarde vers -Z
--   - une arme est un Tool dont la pièce "Handle" a sa longueur sur l'axe Z,
--     le canon vers -Z, et une Attachment "Muzzle" au bout du canon

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)

local Placeholders = {}

function Placeholders.part(parent: Instance?, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
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

local function newModel(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	return model
end

-- Arme : un Tool avec une seule pièce "Handle"
function Placeholders.weaponTool(weaponId: string): Tool
	local def = WeaponDefs.Weapons[weaponId]
	local tool = Instance.new("Tool")
	tool.Name = weaponId

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = def.size
	handle.Color = def.color
	handle.Material = if def.kind == "melee" then Enum.Material.Metal else Enum.Material.SmoothPlastic
	handle.Parent = tool

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0, -def.size.Z / 2)
	muzzle.Parent = handle

	-- On tient l'arme par l'arrière, le canon dépasse devant la main
	tool.Grip = CFrame.new(0, 0, def.size.Z / 2 - 0.4)
	return tool
end

function Placeholders.tree(rng: Random): Model
	local model = newModel("Tree")
	local height = rng:NextNumber(14, 24)
	local trunk = Placeholders.part(
		model,
		"Trunk",
		Vector3.new(height, 2, 2),
		CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(95, 65, 40),
		Enum.Material.Wood
	)
	trunk.Shape = Enum.PartType.Cylinder
	local size = rng:NextNumber(9, 14)
	local leaves = Placeholders.part(
		model,
		"Leaves",
		Vector3.new(size, size, size),
		CFrame.new(0, height, 0),
		Color3.fromRGB(50, rng:NextInteger(95, 130), 45),
		Enum.Material.Grass
	)
	leaves.Shape = Enum.PartType.Ball
	leaves.CanCollide = false
	leaves.CanQuery = false -- les balles et la vue des monstres traversent le feuillage
	model.WorldPivot = CFrame.new()
	return model
end

function Placeholders.rock(rng: Random): Model
	local model = newModel("Rock")
	local size = rng:NextNumber(3, 7)
	Placeholders.part(
		model,
		"Rock",
		Vector3.new(size * 1.3, size, size),
		CFrame.new(0, size / 3, 0),
		Color3.fromRGB(115, 115, 110),
		Enum.Material.Slate
	)
	model.WorldPivot = CFrame.new()
	return model
end

function Placeholders.car(rng: Random): Model
	local model = newModel("Car")
	local paint = Color3.fromHSV(rng:NextNumber(), 0.4, 0.45)
	Placeholders.part(model, "Body", Vector3.new(6, 2.5, 12), CFrame.new(0, 1.75, 0), paint, Enum.Material.Metal)
	Placeholders.part(model, "Cabin", Vector3.new(5.5, 2, 6), CFrame.new(0, 4, 1), paint:Lerp(Color3.new(0, 0, 0), 0.3), Enum.Material.Metal)
	model.WorldPivot = CFrame.new()
	return model
end

-- Bâtiment creux, porte sur la face avant (-Z). Les Attachments "LootSpot"
-- indiquent où poser du butin.
function Placeholders.house(rng: Random): Model
	local model = newModel("House")
	local width, depth, height = 40, 30, rng:NextInteger(12, 18)
	local wall = 1
	local doorWidth, doorHeight = 6, 8
	local color = Color3.fromHSV(rng:NextNumber(0.02, 0.12), 0.35, rng:NextNumber(0.45, 0.7))
	local brick = Enum.Material.Brick
	local p = Placeholders.part

	p(model, "Wall", Vector3.new(width, height, wall), CFrame.new(0, height / 2, depth / 2 - wall / 2), color, brick)
	p(model, "Wall", Vector3.new(wall, height, depth), CFrame.new(-width / 2 + wall / 2, height / 2, 0), color, brick)
	p(model, "Wall", Vector3.new(wall, height, depth), CFrame.new(width / 2 - wall / 2, height / 2, 0), color, brick)

	-- Façade avec l'ouverture de la porte
	local side = (width - doorWidth) / 2
	local frontZ = -depth / 2 + wall / 2
	p(model, "Wall", Vector3.new(side, height, wall), CFrame.new(-width / 2 + side / 2, height / 2, frontZ), color, brick)
	p(model, "Wall", Vector3.new(side, height, wall), CFrame.new(width / 2 - side / 2, height / 2, frontZ), color, brick)
	p(model, "Lintel", Vector3.new(doorWidth, height - doorHeight, wall), CFrame.new(0, doorHeight + (height - doorHeight) / 2, frontZ), color, brick)

	-- Un muret intérieur pour avoir de quoi se cacher
	p(model, "Cover", Vector3.new(10, 3.5, 1), CFrame.new(-6, 1.75, 2), color:Lerp(Color3.new(0, 0, 0), 0.2), brick)

	p(model, "Roof", Vector3.new(width + 2, 1, depth + 2), CFrame.new(0, height + 0.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.4))
	local floor = p(model, "Floor", Vector3.new(width - 2 * wall, 0.2, depth - 2 * wall), CFrame.new(0, 0.1, 0), Color3.fromRGB(120, 90, 60), Enum.Material.WoodPlanks)

	for _, offset in ipairs({ Vector3.new(10, 0.1, 8), Vector3.new(-12, 0.1, 9) }) do
		local spot = Instance.new("Attachment")
		spot.Name = "LootSpot"
		spot.Position = offset
		spot.Parent = floor
	end

	model.WorldPivot = CFrame.new()
	return model
end

-- Sac lâché à la mort d'un joueur
function Placeholders.bag(): Model
	local model = newModel("Bag")
	Placeholders.part(model, "Bag", Vector3.new(2, 1.6, 1.4), CFrame.new(0, 0.8, 0), Color3.fromRGB(110, 85, 50), Enum.Material.Fabric)
	Placeholders.part(model, "Strap", Vector3.new(2.1, 0.3, 0.3), CFrame.new(0, 1.3, 0), Color3.fromRGB(60, 45, 30), Enum.Material.Fabric)
	model.WorldPivot = CFrame.new()
	return model
end

-- Flèche (pointe vers -Z)
function Placeholders.arrow(): Model
	local model = newModel("Arrow")
	Placeholders.part(model, "Shaft", Vector3.new(0.12, 0.12, 2.6), CFrame.new(0, 0, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	Placeholders.part(model, "Tip", Vector3.new(0.25, 0.25, 0.3), CFrame.new(0, 0, -1.4), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)
	model.WorldPivot = CFrame.new()
	return model
end

return Placeholders
