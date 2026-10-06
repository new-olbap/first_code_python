-- Placeholders : des objets faits de formes simples, en attendant les vrais modèles.
-- Conventions (les mêmes que pour les vrais modèles, voir docs/ASSETS.md) :
--   - le pivot du modèle est posé au sol, au centre de sa base
--   - l'avant d'un objet regarde vers -Z
--   - une Attachment "ContainerSpot" (attribut ContainerType) rend l'objet fouillable

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local WeaponModels = require(ReplicatedStorage.Shared.WeaponModels)

local Placeholders = {}

local M = Enum.Material

function Placeholders.part(parent: Instance?, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or M.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end
local part = Placeholders.part

function Placeholders.wedge(parent: Instance?, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = material or M.SmoothPlastic
	wedge.Parent = parent
	return wedge
end

-- Cylindre vertical (les cylindres Roblox sont couchés sur l'axe X)
function Placeholders.column(parent: Instance?, name: string, diameter: number, height: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local column = Placeholders.column

function Placeholders.ball(parent: Instance?, name: string, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(diameter, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end
local ball = Placeholders.ball

local function newModel(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	return model
end

local function finish(model: Model, primary: BasePart?): Model
	model.PrimaryPart = primary
	model.WorldPivot = CFrame.new()
	return model
end

-- Feuillage : les balles et la vue des monstres le traversent
local function foliage(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = true
end

-- embedded = true : l'objet lui-même se fouille (coffre de voiture) ;
-- sinon un conteneur (armoire, caisse...) est posé à cet endroit
function Placeholders.containerSpot(parent: BasePart, containerType: string, position: Vector3, embedded: boolean?)
	local spot = Instance.new("Attachment")
	spot.Name = "ContainerSpot"
	spot:SetAttribute("ContainerType", containerType)
	spot:SetAttribute("Embedded", embedded == true)
	spot.Position = position
	spot.Parent = parent
end

-- ARMES -------------------------------------------------------------------------

function Placeholders.weaponTool(weaponId: string): Tool
	local def = WeaponDefs.Weapons[weaponId]
	return WeaponModels.build(weaponId, def and def.color)
end

-- VÉGÉTATION --------------------------------------------------------------------

local function greens(rng: Random, light: boolean?): Color3
	local base = if light then Color3.fromRGB(110, 150, 70) else Color3.fromRGB(55, 105, 45)
	return base:Lerp(Color3.fromRGB(rng:NextInteger(40, 90), rng:NextInteger(90, 140), rng:NextInteger(30, 60)), 0.5)
end

local function oak(rng: Random): Model
	local model = newModel("Tree")
	local height = rng:NextNumber(12, 18)
	local trunk = column(model, "Trunk", rng:NextNumber(1.6, 2.4), height, CFrame.new(0, height / 2, 0), Color3.fromRGB(90, 62, 40), M.Wood)
	for _ = 1, 2 do
		local angle = rng:NextNumber(0, 2 * math.pi)
		column(model, "Branch", 0.8, 5, CFrame.new(0, height * 0.7, 0) * CFrame.Angles(0, angle, math.rad(45)) * CFrame.new(0, 2.2, 0), Color3.fromRGB(90, 62, 40), M.Wood)
	end
	for _ = 1, rng:NextInteger(4, 6) do
		local offset = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(-1.5, 3), rng:NextNumber(-4, 4))
		foliage(ball(model, "Leaves", rng:NextNumber(7, 11), CFrame.new(Vector3.new(0, height, 0) + offset), greens(rng), M.Grass))
	end
	return finish(model, trunk)
end

local function pine(rng: Random): Model
	local model = newModel("Tree")
	local height = rng:NextNumber(18, 28)
	local trunk = column(model, "Trunk", 1.6, height, CFrame.new(0, height / 2, 0), Color3.fromRGB(80, 55, 38), M.Wood)
	local color = Color3.fromRGB(35, rng:NextInteger(75, 95), 45)
	local tiers = 5
	for tier = 1, tiers do
		local t = (tier - 1) / (tiers - 1)
		local diameter = 12 - t * 9
		local y = height * 0.3 + t * height * 0.65
		local layer = column(model, "Leaves", diameter, 2.6, CFrame.new(0, y, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0), color:Lerp(Color3.new(0, 0, 0), t * 0.15), M.Grass)
		foliage(layer)
	end
	foliage(ball(model, "Top", 2.5, CFrame.new(0, height, 0), color, M.Grass))
	return finish(model, trunk)
end

local function birch(rng: Random): Model
	local model = newModel("Tree")
	local height = rng:NextNumber(14, 20)
	local trunk = column(model, "Trunk", 1.2, height, CFrame.new(0, height / 2, 0), Color3.fromRGB(225, 222, 210), M.SmoothPlastic)
	for i = 1, 5 do
		column(model, "Mark", 1.25, 0.25, CFrame.new(0, i * height / 6, 0), Color3.fromRGB(40, 40, 40), M.SmoothPlastic)
	end
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-2.5, 2.5), rng:NextNumber(-2, 2), rng:NextNumber(-2.5, 2.5))
		foliage(ball(model, "Leaves", rng:NextNumber(5, 7), CFrame.new(Vector3.new(0, height, 0) + offset), greens(rng, true), M.Grass))
	end
	return finish(model, trunk)
end

local function deadTree(rng: Random): Model
	local model = newModel("Tree")
	local height = rng:NextNumber(10, 15)
	local bark = Color3.fromRGB(70, 60, 52)
	local trunk = column(model, "Trunk", 1.6, height, CFrame.new(0, height / 2, 0), bark, M.Wood)
	for _ = 1, 3 do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local y = rng:NextNumber(height * 0.5, height * 0.9)
		column(model, "Branch", 0.6, rng:NextNumber(3, 6), CFrame.new(0, y, 0) * CFrame.Angles(0, angle, math.rad(rng:NextNumber(30, 60))) * CFrame.new(0, 2, 0), bark, M.Wood)
	end
	return finish(model, trunk)
end

-- Arbre au hasard (chêne, pin, bouleau ou arbre mort). Les arbres donnent du bois.
function Placeholders.tree(rng: Random): Model
	local roll = rng:NextNumber()
	if roll < 0.4 then
		return pine(rng)
	elseif roll < 0.75 then
		return oak(rng)
	elseif roll < 0.9 then
		return birch(rng)
	end
	return deadTree(rng)
end

-- Buisson de baies : le dossier "Berries" disparaît quand on les cueille
function Placeholders.berryBush(rng: Random): Model
	local model = newModel("BerryBush")
	local main = ball(model, "Bush", 4, CFrame.new(0, 1.6, 0), greens(rng), M.Grass)
	main.CanQuery = false
	for _ = 1, 3 do
		local b = ball(model, "Bush", rng:NextNumber(2.5, 3.5), CFrame.new(rng:NextNumber(-1.5, 1.5), 1.3, rng:NextNumber(-1.5, 1.5)), greens(rng), M.Grass)
		b.CanQuery = false
	end
	local berries = Instance.new("Model")
	berries.Name = "Berries"
	berries.Parent = model
	for _ = 1, 10 do
		local direction = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0, 1), rng:NextNumber(-1, 1)).Unit
		local berry = ball(berries, "Berry", 0.4, CFrame.new(Vector3.new(0, 1.6, 0) + direction * 2), Color3.fromRGB(190, 30, 60), M.SmoothPlastic)
		berry.CanCollide = false
		berry.CanQuery = false
	end
	return finish(model, main)
end

function Placeholders.rock(rng: Random): Model
	local model = newModel("Rock")
	local size = rng:NextNumber(3, 7)
	local color = Color3.fromRGB(110, 110, 105):Lerp(Color3.fromRGB(130, 120, 100), rng:NextNumber())
	local main = part(model, "Rock", Vector3.new(size * 1.3, size, size), CFrame.new(0, size / 3, 0) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)), color, M.Slate)
	for _ = 1, 2 do
		local s = size * rng:NextNumber(0.4, 0.7)
		part(model, "Rock", Vector3.new(s, s * 0.8, s), CFrame.new(rng:NextNumber(-size / 2, size / 2), s / 4, rng:NextNumber(-size / 2, size / 2)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)), color, M.Slate)
	end
	return finish(model, main)
end

function Placeholders.log(rng: Random): Model
	local model = newModel("Log")
	local length = rng:NextNumber(6, 12)
	local log = part(model, "Log", Vector3.new(length, 1.8, 1.8), CFrame.new(0, 0.8, 0), Color3.fromRGB(95, 68, 45), M.Wood)
	log.Shape = Enum.PartType.Cylinder
	return finish(model, log)
end

-- CAMPEMENT DE LA FORÊT -------------------------------------------------------------

function Placeholders.tent(rng: Random): Model
	local model = newModel("Tent")
	local color = Color3.fromRGB(70, 90, 60):Lerp(Color3.fromRGB(120, 100, 60), rng:NextNumber())
	local w, h, d = 6, 4, 7
	local left = Placeholders.wedge(model, "Cloth", Vector3.new(d, h, w / 2), CFrame.new(-w / 4, h / 2, 0) * CFrame.Angles(0, math.rad(90), 0), color, M.Fabric)
	Placeholders.wedge(model, "Cloth", Vector3.new(d, h, w / 2), CFrame.new(w / 4, h / 2, 0) * CFrame.Angles(0, math.rad(-90), 0), color, M.Fabric)
	return finish(model, left)
end

function Placeholders.campfire(): Model
	local model = newModel("Campfire")
	local base = part(model, "Ashes", Vector3.new(3, 0.2, 3), CFrame.new(0, 0.1, 0), Color3.fromRGB(40, 38, 36), M.Slate)
	for i = 1, 6 do
		local angle = i * math.pi / 3
		part(model, "Stone", Vector3.new(0.8, 0.6, 0.8), CFrame.new(math.cos(angle) * 1.8, 0.3, math.sin(angle) * 1.8), Color3.fromRGB(100, 100, 95), M.Slate)
	end
	for i = 1, 3 do
		local logPart = part(model, "Log", Vector3.new(2.4, 0.4, 0.4), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, i * math.pi / 3, math.rad(20)), Color3.fromRGB(70, 45, 30), M.Wood)
		logPart.Shape = Enum.PartType.Cylinder
	end
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Parent = base
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 80)
	light.Range = 18
	light.Brightness = 2
	light.Parent = base
	return finish(model, base)
end

-- Tour de chasse : une échelle, une plateforme, et une cache en haut
function Placeholders.huntingTower(): Model
	local model = newModel("HuntingTower")
	local wood = Color3.fromRGB(105, 75, 48)
	local height = 10
	for _, corner in ipairs({ Vector3.new(-2.5, 0, -2.5), Vector3.new(2.5, 0, -2.5), Vector3.new(-2.5, 0, 2.5), Vector3.new(2.5, 0, 2.5) }) do
		part(model, "Leg", Vector3.new(0.6, height, 0.6), CFrame.new(corner + Vector3.new(0, height / 2, 0)), wood, M.Wood)
	end
	local platform = part(model, "Platform", Vector3.new(6.5, 0.5, 6.5), CFrame.new(0, height, 0), wood, M.WoodPlanks)
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Rail", Vector3.new(6.5, 0.3, 0.3), CFrame.new(0, height + 2.5, side * 3.1), wood, M.Wood)
		part(model, "Rail", Vector3.new(0.3, 0.3, 6.5), CFrame.new(side * 3.1, height + 2.5, 0), wood, M.Wood)
	end
	local roofColor = Color3.fromRGB(60, 75, 50)
	part(model, "Roof", Vector3.new(7.5, 0.4, 7.5), CFrame.new(0, height + 5.5, 0), roofColor, M.Fabric)
	for _, corner in ipairs({ Vector3.new(-3, 0, -3), Vector3.new(3, 0, -3), Vector3.new(-3, 0, 3), Vector3.new(3, 0, 3) }) do
		part(model, "Post", Vector3.new(0.3, 5.5, 0.3), CFrame.new(corner + Vector3.new(0, height + 2.75, 0)), wood, M.Wood)
	end
	-- Échelle (on y grimpe comme sur une échelle Roblox)
	local ladder = Instance.new("TrussPart")
	ladder.Name = "Ladder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, height, 2)
	ladder.CFrame = CFrame.new(0, height / 2, -4.3)
	ladder.Color = wood
	ladder.Material = M.Wood
	ladder.Parent = model
	Placeholders.containerSpot(platform, "HunterStash", Vector3.new(1.5, 0.25, 1.5))
	return finish(model, platform)
end

-- CONTENEURS ---------------------------------------------------------------------

local containers: { [string]: (Random) -> Model } = {}

containers.Crate = function(rng)
	local model = newModel("Crate")
	local size = rng:NextNumber(2.6, 3.4)
	local wood = Color3.fromRGB(150, 110, 65):Lerp(Color3.fromRGB(110, 80, 50), rng:NextNumber())
	local box = part(model, "Box", Vector3.new(size, size * 0.8, size), CFrame.new(0, size * 0.4, 0), wood, M.WoodPlanks)
	local frame = wood:Lerp(Color3.new(0, 0, 0), 0.35)
	for _, y in ipairs({ 0.08, size * 0.8 - 0.08 }) do
		part(model, "Frame", Vector3.new(size + 0.1, 0.25, 0.25), CFrame.new(0, y, -size / 2), frame, M.Wood)
		part(model, "Frame", Vector3.new(size + 0.1, 0.25, 0.25), CFrame.new(0, y, size / 2), frame, M.Wood)
	end
	return finish(model, box)
end

containers.HunterStash = function()
	local model = newModel("HunterStash")
	local box = part(model, "Box", Vector3.new(2.6, 1.4, 1.6), CFrame.new(0, 0.7, 0), Color3.fromRGB(80, 95, 55), M.Fabric)
	part(model, "Tarp", Vector3.new(2.8, 0.2, 1.8), CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(4)), Color3.fromRGB(60, 70, 45), M.Fabric)
	return finish(model, box)
end

containers.Cabinet = function(rng)
	local model = newModel("Cabinet")
	local wood = Color3.fromRGB(110, 80, 55):Lerp(Color3.fromRGB(150, 130, 100), rng:NextNumber())
	local body = part(model, "Body", Vector3.new(3.4, 6, 1.6), CFrame.new(0, 3, 0), wood, M.Wood)
	part(model, "Split", Vector3.new(0.06, 5.6, 0.05), CFrame.new(0, 3, -0.82), wood:Lerp(Color3.new(0, 0, 0), 0.5), M.Wood)
	for _, x in ipairs({ -0.3, 0.3 }) do
		part(model, "Knob", Vector3.new(0.12, 0.4, 0.12), CFrame.new(x, 3.2, -0.86), Color3.fromRGB(180, 160, 100), M.Metal)
	end
	return finish(model, body)
end

containers.Fridge = function()
	local model = newModel("Fridge")
	local white = Color3.fromRGB(225, 225, 220)
	local body = part(model, "Body", Vector3.new(3, 6.4, 2.6), CFrame.new(0, 3.2, 0), white, M.SmoothPlastic)
	part(model, "Seam", Vector3.new(3, 0.06, 0.05), CFrame.new(0, 4.4, -1.31), Color3.fromRGB(150, 150, 150))
	part(model, "Handle", Vector3.new(0.12, 1.4, 0.15), CFrame.new(1.2, 5.2, -1.38), Color3.fromRGB(150, 150, 155), M.Metal)
	part(model, "Handle", Vector3.new(0.12, 1.8, 0.15), CFrame.new(1.2, 3, -1.38), Color3.fromRGB(150, 150, 155), M.Metal)
	return finish(model, body)
end

containers.MedCabinet = function()
	local model = newModel("MedCabinet")
	local body = part(model, "Body", Vector3.new(3, 5, 1.4), CFrame.new(0, 2.5, 0), Color3.fromRGB(235, 235, 235), M.SmoothPlastic)
	part(model, "Cross", Vector3.new(1.2, 0.35, 0.05), CFrame.new(0, 3.6, -0.72), Color3.fromRGB(210, 40, 40), M.Neon)
	part(model, "Cross", Vector3.new(0.35, 1.2, 0.05), CFrame.new(0, 3.6, -0.72), Color3.fromRGB(210, 40, 40), M.Neon)
	return finish(model, body)
end

containers.Bin = function()
	local model = newModel("Bin")
	local green = Color3.fromRGB(45, 85, 55)
	local body = part(model, "Body", Vector3.new(6, 3.6, 3.4), CFrame.new(0, 1.9, 0), green, M.Metal)
	part(model, "Lid", Vector3.new(6.2, 0.3, 3.6), CFrame.new(0, 3.85, 0.1) * CFrame.Angles(math.rad(-8), 0, 0), green:Lerp(Color3.new(0, 0, 0), 0.3), M.Plastic)
	for _, x in ipairs({ -2.5, 2.5 }) do
		local wheel = part(model, "Wheel", Vector3.new(0.4, 0.6, 0.6), CFrame.new(x, 0.3, -1.3), Color3.fromRGB(25, 25, 25), M.Rubber)
		wheel.Shape = Enum.PartType.Cylinder
	end
	return finish(model, body)
end

containers.WeaponLocker = function()
	local model = newModel("WeaponLocker")
	local olive = Color3.fromRGB(70, 80, 60)
	local body = part(model, "Body", Vector3.new(4, 6.5, 1.8), CFrame.new(0, 3.25, 0), olive, M.DiamondPlate)
	for i = 1, 4 do
		part(model, "Vent", Vector3.new(2.6, 0.12, 0.05), CFrame.new(0, 5.6 - i * 0.3, -0.92), olive:Lerp(Color3.new(0, 0, 0), 0.5))
	end
	part(model, "Lock", Vector3.new(0.3, 0.5, 0.15), CFrame.new(1.4, 3.3, -0.96), Color3.fromRGB(190, 170, 60), M.Metal)
	return finish(model, body)
end

-- Conteneur placé seul (dans un bâtiment, dans la rue...)
function Placeholders.container(containerType: string, rng: Random): Model
	local builder = containers[containerType] or containers.Crate
	return builder(rng)
end

-- VILLE ----------------------------------------------------------------------------

-- Voiture abandonnée, avec un coffre fouillable à l'arrière (+Z)
function Placeholders.car(rng: Random): Model
	local model = newModel("Car")
	local paint = Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.2, 0.55), rng:NextNumber(0.3, 0.6))
	local rust = Color3.fromRGB(120, 70, 40)
	local body = part(model, "Body", Vector3.new(6, 1.8, 12.5), CFrame.new(0, 1.9, 0), paint, M.Metal)
	part(model, "Bumper", Vector3.new(6.2, 0.6, 0.5), CFrame.new(0, 1.3, -6.4), Color3.fromRGB(60, 60, 60), M.Metal)
	part(model, "Bumper", Vector3.new(6.2, 0.6, 0.5), CFrame.new(0, 1.3, 6.4), Color3.fromRGB(60, 60, 60), M.Metal)
	part(model, "Cabin", Vector3.new(5.6, 1.9, 6), CFrame.new(0, 3.75, 0.6), paint:Lerp(rust, 0.25), M.Metal)
	local glass = Color3.fromRGB(40, 55, 65)
	part(model, "Windshield", Vector3.new(5.2, 1.6, 0.2), CFrame.new(0, 3.75, -2.45) * CFrame.Angles(math.rad(-20), 0, 0), glass, M.Glass).Transparency = 0.3
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Window", Vector3.new(0.1, 1.3, 4.8), CFrame.new(side * 2.82, 3.85, 0.6), glass, M.Glass).Transparency = 0.3
		for _, z in ipairs({ -4, 4 }) do
			local wheel = part(model, "Wheel", Vector3.new(0.9, 2.2, 2.2), CFrame.new(side * 2.8, 1.1, z), Color3.fromRGB(25, 25, 25), M.Rubber)
			wheel.Shape = Enum.PartType.Cylinder
		end
		part(model, "Headlight", Vector3.new(1, 0.5, 0.1), CFrame.new(side * 2, 2.2, -6.28), Color3.fromRGB(200, 200, 180), M.Glass)
		part(model, "TailLight", Vector3.new(1, 0.4, 0.1), CFrame.new(side * 2, 2.2, 6.28), Color3.fromRGB(150, 30, 30), M.Glass)
	end
	-- Rouille
	for _ = 1, 3 do
		part(model, "Rust", Vector3.new(rng:NextNumber(1, 2), 0.05, rng:NextNumber(1, 3)), CFrame.new(rng:NextNumber(-2, 2), 2.82, rng:NextNumber(-5, 5)), rust, M.CorrodedMetal)
	end
	Placeholders.containerSpot(body, "CarTrunk", Vector3.new(0, 0.9, 5.5), true)
	return finish(model, body)
end

function Placeholders.streetLight(): Model
	local model = newModel("StreetLight")
	local metal = Color3.fromRGB(60, 62, 66)
	local pole = column(model, "Pole", 0.5, 14, CFrame.new(0, 7, 0), metal, M.Metal)
	part(model, "Arm", Vector3.new(0.3, 0.3, 3.5), CFrame.new(0, 13.8, -1.6), metal, M.Metal)
	part(model, "Head", Vector3.new(1.2, 0.4, 1.6), CFrame.new(0, 13.6, -3.2), metal, M.Metal)
	local lamp = part(model, "Lamp", Vector3.new(0.9, 0.1, 1.2), CFrame.new(0, 13.35, -3.2), Color3.fromRGB(255, 220, 160), M.Neon)
	local light = Instance.new("SpotLight")
	light.Name = "StreetLamp"
	light.Face = Enum.NormalId.Bottom
	light.Angle = 110
	light.Range = 30
	light.Brightness = 2.5
	light.Color = Color3.fromRGB(255, 205, 150)
	light.Enabled = false
	light.Parent = lamp
	return finish(model, pole)
end

function Placeholders.bench(): Model
	local model = newModel("Bench")
	local wood = Color3.fromRGB(120, 85, 55)
	local metal = Color3.fromRGB(40, 40, 42)
	local seat = part(model, "Seat", Vector3.new(6, 0.3, 1.6), CFrame.new(0, 1.6, 0), wood, M.WoodPlanks)
	part(model, "Back", Vector3.new(6, 1.4, 0.25), CFrame.new(0, 2.6, 0.75) * CFrame.Angles(math.rad(-10), 0, 0), wood, M.WoodPlanks)
	for _, x in ipairs({ -2.6, 2.6 }) do
		part(model, "Leg", Vector3.new(0.25, 1.6, 1.5), CFrame.new(x, 0.8, 0), metal, M.Metal)
	end
	return finish(model, seat)
end

function Placeholders.barrier(): Model
	local model = newModel("Barrier")
	local concrete = Color3.fromRGB(165, 160, 150)
	local base = part(model, "Base", Vector3.new(8, 1, 2.2), CFrame.new(0, 0.5, 0), concrete, M.Concrete)
	part(model, "Top", Vector3.new(8, 2, 0.9), CFrame.new(0, 2, 0), concrete, M.Concrete)
	Placeholders.wedge(model, "Slope", Vector3.new(8, 1, 0.65), CFrame.new(0, 1.5, -0.77), concrete, M.Concrete)
	Placeholders.wedge(model, "Slope", Vector3.new(8, 1, 0.65), CFrame.new(0, 1.5, 0.77) * CFrame.Angles(0, math.pi, 0), concrete, M.Concrete)
	part(model, "Stripe", Vector3.new(8.02, 0.3, 0.92), CFrame.new(0, 2.6, 0), Color3.fromRGB(200, 60, 40), M.SmoothPlastic)
	return finish(model, base)
end

function Placeholders.cone(): Model
	local model = newModel("Cone")
	local base = part(model, "Base", Vector3.new(1.4, 0.15, 1.4), CFrame.new(0, 0.08, 0), Color3.fromRGB(230, 100, 30))
	column(model, "Cone", 0.7, 1.6, CFrame.new(0, 0.9, 0), Color3.fromRGB(240, 110, 30))
	column(model, "Stripe", 0.75, 0.25, CFrame.new(0, 1.1, 0), Color3.fromRGB(240, 240, 240))
	return finish(model, base)
end

function Placeholders.tires(rng: Random): Model
	local model = newModel("Tires")
	local first
	for i = 1, rng:NextInteger(2, 4) do
		local tire = part(model, "Tire", Vector3.new(0.9, 2.6, 2.6), CFrame.new(rng:NextNumber(-0.2, 0.2), (i - 0.5) * 0.9, rng:NextNumber(-0.2, 0.2)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(28, 28, 28), M.Rubber)
		tire.Shape = Enum.PartType.Cylinder
		first = first or tire
	end
	return finish(model, first)
end

function Placeholders.utilityPole(): Model
	local model = newModel("UtilityPole")
	local wood = Color3.fromRGB(85, 65, 45)
	local pole = column(model, "Pole", 0.9, 20, CFrame.new(0, 10, 0), wood, M.Wood)
	part(model, "Crossbar", Vector3.new(6, 0.4, 0.4), CFrame.new(0, 18.5, 0), wood, M.Wood)
	for _, x in ipairs({ -2.5, 0, 2.5 }) do
		column(model, "Insulator", 0.35, 0.6, CFrame.new(x, 19, 0), Color3.fromRGB(200, 200, 190), M.Glass)
	end
	return finish(model, pole)
end

-- OBJETS DU JEU ----------------------------------------------------------------------

-- Sac lâché à la mort d'un joueur
function Placeholders.bag(): Model
	local model = newModel("Bag")
	local fabric = Color3.fromRGB(110, 85, 50)
	local bag = part(model, "Bag", Vector3.new(2, 1.6, 1.4), CFrame.new(0, 0.8, 0), fabric, M.Fabric)
	part(model, "Flap", Vector3.new(2.05, 0.6, 1.45), CFrame.new(0, 1.35, 0), fabric:Lerp(Color3.new(0, 0, 0), 0.25), M.Fabric)
	part(model, "Strap", Vector3.new(0.3, 1.7, 1.5), CFrame.new(-0.5, 0.8, 0), Color3.fromRGB(60, 45, 30), M.Fabric)
	part(model, "Strap", Vector3.new(0.3, 1.7, 1.5), CFrame.new(0.5, 0.8, 0), Color3.fromRGB(60, 45, 30), M.Fabric)
	return finish(model, bag)
end

-- Petit sac pour les objets jetés par un joueur
function Placeholders.pouch(): Model
	local model = newModel("Pouch")
	local pouch = part(model, "Pouch", Vector3.new(1.2, 0.9, 0.9), CFrame.new(0, 0.45, 0), Color3.fromRGB(150, 130, 90), M.Fabric)
	return finish(model, pouch)
end

-- Flèche (pointe vers -Z)
function Placeholders.arrow(): Model
	local model = newModel("Arrow")
	local shaft = part(model, "Shaft", Vector3.new(0.1, 0.1, 2.6), CFrame.new(0, 0, 0), Color3.fromRGB(150, 110, 70), M.Wood)
	Placeholders.wedge(model, "Tip", Vector3.new(0.06, 0.22, 0.35), CFrame.new(0, 0, -1.45), Color3.fromRGB(80, 80, 85), M.Metal)
	for _, angle in ipairs({ 0, 120, 240 }) do
		part(model, "Feather", Vector3.new(0.02, 0.25, 0.5), CFrame.new(0, 0, 1.1) * CFrame.Angles(0, 0, math.rad(angle)) * CFrame.new(0, 0.12, 0), Color3.fromRGB(200, 60, 50), M.Fabric)
	end
	return finish(model, shaft)
end

return Placeholders
