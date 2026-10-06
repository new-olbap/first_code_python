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

-- Renvoie une copie d'un rig R15 aux couleurs demandées
function Rigs.build(name: string, skinColor: Color3, clothesColor: Color3): Model
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
		cache[key] = model
	end
	return cache[key]:Clone()
end

return Rigs
