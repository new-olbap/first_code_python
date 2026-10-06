-- Modèles d'armes générés par le code (utilisés quand il n'y a pas de vrai modèle
-- dans ReplicatedStorage/Assets/Weapons). Chaque arme est un Tool :
--   - la pièce "Handle" est le corps de l'arme, l'avant (canon, lame) vers -Z, le haut vers +Y
--   - les autres pièces sont soudées à Handle (WeldConstraint)
--   - l'Attachment "Muzzle" marque le bout du canon
--   - Tool.Grip place la main sur la poignée

local WeaponModels = {}

local METAL = Color3.fromRGB(45, 47, 52)
local DARK = Color3.fromRGB(28, 29, 32)
local STEEL = Color3.fromRGB(170, 172, 178)
local WOOD = Color3.fromRGB(120, 78, 45)
local WOOD_DARK = Color3.fromRGB(85, 55, 32)
local GRIP = Color3.fromRGB(35, 30, 28)

type Builder = {
	tool: Tool,
	handle: Part,
}

local function newTool(name: string, bodySize: Vector3, color: Color3, material: Enum.Material): Builder
	local tool = Instance.new("Tool")
	tool.Name = name
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = bodySize
	handle.Color = color
	handle.Material = material
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CFrame = CFrame.new()
	handle.Parent = tool
	return { tool = tool, handle = handle }
end

-- Ajoute une pièce soudée au corps. offset est relatif au centre de Handle.
local function piece(b: Builder, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.CFrame = b.handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = b.handle
	weld.Part1 = part
	weld.Parent = part
	part.Parent = b.tool
	return part
end

local function wedge(b: Builder, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CFrame = b.handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = b.handle
	weld.Part1 = part
	weld.Parent = part
	part.Parent = b.tool
	return part
end

-- Cylindre orienté le long de l'axe Z (les cylindres Roblox sont sur l'axe X)
local function tube(b: Builder, name: string, diameter: number, length: number, center: Vector3, color: Color3, material: Enum.Material?): Part
	return piece(b, name, Vector3.new(length, diameter, diameter), CFrame.new(center) * CFrame.Angles(0, math.rad(90), 0), color, material, Enum.PartType.Cylinder)
end

local function finish(b: Builder, muzzleZ: number?, gripPoint: Vector3): Tool
	if muzzleZ then
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "Muzzle"
		muzzle.Position = Vector3.new(0, 0, muzzleZ)
		muzzle.Parent = b.handle
	end
	b.tool.Grip = CFrame.new(gripPoint)
	return b.tool
end

local builders: { [string]: (string) -> Tool } = {}

builders.Knife = function(name)
	local b = newTool(name, Vector3.new(0.16, 0.22, 0.55), GRIP, Enum.Material.Fabric)
	piece(b, "Guard", Vector3.new(0.12, 0.38, 0.06), CFrame.new(0, 0.02, -0.3), STEEL, Enum.Material.Metal)
	piece(b, "Blade", Vector3.new(0.04, 0.22, 0.75), CFrame.new(0, 0.03, -0.7), STEEL, Enum.Material.Metal)
	wedge(b, "Tip", Vector3.new(0.04, 0.22, 0.25), CFrame.new(0, 0.03, -1.2), STEEL, Enum.Material.Metal)
	piece(b, "Pommel", Vector3.new(0.18, 0.24, 0.06), CFrame.new(0, 0, 0.3), STEEL, Enum.Material.Metal)
	return finish(b, nil, Vector3.new(0, 0, 0.05))
end

builders.Machete = function(name)
	local b = newTool(name, Vector3.new(0.18, 0.26, 0.6), WOOD_DARK, Enum.Material.Wood)
	piece(b, "Guard", Vector3.new(0.12, 0.36, 0.05), CFrame.new(0, 0.03, -0.32), METAL, Enum.Material.Metal)
	piece(b, "Blade", Vector3.new(0.04, 0.36, 1.6), CFrame.new(0, 0.06, -1.15), STEEL, Enum.Material.Metal)
	piece(b, "BladeBelly", Vector3.new(0.04, 0.12, 0.9), CFrame.new(0, -0.15, -1.45), STEEL, Enum.Material.Metal)
	wedge(b, "Tip", Vector3.new(0.04, 0.48, 0.35), CFrame.new(0, 0, -2.12), STEEL, Enum.Material.Metal)
	return finish(b, nil, Vector3.new(0, 0, 0.05))
end

builders.Bat = function(name)
	local b = newTool(name, Vector3.new(0.24, 0.24, 0.9), Color3.fromRGB(40, 35, 30), Enum.Material.Fabric)
	tube(b, "Knob", 0.36, 0.1, Vector3.new(0, 0, 0.5), WOOD, Enum.Material.Wood)
	tube(b, "Taper", 0.32, 0.9, Vector3.new(0, 0, -0.85), WOOD, Enum.Material.Wood)
	tube(b, "Barrel", 0.44, 1.5, Vector3.new(0, 0, -2), WOOD, Enum.Material.Wood)
	-- Quelques clous : c'est une batte de survie
	for i, z in ipairs({ -1.6, -2.0, -2.4 }) do
		local angle = math.rad(i * 120)
		piece(b, "Nail", Vector3.new(0.04, 0.3, 0.04), CFrame.new(0, 0, z) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 0.25, 0), STEEL, Enum.Material.Metal)
	end
	return finish(b, nil, Vector3.new(0, 0, 0.25))
end

builders.Bow = function(name)
	local b = newTool(name, Vector3.new(0.16, 0.7, 0.2), WOOD_DARK, Enum.Material.Wood)
	piece(b, "Wrap", Vector3.new(0.18, 0.3, 0.22), CFrame.new(), Color3.fromRGB(60, 45, 35), Enum.Material.Fabric)
	-- Branches : 3 segments de chaque côté, de plus en plus inclinés vers l'arrière
	local tipY, tipZ = 0, 0
	for side = -1, 1, 2 do
		local y, z = 0.35, 0
		for segment = 1, 3 do
			local angle = math.rad(10 + segment * 14)
			local length = 0.55
			local dy, dz = math.cos(angle) * length, math.sin(angle) * length
			piece(
				b,
				"Limb",
				Vector3.new(0.1, length, 0.12),
				CFrame.new(0, side * (y + dy / 2), z + dz / 2) * CFrame.Angles(side * angle, 0, 0),
				WOOD,
				Enum.Material.Wood
			)
			y += dy
			z += dz
		end
		tipY, tipZ = y, z
	end
	piece(b, "String", Vector3.new(0.02, tipY * 2, 0.02), CFrame.new(0, 0, tipZ), Color3.fromRGB(230, 225, 210), Enum.Material.Fabric)
	return finish(b, -0.1, Vector3.new(0, 0, 0))
end

builders.Pistol = function(name)
	local b = newTool(name, Vector3.new(0.26, 0.28, 1.15), DARK, Enum.Material.Metal)
	piece(b, "Frame", Vector3.new(0.24, 0.16, 0.95), CFrame.new(0, -0.2, -0.07), METAL)
	piece(b, "Grip", Vector3.new(0.24, 0.7, 0.36), CFrame.new(0, -0.55, 0.33) * CFrame.Angles(math.rad(-14), 0, 0), GRIP, Enum.Material.Fabric)
	piece(b, "TriggerGuard", Vector3.new(0.06, 0.06, 0.32), CFrame.new(0, -0.42, -0.08), METAL)
	piece(b, "Trigger", Vector3.new(0.05, 0.16, 0.05), CFrame.new(0, -0.33, 0), STEEL, Enum.Material.Metal)
	tube(b, "Barrel", 0.12, 0.12, Vector3.new(0, 0.02, -0.63), DARK, Enum.Material.Metal)
	piece(b, "FrontSight", Vector3.new(0.04, 0.06, 0.06), CFrame.new(0, 0.17, -0.5), STEEL, Enum.Material.Metal)
	piece(b, "RearSight", Vector3.new(0.16, 0.06, 0.06), CFrame.new(0, 0.17, 0.5), STEEL, Enum.Material.Metal)
	return finish(b, -0.7, Vector3.new(0, -0.5, 0.33))
end

builders.Shotgun = function(name)
	local b = newTool(name, Vector3.new(0.28, 0.4, 1.1), METAL, Enum.Material.Metal)
	tube(b, "Barrel", 0.16, 2.1, Vector3.new(0, 0.1, -1.6), DARK, Enum.Material.Metal)
	tube(b, "Tube", 0.14, 1.6, Vector3.new(0, -0.08, -1.35), METAL, Enum.Material.Metal)
	piece(b, "Pump", Vector3.new(0.3, 0.26, 0.7), CFrame.new(0, -0.08, -1.25), WOOD, Enum.Material.Wood)
	piece(b, "Grip", Vector3.new(0.22, 0.5, 0.3), CFrame.new(0, -0.38, 0.45) * CFrame.Angles(math.rad(-25), 0, 0), WOOD_DARK, Enum.Material.Wood)
	piece(b, "Stock", Vector3.new(0.24, 0.42, 1.1), CFrame.new(0, -0.12, 1.15) * CFrame.Angles(math.rad(-6), 0, 0), WOOD, Enum.Material.Wood)
	piece(b, "ButtPad", Vector3.new(0.26, 0.5, 0.08), CFrame.new(0, -0.18, 1.72), GRIP, Enum.Material.Fabric)
	piece(b, "TriggerGuard", Vector3.new(0.06, 0.06, 0.3), CFrame.new(0, -0.3, 0.15), METAL)
	piece(b, "Bead", Vector3.new(0.05, 0.05, 0.05), CFrame.new(0, 0.2, -2.6), STEEL, Enum.Material.Metal)
	return finish(b, -2.65, Vector3.new(0, -0.35, 0.45))
end

builders.AssaultRifle = function(name)
	local b = newTool(name, Vector3.new(0.28, 0.4, 1.3), DARK, Enum.Material.Metal)
	piece(b, "Handguard", Vector3.new(0.3, 0.32, 0.95), CFrame.new(0, -0.02, -1.1), Color3.fromRGB(70, 75, 60))
	tube(b, "Barrel", 0.1, 0.7, Vector3.new(0, 0, -1.9), DARK, Enum.Material.Metal)
	tube(b, "Muzzle", 0.16, 0.18, Vector3.new(0, 0, -2.3), METAL, Enum.Material.Metal)
	piece(b, "Rail", Vector3.new(0.14, 0.08, 1.9), CFrame.new(0, 0.24, -0.5), METAL, Enum.Material.Metal)
	piece(b, "Sight", Vector3.new(0.16, 0.16, 0.3), CFrame.new(0, 0.36, 0.1), DARK, Enum.Material.Metal)
	piece(b, "SightGlass", Vector3.new(0.1, 0.1, 0.02), CFrame.new(0, 0.36, -0.06), Color3.fromRGB(90, 160, 200), Enum.Material.Glass)
	piece(b, "Magazine", Vector3.new(0.18, 0.62, 0.3), CFrame.new(0, -0.46, -0.32) * CFrame.Angles(math.rad(12), 0, 0), METAL)
	piece(b, "Grip", Vector3.new(0.22, 0.55, 0.28), CFrame.new(0, -0.42, 0.35) * CFrame.Angles(math.rad(-18), 0, 0), GRIP, Enum.Material.Fabric)
	piece(b, "StockTube", Vector3.new(0.14, 0.14, 0.7), CFrame.new(0, 0.02, 1), METAL, Enum.Material.Metal)
	piece(b, "Stock", Vector3.new(0.22, 0.48, 0.45), CFrame.new(0, -0.08, 1.45), Color3.fromRGB(70, 75, 60))
	return finish(b, -2.4, Vector3.new(0, -0.4, 0.35))
end

-- Construit le placeholder d'une arme
function WeaponModels.build(weaponId: string, color: Color3?): Tool
	local builder = builders[weaponId]
	if builder then
		return builder(weaponId)
	end
	-- Arme sans modèle dédié : un simple bloc
	local b = newTool(weaponId, Vector3.new(0.3, 0.5, 2), color or METAL, Enum.Material.Metal)
	return finish(b, -1, Vector3.new(0, 0, 0.6))
end

return WeaponModels
