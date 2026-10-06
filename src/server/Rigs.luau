-- Fabrique des personnages R15 de couleur unie pour les placeholders
-- (Rôdeur, mannequins). Seul le serveur peut le faire.

local Players = game:GetService("Players")

local Rigs = {}

local cache: { [string]: Model } = {}

-- Rig de secours très simple si Roblox n'arrive pas à créer un R15
local function buildSimpleRig(skinColor: Color3, clothesColor: Color3): Model
	local model = Instance.new("Model")
	local function bodyPart(name: string, size: Vector3, position: Vector3, color: Color3): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.CFrame = CFrame.new(position)
		part.Parent = model
		return part
	end
	local root = bodyPart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), clothesColor)
	root.Transparency = 1
	local pieces = {
		bodyPart("UpperTorso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), clothesColor),
		bodyPart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), skinColor),
		bodyPart("LeftLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), clothesColor),
		bodyPart("RightLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), clothesColor),
	}
	for _, piece in ipairs(pieces) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = piece
		weld.Parent = piece
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

-- Deux yeux lumineux soudés à la tête (pour les monstres)
local function addEyes(model: Model, color: Color3)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.22, 0.12, 0.05)
		eye.Material = Enum.Material.Neon
		eye.Color = color
		eye.CanCollide = false
		eye.CanQuery = false
		eye.Massless = true
		eye.CFrame = head.CFrame * CFrame.new(side * 0.22, 0.12, -head.Size.Z / 2 - 0.02)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = eye
		weld.Parent = eye
		eye.Parent = model
	end
end

-- Renvoie une copie d'un rig R15 aux couleurs demandées
function Rigs.build(name: string, skinColor: Color3, clothesColor: Color3, eyeColor: Color3?): Model
	local key = name .. skinColor:ToHex() .. clothesColor:ToHex()
	if not cache[key] then
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skinColor
		description.LeftArmColor = skinColor
		description.RightArmColor = skinColor
		description.TorsoColor = clothesColor
		description.LeftLegColor = clothesColor
		description.RightLegColor = clothesColor

		local ok, result = pcall(function()
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		local model: Model
		if ok and result then
			model = result
			-- Le script Animate sert aux joueurs ; nos PNJ sont animés par le serveur
			local animate = model:FindFirstChild("Animate")
			if animate then
				animate:Destroy()
			end
		else
			warn("[Rigs] R15 indisponible, rig simple utilisé :", result)
			model = buildSimpleRig(skinColor, clothesColor)
		end
		model.Name = name
		if eyeColor then
			addEyes(model, eyeColor)
		end
		cache[key] = model
	end
	return cache[key]:Clone()
end

return Rigs
