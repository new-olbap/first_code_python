-- Fait apparaître des armes au sol. Chaque zone a sa propre table de butin.
-- Une arme ramassée réapparaît au même endroit (avec un nouveau tirage) après un délai.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LootService = {}

local WeaponService
local rng = Random.new()
local folder

-- Tire une arme au hasard selon les poids de la table de butin
local function rollWeapon(lootTable)
	local total = 0
	for _, weight in pairs(lootTable) do
		total += weight
	end
	local roll = rng:NextNumber(0, total)
	for weaponId, weight in pairs(lootTable) do
		roll -= weight
		if roll <= 0 then
			return weaponId
		end
	end
	return next(lootTable)
end

local function spawnPickup(spot, zone)
	local weaponId = rollWeapon(zone.loot)
	local cfg = Config.Weapons[weaponId]
	local rarity = Config.Rarities[cfg.rarity]

	-- L'arme est posée à plat sur le sol
	local part = Instance.new("Part")
	part.Name = "Butin_" .. weaponId
	part.Anchored = true
	part.CanCollide = false
	part.Size = cfg.size
	part.Color = cfg.color
	part.Material = Enum.Material.Metal
	local lift = math.max(cfg.size.X, cfg.size.Z) / 2 + 0.05
	part.CFrame = CFrame.new(spot + Vector3.new(0, lift, 0))
		* CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0)
		* CFrame.Angles(math.rad(90), 0, 0)

	-- Une lumière de la couleur de la rareté, visible de loin la nuit
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = 6
	light.Brightness = 1.5
	light.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = 40
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = cfg.name
	label.TextColor3 = rarity.color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ramasser"
	prompt.ObjectText = cfg.name .. " (" .. rarity.name .. ")"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local taken = false
	prompt.Triggered:Connect(function(player)
		if taken then
			return
		end
		local picked, message = WeaponService.give(player, weaponId)
		if message then
			Remotes.Notify:FireClient(player, message, picked and rarity.color or Color3.fromRGB(255, 120, 120))
		end
		if picked then
			taken = true
			part:Destroy()
			task.delay(Config.LootRespawnTime, spawnPickup, spot, zone)
		end
	end)

	part.Parent = folder
end

function LootService.start(lootSpots, weaponService)
	WeaponService = weaponService

	folder = Instance.new("Folder")
	folder.Name = "Butin"
	folder.Parent = workspace

	for _, zone in ipairs(Config.Zones) do
		for _, spot in ipairs(lootSpots[zone.id] or {}) do
			spawnPickup(spot, zone)
		end
	end
end

return LootService
