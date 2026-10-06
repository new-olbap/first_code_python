-- Générateur de bâtiments (placeholders). Chaque bâtiment est un Model :
--   - pivot au sol, au centre ; porte d'entrée sur la face avant (-Z)
--   - des Attachments "LootSpot" (arme au sol) et "ContainerSpot" (attribut
--     ContainerType) indiquent où mettre du butin
-- Pour un vrai modèle : ReplicatedStorage/Assets/Buildings/<Type> (voir docs/ASSETS.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placeholders = require(ReplicatedStorage.Shared.Placeholders)

local Buildings = {}

local M = Enum.Material
local part = Placeholders.part
local wedge = Placeholders.wedge

local WALL = 1 -- épaisseur des murs
local STORY = 10 -- hauteur d'un étage

type Opening = { x: number, width: number, bottom: number, top: number, window: boolean? }
type Style = {
	wall: Color3,
	wallMaterial: Enum.Material,
	trim: Color3,
	roof: Color3,
	roofMaterial: Enum.Material,
	floor: Color3,
	floorMaterial: Enum.Material,
}

-- Le conteneur posé regarde vers le -Z de worldCFrame : contre le mur du fond,
-- pas de rotation ; contre le mur de droite, 90° ; contre celui de gauche, -90°.
local function addSpot(parent: BasePart, name: string, worldCFrame: CFrame, containerType: string?)
	local spot = Instance.new("Attachment")
	spot.Name = name
	spot.CFrame = parent.CFrame:ToObjectSpace(worldCFrame)
	if containerType then
		spot:SetAttribute("ContainerType", containerType)
	end
	spot.Parent = parent
end

-- Mur avec des ouvertures (portes, fenêtres). frame = centre du bas du mur ;
-- le mur s'étend sur l'axe X de frame, l'épaisseur sur son axe Z.
local function wall(model: Model, frame: CFrame, length: number, height: number, openings: { Opening }, style: Style, rng: Random)
	table.sort(openings, function(a, b)
		return a.x < b.x
	end)
	local function segment(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 then
			part(model, "Wall", Vector3.new(x1 - x0, y1 - y0, WALL), frame * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0), style.wall, style.wallMaterial)
		end
	end

	local cursor = -length / 2
	for _, opening in ipairs(openings) do
		local left, right = opening.x - opening.width / 2, opening.x + opening.width / 2
		segment(cursor, left, 0, height)
		segment(left, right, 0, opening.bottom)
		segment(left, right, opening.top, height)
		cursor = right

		if opening.window then
			-- Rebord et encadrement
			part(model, "Sill", Vector3.new(opening.width + 0.6, 0.3, WALL + 0.4), frame * CFrame.new(opening.x, opening.bottom, 0), style.trim, M.Wood)
			part(model, "Lintel", Vector3.new(opening.width + 0.6, 0.4, WALL + 0.2), frame * CFrame.new(opening.x, opening.top, 0), style.trim, M.Wood)
			local roll = rng:NextNumber()
			if roll < 0.3 then
				-- Fenêtre condamnée par des planches
				for i = 1, 3 do
					local y = opening.bottom + (opening.top - opening.bottom) * i / 4
					local plank = part(model, "Plank", Vector3.new(opening.width + 0.8, 0.5, 0.2), frame * CFrame.new(opening.x, y, -WALL / 2 - 0.1) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))), Color3.fromRGB(125, 95, 60), M.WoodPlanks)
					plank.CanQuery = false
				end
			elseif roll < 0.55 then
				-- Vitre sale (les balles passent, pas les joueurs)
				local glass = part(model, "Glass", Vector3.new(opening.width, opening.top - opening.bottom, 0.15), frame * CFrame.new(opening.x, (opening.bottom + opening.top) / 2, 0), Color3.fromRGB(150, 175, 185), M.Glass)
				glass.Transparency = 0.6
				glass.CanQuery = false
			end
		end
	end
	segment(cursor, length / 2, 0, height)
end

-- Ouvertures de fenêtres régulières sur un mur
local function windows(length: number, count: number, width: number, bottom: number, top: number, skipCenter: number?): { Opening }
	local list = {}
	for i = 1, count do
		local x = -length / 2 + length * i / (count + 1)
		if not skipCenter or math.abs(x) > skipCenter then
			table.insert(list, { x = x, width = width, bottom = bottom, top = top, window = true })
		end
	end
	return list
end

-- Les 4 murs d'un étage. frontOpenings remplace les fenêtres de la façade.
local function story(model: Model, level: number, width: number, depth: number, style: Style, rng: Random, frontOpenings: { Opening }?, sideWindows: number?)
	local y = level * STORY
	local height = STORY
	local front = frontOpenings or windows(width, 3, 3.5, 3, 7)
	wall(model, CFrame.new(0, y, -depth / 2 + WALL / 2), width, height, front, style, rng)
	wall(model, CFrame.new(0, y, depth / 2 - WALL / 2), width, height, windows(width, 3, 3.5, 3, 7), style, rng)
	local side = sideWindows or 2
	wall(model, CFrame.new(-width / 2 + WALL / 2, y, 0) * CFrame.Angles(0, math.rad(90), 0), depth - 2 * WALL, height, windows(depth - 2 * WALL, side, 3.5, 3, 7), style, rng)
	wall(model, CFrame.new(width / 2 - WALL / 2, y, 0) * CFrame.Angles(0, math.rad(90), 0), depth - 2 * WALL, height, windows(depth - 2 * WALL, side, 3.5, 3, 7), style, rng)
	-- Bandeau décoratif entre les étages
	part(model, "Band", Vector3.new(width + 0.4, 0.5, depth + 0.4), CFrame.new(0, y + height - 0.25, 0), style.trim, M.Concrete).CanQuery = false
end

local function floorSlab(model: Model, width: number, depth: number, style: Style): Part
	return part(model, "Floor", Vector3.new(width - 2 * WALL, 0.2, depth - 2 * WALL), CFrame.new(0, 0.1, 0), style.floor, style.floorMaterial)
end

-- Plancher de l'étage, avec la trémie de l'escalier côté gauche
local function upperFloor(model: Model, level: number, width: number, depth: number, stairWidth: number, style: Style)
	local inner = width - 2 * WALL
	local slabWidth = inner - stairWidth
	part(model, "UpperFloor", Vector3.new(slabWidth, 0.6, depth - 2 * WALL), CFrame.new(-inner / 2 + stairWidth + slabWidth / 2, level * STORY - 0.3, 0), style.floor, style.floorMaterial)
end

-- Escalier plein le long du mur gauche, de l'avant vers l'arrière
local function stairs(model: Model, level: number, width: number, depth: number, stairWidth: number, style: Style)
	local steps = STORY
	local run = depth - 2 * WALL - 4
	local stepDepth = run / steps
	local x = -width / 2 + WALL + stairWidth / 2
	local baseY = (level - 1) * STORY
	for i = 1, steps do
		local z = -depth / 2 + WALL + 2 + (i - 0.5) * stepDepth
		part(model, "Step", Vector3.new(stairWidth, i, stepDepth), CFrame.new(x, baseY + i / 2, z), style.trim, M.WoodPlanks)
	end
end

local function flatRoof(model: Model, width: number, depth: number, height: number, style: Style)
	part(model, "Roof", Vector3.new(width + 1, 0.8, depth + 1), CFrame.new(0, height + 0.4, 0), style.roof, M.Concrete)
	-- Acrotère (petit muret autour du toit)
	for _, z in ipairs({ -depth / 2, depth / 2 }) do
		part(model, "Parapet", Vector3.new(width + 1, 1.2, 0.6), CFrame.new(0, height + 1.4, z), style.trim, M.Concrete)
	end
	for _, x in ipairs({ -width / 2, width / 2 }) do
		part(model, "Parapet", Vector3.new(0.6, 1.2, depth + 1), CFrame.new(x, height + 1.4, 0), style.trim, M.Concrete)
	end
end

-- Toit à deux pans, faîtage parallèle à la façade
local function pitchedRoof(model: Model, width: number, depth: number, height: number, style: Style)
	local rise = depth * 0.35
	local overhang = 1.5
	part(model, "Ceiling", Vector3.new(width, 0.6, depth), CFrame.new(0, height + 0.3, 0), style.roof, style.roofMaterial)
	local half = depth / 2 + overhang
	wedge(model, "Roof", Vector3.new(width + overhang * 2, rise, half), CFrame.new(0, height + 0.6 + rise / 2, -half / 2), style.roof, style.roofMaterial)
	wedge(model, "Roof", Vector3.new(width + overhang * 2, rise, half), CFrame.new(0, height + 0.6 + rise / 2, half / 2) * CFrame.Angles(0, math.pi, 0), style.roof, style.roofMaterial)
	-- Pignons
	for _, x in ipairs({ -width / 2 + WALL / 2, width / 2 - WALL / 2 }) do
		wedge(model, "Gable", Vector3.new(WALL, rise, depth / 2), CFrame.new(x, height + 0.6 + rise / 2, -depth / 4), style.wall, style.wallMaterial)
		wedge(model, "Gable", Vector3.new(WALL, rise, depth / 2), CFrame.new(x, height + 0.6 + rise / 2, depth / 4) * CFrame.Angles(0, math.pi, 0), style.wall, style.wallMaterial)
	end
	-- Cheminée
	part(model, "Chimney", Vector3.new(2, rise + 3, 2), CFrame.new(width / 3, height + rise / 2 + 2, depth / 6), style.trim:Lerp(Color3.fromRGB(120, 60, 50), 0.5), M.Brick)
end

local function sign(model: Model, text: string, width: number, depth: number, y: number, color: Color3)
	local board = part(model, "Sign", Vector3.new(math.min(width - 4, #text * 1.6 + 4), 2.4, 0.4), CFrame.new(0, y, -depth / 2 - 0.3), Color3.fromRGB(30, 30, 32), M.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0.3
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
end

local function awning(model: Model, width: number, depth: number, rng: Random)
	local colors = { Color3.fromRGB(170, 50, 45), Color3.fromRGB(40, 100, 70), Color3.fromRGB(50, 70, 140) }
	local color = colors[rng:NextInteger(1, #colors)]
	local stripes = 8
	local stripeWidth = (width - 2) / stripes
	for i = 1, stripes do
		local x = -width / 2 + 1 + (i - 0.5) * stripeWidth
		local c = if i % 2 == 0 then Color3.fromRGB(230, 225, 210) else color
		local p = wedge(model, "Awning", Vector3.new(stripeWidth, 1.5, 3), CFrame.new(x, 9.2, -depth / 2 - 1.5), c, M.Fabric)
		p.CanQuery = false
	end
end

local function furnitureTable(model: Model, cframe: CFrame)
	local wood = Color3.fromRGB(120, 85, 55)
	part(model, "Table", Vector3.new(4, 0.3, 2.6), cframe * CFrame.new(0, 2.8, 0), wood, M.Wood)
	for _, x in ipairs({ -1.7, 1.7 }) do
		for _, z in ipairs({ -1, 1 }) do
			part(model, "TableLeg", Vector3.new(0.3, 2.7, 0.3), cframe * CFrame.new(x, 1.35, z), wood, M.Wood)
		end
	end
end

local function shelves(model: Model, cframe: CFrame, length: number)
	local metal = Color3.fromRGB(90, 92, 98)
	for i = 0, 3 do
		part(model, "Shelf", Vector3.new(length, 0.2, 1.8), cframe * CFrame.new(0, 0.5 + i * 1.8, 0), metal, M.Metal)
	end
	for _, x in ipairs({ -length / 2, length / 2 }) do
		part(model, "ShelfPost", Vector3.new(0.2, 6, 1.8), cframe * CFrame.new(x, 3, 0), metal, M.Metal)
	end
	-- Quelques produits renversés
	for _ = 1, 6 do
		local y = 0.8 + math.random(0, 3) * 1.8
		part(model, "Box", Vector3.new(0.8, 0.8, 0.8), cframe * CFrame.new(math.random() * (length - 1) - (length - 1) / 2, y, 0), Color3.fromHSV(math.random(), 0.5, 0.7), M.Cardboard).CanQuery = false
	end
end

-- STYLES -----------------------------------------------------------------------------

local function houseStyle(rng: Random): Style
	local paints = {
		Color3.fromRGB(196, 180, 150),
		Color3.fromRGB(160, 175, 170),
		Color3.fromRGB(190, 160, 140),
		Color3.fromRGB(150, 160, 180),
		Color3.fromRGB(200, 190, 170),
	}
	return {
		wall = paints[rng:NextInteger(1, #paints)]:Lerp(Color3.fromRGB(120, 115, 100), rng:NextNumber(0, 0.3)),
		wallMaterial = if rng:NextNumber() < 0.5 then M.WoodPlanks else M.Plaster,
		trim = Color3.fromRGB(235, 230, 220):Lerp(Color3.fromRGB(90, 70, 50), rng:NextNumber(0, 0.7)),
		roof = Color3.fromRGB(120, 55, 45):Lerp(Color3.fromRGB(60, 60, 70), rng:NextNumber()),
		roofMaterial = if rng:NextNumber() < 0.5 then M.RoofShingles else M.ClayRoofTiles,
		floor = Color3.fromRGB(125, 92, 62),
		floorMaterial = M.WoodPlanks,
	}
end

local function brickStyle(rng: Random): Style
	return {
		wall = Color3.fromRGB(150, 75, 60):Lerp(Color3.fromRGB(110, 100, 95), rng:NextNumber(0, 0.6)),
		wallMaterial = M.Brick,
		trim = Color3.fromRGB(190, 185, 175),
		roof = Color3.fromRGB(80, 80, 85),
		roofMaterial = M.Concrete,
		floor = Color3.fromRGB(150, 145, 135),
		floorMaterial = M.CeramicTiles,
	}
end

local function metalStyle(rng: Random): Style
	return {
		wall = Color3.fromRGB(120, 125, 130):Lerp(Color3.fromRGB(140, 95, 60), rng:NextNumber(0, 0.4)),
		wallMaterial = M.CorrodedMetal,
		trim = Color3.fromRGB(70, 72, 76),
		roof = Color3.fromRGB(90, 92, 96),
		roofMaterial = M.CorrodedMetal,
		floor = Color3.fromRGB(115, 112, 108),
		floorMaterial = M.Concrete,
	}
end

-- ARCHÉTYPES -------------------------------------------------------------------------

-- Maison à étage, toit à deux pans
local function house(rng: Random): Model
	local model = Instance.new("Model")
	model.Name = "House"
	local width, depth = 28, 22
	local style = houseStyle(rng)
	local floor = floorSlab(model, width, depth, style)
	local door = { x = 5, width = 5, bottom = 0, top = 8 }
	local front = { door, { x = -6, width = 4, bottom = 3, top = 7, window = true } }
	story(model, 0, width, depth, style, rng, front)
	story(model, 1, width, depth, style, rng)
	upperFloor(model, 1, width, depth, 4, style)
	stairs(model, 1, width, depth, 4, style)
	pitchedRoof(model, width, depth, 2 * STORY, style)
	-- Perron devant la porte
	part(model, "Porch", Vector3.new(7, 0.6, 3), CFrame.new(5, 0.3, -depth / 2 - 1.5), style.trim, M.Concrete)

	furnitureTable(model, CFrame.new(4, 0.2, 2))
	addSpot(floor, "ContainerSpot", CFrame.new(width / 2 - 2.5, 0.2, depth / 2 - 2), "Fridge")
	addSpot(floor, "ContainerSpot", CFrame.new(width / 2 - 2, 0.2, -2) * CFrame.Angles(0, math.rad(90), 0), "Cabinet")
	addSpot(floor, "ContainerSpot", CFrame.new(4, STORY, depth / 2 - 2), "Cabinet")
	addSpot(floor, "LootSpot", CFrame.new(-2, STORY, 0))
	-- Lit à l'étage
	part(model, "Bed", Vector3.new(4, 1.4, 7), CFrame.new(width / 2 - 4, STORY + 0.7, -depth / 2 + 5), Color3.fromRGB(150, 60, 60), M.Fabric)
	return model
end

-- Petit immeuble en brique, 2 étages, toit plat
local function apartment(rng: Random): Model
	local model = Instance.new("Model")
	model.Name = "Apartment"
	local width, depth = 32, 24
	local style = brickStyle(rng)
	local floor = floorSlab(model, width, depth, style)
	local front = windows(width, 4, 3.5, 3, 7, 3.5)
	table.insert(front, { x = 0, width = 5, bottom = 0, top = 8 })
	story(model, 0, width, depth, style, rng, front, 3)
	story(model, 1, width, depth, style, rng, windows(width, 4, 3.5, 3, 7), 3)
	upperFloor(model, 1, width, depth, 4, style)
	stairs(model, 1, width, depth, 4, style)
	flatRoof(model, width, depth, 2 * STORY, style)
	-- Climatiseurs sur la façade
	for _ = 1, 2 do
		part(model, "AirConditioner", Vector3.new(2.4, 1.6, 1.4), CFrame.new(rng:NextNumber(-12, 12), STORY + 2, -depth / 2 - 0.7), Color3.fromRGB(200, 200, 195), M.Metal)
	end

	addSpot(floor, "ContainerSpot", CFrame.new(width / 2 - 2.5, 0.2, depth / 2 - 2), "Fridge")
	addSpot(floor, "ContainerSpot", CFrame.new(width / 2 - 2, STORY, 0) * CFrame.Angles(0, math.rad(90), 0), "Cabinet")
	addSpot(floor, "ContainerSpot", CFrame.new(0, STORY, depth / 2 - 2), "MedCabinet")
	addSpot(floor, "LootSpot", CFrame.new(6, 0.2, 4))
	furnitureTable(model, CFrame.new(6, STORY, -4))
	return model
end

-- Magasin : grande vitrine, enseigne, auvent, étagères
local SHOPS = {
	{ text = "ÉPICERIE", color = Color3.fromRGB(120, 220, 120), containers = { "Fridge", "Fridge", "Cabinet" } },
	{ text = "PHARMACIE", color = Color3.fromRGB(90, 230, 120), containers = { "MedCabinet", "MedCabinet", "Cabinet" } },
	{ text = "ARMURERIE", color = Color3.fromRGB(240, 90, 60), containers = { "WeaponLocker", "Cabinet", "Crate" } },
	{ text = "QUINCAILLERIE", color = Color3.fromRGB(240, 200, 80), containers = { "Crate", "Cabinet", "Cabinet" } },
	{ text = "BAR", color = Color3.fromRGB(255, 120, 200), containers = { "Fridge", "Cabinet", "Bin" } },
}

local function shop(rng: Random, kind: number?): Model
	local model = Instance.new("Model")
	model.Name = "Shop"
	local info = SHOPS[kind or rng:NextInteger(1, #SHOPS)]
	local width, depth = 34, 26
	local style = if rng:NextNumber() < 0.5 then brickStyle(rng) else houseStyle(rng)
	style.wallMaterial = if style.wallMaterial == M.WoodPlanks then M.Plaster else style.wallMaterial
	local floor = floorSlab(model, width, depth, style)
	local front = {
		{ x = 0, width = 6, bottom = 0, top = 8 },
		{ x = -10, width = 10, bottom = 2.5, top = 8, window = true },
		{ x = 10, width = 10, bottom = 2.5, top = 8, window = true },
	}
	story(model, 0, width, depth, style, rng, front, 2)
	flatRoof(model, width, depth, STORY, style)
	sign(model, info.text, width, depth, 9.2 + 1.6, info.color)
	awning(model, width, depth, rng)

	-- Comptoir et rayons
	part(model, "Counter", Vector3.new(8, 3.4, 2), CFrame.new(-8, 1.9, 4), Color3.fromRGB(110, 80, 55), M.Wood)
	shelves(model, CFrame.new(5, 0.2, 2), 12)
	shelves(model, CFrame.new(5, 0.2, 7), 12)

	local spots = {
		CFrame.new(-width / 2 + 2, 0.2, depth / 2 - 2.5),
		CFrame.new(width / 2 - 2.5, 0.2, depth / 2 - 2),
		CFrame.new(-8, 0.2, 7.5),
	}
	for index, containerType in ipairs(info.containers) do
		addSpot(floor, "ContainerSpot", spots[index], containerType)
	end
	addSpot(floor, "LootSpot", CFrame.new(-4, 0.2, -6))
	return model
end

-- Entrepôt en tôle : grande porte, caisses partout
local function warehouse(rng: Random): Model
	local model = Instance.new("Model")
	model.Name = "Warehouse"
	local width, depth = 40, 30
	local style = metalStyle(rng)
	local height = 16
	local floor = floorSlab(model, width, depth, style)
	local high = function(length: number)
		return windows(length, 4, 4, 12, 14.5)
	end
	local front = high(width)
	for index = #front, 1, -1 do
		if math.abs(front[index].x) < 9 then
			table.remove(front, index)
		end
	end
	table.insert(front, { x = 0, width = 12, bottom = 0, top = 10 })
	wall(model, CFrame.new(0, 0, -depth / 2 + WALL / 2), width, height, front, style, rng)
	wall(model, CFrame.new(0, 0, depth / 2 - WALL / 2), width, height, high(width), style, rng)
	for _, x in ipairs({ -width / 2 + WALL / 2, width / 2 - WALL / 2 }) do
		wall(model, CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(90), 0), depth - 2 * WALL, height, high(depth - 2 * WALL), style, rng)
	end
	-- Toit en pente douce
	wedge(model, "Roof", Vector3.new(width + 2, 3, depth / 2 + 1), CFrame.new(0, height + 1.5, -depth / 4 - 0.5), style.roof, style.roofMaterial)
	wedge(model, "Roof", Vector3.new(width + 2, 3, depth / 2 + 1), CFrame.new(0, height + 1.5, depth / 4 + 0.5) * CFrame.Angles(0, math.pi, 0), style.roof, style.roofMaterial)
	part(model, "Ceiling", Vector3.new(width, 0.5, depth), CFrame.new(0, height + 0.25, 0), style.roof, style.roofMaterial)
	-- Rideau métallique à moitié levé
	part(model, "Shutter", Vector3.new(12, 2.5, 0.3), CFrame.new(0, 8.75, -depth / 2 - 0.2), Color3.fromRGB(150, 150, 140), M.DiamondPlate)

	-- Palettes et racks
	for i = 1, 4 do
		part(model, "Pallet", Vector3.new(4, 0.5, 4), CFrame.new(-14 + i * 5.5, 0.45, 9), Color3.fromRGB(150, 115, 70), M.WoodPlanks)
		part(model, "Load", Vector3.new(3.6, rng:NextNumber(2, 4), 3.6), CFrame.new(-14 + i * 5.5, 2.2, 9), Color3.fromRGB(170, 140, 100), M.Cardboard)
	end
	shelves(model, CFrame.new(-12, 0.2, -6) * CFrame.Angles(0, math.rad(90), 0), 10)

	addSpot(floor, "ContainerSpot", CFrame.new(12, 0.2, -8), "Crate")
	addSpot(floor, "ContainerSpot", CFrame.new(15, 0.2, 2), "Crate")
	addSpot(floor, "ContainerSpot", CFrame.new(-width / 2 + 2, 0.2, 8) * CFrame.Angles(0, math.rad(-90), 0), if rng:NextNumber() < 0.35 then "WeaponLocker" else "Cabinet")
	addSpot(floor, "LootSpot", CFrame.new(4, 0.2, -4))
	return model
end

-- Ruine : maison effondrée, à moitié sans toit, gravats
local function ruin(rng: Random): Model
	local model = Instance.new("Model")
	model.Name = "Ruin"
	local width, depth = 28, 22
	local style = brickStyle(rng)
	style.wall = style.wall:Lerp(Color3.fromRGB(80, 75, 70), 0.4)
	local floor = floorSlab(model, width, depth, style)
	-- Murs à des hauteurs irrégulières
	local function brokenWall(frame: CFrame, length: number, openings: { Opening })
		local pieces = 4
		for i = 1, pieces do
			local x0 = -length / 2 + (i - 1) * length / pieces
			local h = rng:NextNumber(3, STORY)
			local segmentOpenings = {}
			for _, o in ipairs(openings) do
				if o.x >= x0 and o.x < x0 + length / pieces then
					table.insert(segmentOpenings, { x = o.x - (x0 + length / pieces / 2), width = o.width, bottom = o.bottom, top = math.min(o.top, h - 0.5), window = o.window })
				end
			end
			wall(model, frame * CFrame.new(x0 + length / pieces / 2, 0, 0), length / pieces, h, segmentOpenings, style, rng)
		end
	end
	brokenWall(CFrame.new(0, 0, -depth / 2 + WALL / 2), width, { { x = -4, width = 5, bottom = 0, top = 8 } })
	brokenWall(CFrame.new(0, 0, depth / 2 - WALL / 2), width, {})
	brokenWall(CFrame.new(-width / 2 + WALL / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0), depth - 2 * WALL, {})
	brokenWall(CFrame.new(width / 2 - WALL / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0), depth - 2 * WALL, { { x = 2.5, width = 4, bottom = 3, top = 7, window = true } })
	-- Morceau de toit effondré
	wedge(model, "Collapsed", Vector3.new(14, 6, 10), CFrame.new(6, 3, 3) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0), style.roof, M.Concrete)
	for _ = 1, 8 do
		local s = rng:NextNumber(1, 2.5)
		part(model, "Rubble", Vector3.new(s, s * 0.6, s), CFrame.new(rng:NextNumber(-12, 12), s * 0.3, rng:NextNumber(-9, 9)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), 0), style.wall, M.Brick)
	end
	addSpot(floor, "ContainerSpot", CFrame.new(-9, 0.2, 6), "Crate")
	addSpot(floor, "LootSpot", CFrame.new(-6, 0.2, -2))
	return model
end

Buildings.Types = {
	House = house,
	Apartment = apartment,
	Shop = shop,
	Warehouse = warehouse,
	Ruin = ruin,
}

-- Construit le placeholder d'un bâtiment (shopKind : index dans SHOPS, pour varier les magasins)
function Buildings.build(buildingType: string, rng: Random, shopKind: number?): Model
	local model
	if buildingType == "Shop" then
		model = shop(rng, shopKind)
	else
		model = (Buildings.Types[buildingType] or house)(rng)
	end
	model.PrimaryPart = model:FindFirstChild("Floor") :: BasePart
	model.WorldPivot = CFrame.new()
	return model
end

Buildings.ShopCount = #SHOPS

return Buildings
