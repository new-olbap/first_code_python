-- Tout ce qui se ramasse : armes au sol, sacs des joueurs morts, flèches plantées.
-- Le serveur décide de tout ; le joueur maintient E (ProximityPrompt) pour ramasser.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)

local LootService = {}

local WeaponService
local rng = Random.new()
local folder: Folder
local arrowPickups: { Model } = {}
local MAX_ARROW_PICKUPS = 60

local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 120, 120)

-- Tire une arme au hasard selon les poids de la table de butin
local function rollWeapon(lootTable: { [string]: number }): string
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
	return (next(lootTable))
end

-- Rend un modèle décoratif : ancré, sans collision, ignoré par les tirs
local function makeStatic(model: Instance)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
end

local function addLabel(part: BasePart, text: string, color: Color3, maxDistance: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(180, 26)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	billboard.MaxDistance = maxDistance
	billboard.LightInfluence = 0
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
end

local function addPrompt(part: BasePart, action: string, object: string, holdDuration: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

-- ARMES AU SOL ------------------------------------------------------------------

-- Crée une arme au sol. onTaken est appelé après ramassage (pour remettre du butin).
function LootService.spawnWeapon(position: Vector3, item, onTaken: (() -> ())?)
	local def = WeaponDefs.Weapons[item.weaponId]
	local rarity = WeaponDefs.Rarities[def.rarity]

	-- On réutilise le modèle de l'arme (vrai modèle ou placeholder), posé à plat
	local tool = WeaponService.createTool(item)
	local model = Instance.new("Model")
	model.Name = "Loot_" .. item.weaponId
	for _, child in ipairs(tool:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			child.Parent = model
		end
	end
	tool:Destroy()
	local handle = model:FindFirstChild("Handle") :: BasePart?
	if not handle then
		model:Destroy()
		return
	end
	model.PrimaryPart = handle
	makeStatic(model)

	local size = handle.Size
	local flat = if size.Y > size.X then CFrame.Angles(0, 0, math.rad(90)) else CFrame.identity
	local thickness = math.min(size.X, size.Y)
	model:PivotTo(CFrame.new(position + Vector3.new(0, thickness / 2 + 0.05, 0)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0) * flat)

	-- Lumière de la couleur de la rareté : on repère le butin de loin, surtout la nuit
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = 7
	light.Brightness = 1.5
	light.Parent = handle

	local percent = math.floor(item.durability / def.maxDurability * 100)
	addLabel(handle, def.name, rarity.color, 45)
	local prompt = addPrompt(handle, "Ramasser", def.name .. " · " .. rarity.name .. " · état " .. percent .. "%", 0.35)

	local taken = false
	prompt.Triggered:Connect(function(player)
		if taken then
			return
		end
		local picked, message = WeaponService.giveItem(player, item)
		if message then
			Remotes.Notify:FireClient(player, message, if picked then rarity.color else RED)
		end
		if picked then
			taken = true
			SoundPlayer.playAt(handle.Position, "Pickup", 30)
			model:Destroy()
			if onTaken then
				onTaken()
			end
		end
	end)

	model.Parent = folder
end

-- Emplacement de butin d'une zone : une arme tirée au sort, renouvelée après ramassage
function LootService.spawnZoneLoot(position: Vector3, zone)
	local range = GameConfig.LootDurability
	local item = WeaponService.newItem(rollWeapon(zone.loot), rng:NextNumber(range.min, range.max))
	LootService.spawnWeapon(position, item, function()
		task.delay(GameConfig.LootRespawnTime, LootService.spawnZoneLoot, position, zone)
	end)
end

-- Râtelier de la zone de test : toujours la même arme, neuve, qui revient vite
function LootService.spawnRack(position: Vector3, weaponId: string)
	LootService.spawnWeapon(position, WeaponService.newItem(weaponId, 1), function()
		task.delay(3, LootService.spawnRack, position, weaponId)
	end)
end

-- SAC DU JOUEUR MORT -------------------------------------------------------------

function LootService.dropBag(position: Vector3, items: { any }, ownerName: string)
	if #items == 0 then
		return
	end
	local model = AssetLoader.get("Props", "Bag", Placeholders.bag) :: Model
	model.Name = "Bag"
	makeStatic(model)
	model:PivotTo(CFrame.new(position)) -- position = point au sol

	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	addLabel(part, "Sac de " .. ownerName, Color3.fromRGB(255, 210, 120), 60)
	local prompt = addPrompt(part, "Fouiller", "Sac de " .. ownerName .. " (" .. #items .. " objets)", 0.8)

	prompt.Triggered:Connect(function(player)
		local taken = {}
		for index = #items, 1, -1 do
			local picked = WeaponService.giveItem(player, items[index])
			if picked then
				table.insert(taken, WeaponDefs.Weapons[items[index].weaponId].name)
				table.remove(items, index)
			end
		end
		if #taken > 0 then
			Remotes.Notify:FireClient(player, "Récupéré : " .. table.concat(taken, ", "), WHITE)
			SoundPlayer.playAt(part.Position, "Pickup", 30)
		else
			Remotes.Notify:FireClient(player, "Rien que tu puisses prendre", RED)
		end
		if #items == 0 then
			model:Destroy()
		else
			prompt.ObjectText = "Sac de " .. ownerName .. " (" .. #items .. " objets)"
		end
	end)

	model.Parent = folder
	Debris:AddItem(model, GameConfig.BagLifetime)
end

-- FLÈCHES PLANTÉES ----------------------------------------------------------------

function LootService.dropArrow(cframe: CFrame)
	local model = AssetLoader.get("Props", "Arrow", Placeholders.arrow) :: Model
	makeStatic(model)
	model:PivotTo(cframe)
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	local prompt = addPrompt(part, "Ramasser", "Flèche", 0)
	prompt.MaxActivationDistance = 7

	prompt.Triggered:Connect(function(player)
		if WeaponService.addReserve(player, "Bow", 1) then
			Remotes.Notify:FireClient(player, "+1 flèche", WHITE)
			model:Destroy()
		else
			Remotes.Notify:FireClient(player, "Il te faut un arc", RED)
		end
	end)

	model.Parent = folder
	Debris:AddItem(model, GameConfig.ArrowPickupLifetime)

	-- On limite le nombre de flèches au sol pour garder le serveur léger
	table.insert(arrowPickups, model)
	if #arrowPickups > MAX_ARROW_PICKUPS then
		table.remove(arrowPickups, 1):Destroy()
	end
end

function LootService.start(lootSpots: { [string]: { Vector3 } }, zones, weaponService)
	WeaponService = weaponService
	folder = Instance.new("Folder")
	folder.Name = "Loot"
	folder.Parent = workspace

	for _, zone in ipairs(zones) do
		for _, spot in ipairs(lootSpots[zone.id] or {}) do
			LootService.spawnZoneLoot(spot, zone)
		end
	end
end

return LootService
