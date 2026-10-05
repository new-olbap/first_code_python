-- Effets visuels des tirs : traînées de balles et flash du canon.
-- Ils sont créés seulement sur l'écran du joueur, le serveur n'en a pas besoin.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Effects = {}

local folder

local function makeEffectPart(size, cframe, color)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	part.Parent = folder
	return part
end

local function tracer(from, to)
	local distance = (to - from).Magnitude
	if distance < 0.1 then
		return
	end
	local part = makeEffectPart(
		Vector3.new(0.08, 0.08, distance),
		CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2),
		Color3.fromRGB(255, 220, 120)
	)
	TweenService:Create(part, TweenInfo.new(0.12), { Transparency = 1 }):Play()
	Debris:AddItem(part, 0.15)

	local impact = makeEffectPart(Vector3.new(0.4, 0.4, 0.4), CFrame.new(to), Color3.fromRGB(255, 180, 80))
	impact.Shape = Enum.PartType.Ball
	TweenService:Create(impact, TweenInfo.new(0.2), { Transparency = 1, Size = Vector3.new(1, 1, 1) }):Play()
	Debris:AddItem(impact, 0.25)
end

local function muzzleFlash(position)
	local flash = makeEffectPart(Vector3.new(0.6, 0.6, 0.6), CFrame.new(position), Color3.fromRGB(255, 230, 150))
	flash.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = flash.Color
	light.Range = 10
	light.Brightness = 3
	light.Parent = flash
	Debris:AddItem(flash, 0.06)
end

function Effects.start()
	folder = Instance.new("Folder")
	folder.Name = "EffetsLocaux"
	folder.Parent = workspace

	Remotes.ShotFired.OnClientEvent:Connect(function(muzzle, endPoints)
		muzzleFlash(muzzle)
		for _, endPoint in ipairs(endPoints) do
			tracer(muzzle, endPoint)
		end
	end)
end

return Effects
