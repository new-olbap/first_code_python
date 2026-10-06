-- Effets visuels et sonores des armes. Tout est local à l'écran du joueur :
-- les tirs du joueur sont affichés tout de suite (sans attendre le serveur),
-- ceux des autres joueurs arrivent par le RemoteEvent WeaponFx.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local Ballistics = require(ReplicatedStorage.Shared.Ballistics)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)

local Effects = {}

Effects.folder = Instance.new("Folder")
Effects.folder.Name = "LocalEffects"

local TRACER_COLOR = Color3.fromRGB(255, 220, 120)

local function effectPart(size: Vector3, cframe: CFrame, color: Color3): Part
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
	part.Parent = Effects.folder
	return part
end

local function tracer(from: Vector3, to: Vector3)
	local distance = (to - from).Magnitude
	if distance < 0.1 then
		return
	end
	local part = effectPart(Vector3.new(0.07, 0.07, distance), CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2), TRACER_COLOR)
	TweenService:Create(part, TweenInfo.new(0.1), { Transparency = 1 }):Play()
	Debris:AddItem(part, 0.12)
end

local function impact(position: Vector3)
	local spark = effectPart(Vector3.new(0.3, 0.3, 0.3), CFrame.new(position), Color3.fromRGB(255, 180, 80))
	spark.Shape = Enum.PartType.Ball
	TweenService:Create(spark, TweenInfo.new(0.18), { Transparency = 1, Size = Vector3.new(1.1, 1.1, 1.1) }):Play()
	Debris:AddItem(spark, 0.2)
end

local function muzzleFlash(position: Vector3)
	local flash = effectPart(Vector3.new(0.7, 0.7, 0.7), CFrame.new(position), Color3.fromRGB(255, 230, 150))
	flash.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = flash.Color
	light.Range = 12
	light.Brightness = 4
	light.Parent = flash
	Debris:AddItem(flash, 0.05)
end

-- Tir d'arme à feu : flash, traînées, impacts, son qui porte aussi loin que le bruit
function Effects.shot(weaponId: string, muzzle: Vector3, endPoints: { Vector3 })
	local def = WeaponDefs.Weapons[weaponId]
	if not def then
		return
	end
	muzzleFlash(muzzle)
	for _, endPoint in ipairs(endPoints) do
		tracer(muzzle, endPoint)
		impact(endPoint)
	end
	if def.sounds.fire then
		SoundPlayer.playAt(muzzle, def.sounds.fire, def.noise * 2)
	end
end

function Effects.swing(weaponId: string, position: Vector3)
	local def = WeaponDefs.Weapons[weaponId]
	if def and def.sounds.swing then
		SoundPlayer.playAt(position, def.sounds.swing, 40)
	end
end

-- Flèche : même trajectoire que celle simulée par le serveur
function Effects.arrow(weaponId: string, origin: Vector3, velocity: Vector3, ignore: { Instance })
	local def = WeaponDefs.Weapons[weaponId]
	if not def then
		return
	end
	if def.sounds.fire then
		SoundPlayer.playAt(origin, def.sounds.fire, 40)
	end

	local model = AssetLoader.get("Props", "Arrow", Placeholders.arrow) :: Model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	model.Parent = Effects.folder

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = table.clone(ignore)
	table.insert(filter, Effects.folder)
	params.FilterDescendantsInstances = filter

	local position, currentVelocity, age = origin, velocity, 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		local newPosition, newVelocity = Ballistics.step(position, currentVelocity, def.gravity, dt)
		local result = workspace:Raycast(position, newPosition - position, params)
		age += dt
		if result or age > 4 then
			connection:Disconnect()
			if result then
				model:PivotTo(CFrame.lookAt(result.Position - currentVelocity.Unit * 0.8, result.Position + currentVelocity.Unit))
			end
			-- Le serveur crée la flèche ramassable : on retire la nôtre
			Debris:AddItem(model, 0.15)
			return
		end
		model:PivotTo(CFrame.lookAt(newPosition, newPosition + newVelocity))
		position, currentVelocity = newPosition, newVelocity
	end)
end

-- Chiffre de dégâts qui monte et disparaît au-dessus de la cible
function Effects.damageNumber(position: Vector3, damage: number, headshot: boolean, killed: boolean)
	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldPosition = position

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 30)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	billboard.Parent = attachment

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = tostring(math.floor(damage + 0.5))
	label.TextColor3 = if killed
		then Color3.fromRGB(255, 60, 60)
		elseif headshot then Color3.fromRGB(255, 210, 60)
		else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = billboard

	local offset = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	TweenService:Create(billboard, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(offset.X, 3, offset.Z),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(attachment, 0.75)
end

function Effects.start()
	Effects.folder.Parent = workspace

	-- Attaques des autres joueurs
	Remotes.WeaponFx.OnClientEvent:Connect(function(kind, weaponId, a, b)
		if kind == "shot" then
			Effects.shot(weaponId, a, b)
		elseif kind == "swing" then
			Effects.swing(weaponId, a)
		elseif kind == "arrow" then
			Effects.arrow(weaponId, a, b, {})
		end
	end)
end

return Effects
