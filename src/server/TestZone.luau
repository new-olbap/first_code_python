-- Zone de test, à côté du point de départ : toutes les armes en libre-service,
-- des mannequins à 10, 25, 50 et 80 studs, et des boutons pour faire venir des Rôdeurs.
-- Les mannequins encaissent tout et se soignent après 2 s sans être touchés :
-- pratique pour voir les dégâts, la dispersion et le recul de chaque arme.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)
local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local Combat = require(script.Parent.Combat)
local Rigs = require(script.Parent.Rigs)

local TestZone = {}

local DUMMY_HEALTH = 1000

local function addSign(parent: Instance, position: Vector3, text: string, color: Color3)
	local post = Placeholders.part(parent, "Sign", Vector3.new(0.4, 6, 0.4), CFrame.new(position + Vector3.new(0, 3, 0)), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0
	billboard.Parent = post
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function spawnDummy(parent: Instance, position: Vector3, label: string)
	local dummy = AssetLoader.get("Characters", "Dummy", function()
		return Rigs.build("Dummy", Color3.fromRGB(230, 200, 150), Color3.fromRGB(200, 170, 120))
	end) :: Model
	local humanoid = dummy:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = dummy:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoid.MaxHealth = DUMMY_HEALTH
	humanoid.Health = DUMMY_HEALTH
	humanoid.DisplayName = label
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.BreakJointsOnDeath = false
	-- Face aux joueurs (qui arrivent du côté +Z)
	dummy:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.pi, 0))
	root.Anchored = true
	dummy.Parent = parent

	local lastHit = 0
	humanoid.HealthChanged:Connect(function(health)
		if health < humanoid.MaxHealth then
			lastHit = os.clock()
		end
	end)
	humanoid.Died:Connect(function()
		task.delay(2, function()
			dummy:Destroy()
			spawnDummy(parent, position, label)
		end)
	end)
	task.spawn(function()
		while dummy.Parent do
			task.wait(0.5)
			if humanoid.Health > 0 and os.clock() - lastHit > 2 then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end)
end

local function addButton(parent: Instance, position: Vector3, text: string, color: Color3, onPress: (Player) -> ())
	local button = Placeholders.part(parent, "Button", Vector3.new(3, 3, 1), CFrame.new(position + Vector3.new(0, 1.5, 0)), color, Enum.Material.Neon)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = "Zone de test"
	prompt.HoldDuration = 0.2
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	prompt.Triggered:Connect(onPress)
end

function TestZone.build(LootService, MonsterService)
	if not GameConfig.Debug.testZoneEnabled then
		return
	end
	local zone = ZoneDefs.TestZone
	local center, size = zone.center, zone.size
	local folder = Instance.new("Folder")
	folder.Name = "TestZone"

	-- Sol et barrière basse (ouverte côté départ)
	Placeholders.part(folder, "Floor", Vector3.new(size.X, 0.2, size.Z), CFrame.new(center + Vector3.new(0, 0.1, 0)), Color3.fromRGB(95, 95, 100), Enum.Material.Concrete)
	local fence = Color3.fromRGB(200, 170, 40)
	local halfX, halfZ = size.X / 2, size.Z / 2
	Placeholders.part(folder, "Fence", Vector3.new(1, 3, size.Z), CFrame.new(center + Vector3.new(-halfX, 1.5, 0)), fence)
	Placeholders.part(folder, "Fence", Vector3.new(1, 3, size.Z), CFrame.new(center + Vector3.new(halfX, 1.5, 0)), fence)
	Placeholders.part(folder, "Fence", Vector3.new(size.X, 3, 1), CFrame.new(center + Vector3.new(0, 1.5, -halfZ)), fence)

	-- Ligne de tir, du côté +Z
	local firingLineZ = center.Z + halfZ - 12
	addSign(folder, Vector3.new(center.X - halfX + 4, 0, center.Z + halfZ - 2), "ZONE DE TEST", fence)
	Placeholders.part(folder, "FiringLine", Vector3.new(size.X - 2, 0.25, 0.6), CFrame.new(center.X, 0.2, firingLineZ), Color3.fromRGB(240, 240, 240), Enum.Material.Neon)

	-- Râtelier : une arme de chaque type, qui revient 3 s après avoir été prise
	-- (côté gauche de l'enclos ; les boutons sont à droite)
	local rackStart, rackEnd = center.X - halfX + 5, center.X + 10
	local count = #WeaponDefs.Order
	for index, weaponId in ipairs(WeaponDefs.Order) do
		local x = rackStart + (index - 1) * ((rackEnd - rackStart) / math.max(1, count - 1))
		LootService.spawnRack(Vector3.new(x, 0.2, firingLineZ + 5), weaponId)
	end

	-- Mannequins
	local dummies = Instance.new("Folder")
	dummies.Name = "Dummies"
	dummies.Parent = folder
	Combat.registerTargetFolder(dummies)
	for index, distance in ipairs({ 10, 25, 50, 80 }) do
		local x = center.X - 15 + (index - 1) * 10
		spawnDummy(dummies, Vector3.new(x, 0.2, firingLineZ - distance), "Mannequin " .. distance .. " studs")
	end

	-- Boutons : faire venir des Rôdeurs au fond de l'enclos, ou tous les supprimer
	local buttonZ = firingLineZ + 5
	addButton(folder, Vector3.new(center.X + halfX - 5, 0, buttonZ), "3 Rôdeurs", Color3.fromRGB(200, 60, 60), function(player)
		local spawned = MonsterService.spawnGroupAt(Vector3.new(center.X, 0, center.Z - halfZ + 8), 3)
		Remotes.Notify:FireClient(player, spawned .. " Rôdeurs arrivent !", Color3.fromRGB(255, 120, 120))
	end)
	addButton(folder, Vector3.new(center.X + halfX - 13, 0, buttonZ), "Supprimer les monstres", Color3.fromRGB(60, 160, 220), function(player)
		Remotes.Notify:FireClient(player, MonsterService.killAll() .. " monstres supprimés", Color3.new(1, 1, 1))
	end)

	folder.Parent = workspace
end

return TestZone
