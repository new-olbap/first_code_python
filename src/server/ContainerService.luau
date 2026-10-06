-- Tout ce qui se fouille : conteneurs du décor (armoires, caisses, coffres de voiture...),
-- sacs des joueurs morts, et petits sacs d'objets jetés.
--
-- Fouiller (maintenir E) ouvre une fenêtre avec le contenu. Le serveur garde le
-- contenu, vérifie la distance à chaque action et met à jour tous les joueurs
-- qui regardent le même conteneur. Un conteneur du décor vidé se remplit à
-- nouveau après un délai (respawnTime).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local ContainerDefs = require(ReplicatedStorage.Shared.ContainerDefs)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefs = require(ReplicatedStorage.Shared.ItemDefs)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)

local ContainerService = {}

-- Une entrée de contenu : un objet (avec quantité) ou une arme (avec son état)
export type Entry = { kind: string, id: string?, count: number?, item: any? }

type Lootable = {
	id: number,
	title: string,
	entries: { Entry },
	anchor: BasePart | Attachment,
	prompt: ProximityPrompt,
	containerType: string?, -- nil pour un sac
	empty: boolean,
	viewers: { [Player]: boolean },
	onEmptied: () -> (),
}

local WeaponService
local InventoryService
local rng = Random.new()
local folder: Folder
local lootables: { [number]: Lootable } = {}
local nextId = 0

local RED = Color3.fromRGB(255, 120, 120)

local function anchorPosition(lootable: Lootable): Vector3
	local anchor = lootable.anchor
	if anchor:IsA("Attachment") then
		return anchor.WorldPosition
	end
	return (anchor :: BasePart).Position
end

local function serialize(entries: { Entry })
	local list = {}
	for _, entry in ipairs(entries) do
		if entry.kind == "weapon" then
			local def = WeaponDefs.Weapons[entry.item.weaponId]
			table.insert(list, {
				kind = "weapon",
				id = entry.item.weaponId,
				durability = entry.item.durability / def.maxDurability,
			})
		else
			table.insert(list, { kind = "item", id = entry.id, count = entry.count })
		end
	end
	return list
end

local function refresh(lootable: Lootable)
	local data = serialize(lootable.entries)
	for viewer in pairs(lootable.viewers) do
		if viewer.Parent then
			Remotes.ContainerOpen:FireClient(viewer, lootable.id, lootable.title, data)
		else
			lootable.viewers[viewer] = nil
		end
	end
end

local function close(lootable: Lootable, player: Player)
	if lootable.viewers[player] then
		lootable.viewers[player] = nil
		Remotes.ContainerOpen:FireClient(player, nil)
	end
end

local function closeForEveryone(lootable: Lootable)
	for viewer in pairs(lootable.viewers) do
		close(lootable, viewer)
	end
end

-- Tire le contenu d'un conteneur selon sa table de butin
local function rollLoot(containerType: string): { Entry }
	local def = ContainerDefs.Containers[containerType]
	local total = 0
	for _, entry in ipairs(def.loot) do
		total += entry.weight
	end
	local items: { [string]: number } = {}
	local entries: { Entry } = {}
	for _ = 1, rng:NextInteger(def.rolls.min, def.rolls.max) do
		local roll = rng:NextNumber(0, total)
		for _, entry in ipairs(def.loot) do
			roll -= entry.weight
			if roll <= 0 then
				if entry.weapon then
					local range = GameConfig.LootDurability
					table.insert(entries, { kind = "weapon", item = WeaponService.newItem(entry.weapon, rng:NextNumber(range.min, range.max)) })
				else
					items[entry.item] = (items[entry.item] or 0) + rng:NextInteger(entry.min, entry.max)
				end
				break
			end
		end
	end
	for id, count in pairs(items) do
		table.insert(entries, { kind = "item", id = id, count = count })
	end
	return entries
end

local function updatePrompt(lootable: Lootable)
	local prompt = lootable.prompt
	if lootable.containerType then
		prompt.ObjectText = lootable.title .. (if lootable.empty then " (vide)" else "")
	else
		prompt.ObjectText = lootable.title .. " (" .. #lootable.entries .. ")"
	end
end

local function register(anchor: BasePart | Attachment, title: string, entries: { Entry }, containerType: string?, holdDuration: number, onEmptied: () -> ()): Lootable
	nextId += 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Fouiller"
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local lootable: Lootable = {
		id = nextId,
		title = title,
		entries = entries,
		anchor = anchor,
		prompt = prompt,
		containerType = containerType,
		empty = #entries == 0,
		viewers = {},
		onEmptied = onEmptied,
	}
	lootables[nextId] = lootable
	updatePrompt(lootable)

	prompt.Triggered:Connect(function(player)
		if lootable.empty then
			Remotes.Notify:FireClient(player, title .. " : déjà fouillé", RED)
			return
		end
		lootable.viewers[player] = true
		SoundPlayer.playAt(anchorPosition(lootable), "Pickup", 25)
		refresh(lootable)
	end)
	return lootable
end

local function checkEmpty(lootable: Lootable)
	if #lootable.entries > 0 then
		updatePrompt(lootable)
		return
	end
	lootable.empty = true
	closeForEveryone(lootable)
	updatePrompt(lootable)
	lootable.onEmptied()
end

-- Donne une entrée au joueur. Renvoie true si elle a été prise entièrement.
local function giveEntry(player: Player, entry: Entry): (boolean, string?)
	if entry.kind == "weapon" then
		local taken, message = WeaponService.giveItem(player, entry.item)
		return taken, message
	end
	local added = InventoryService.add(player, entry.id :: string, entry.count :: number)
	local name = ItemDefs.Items[entry.id].name
	if added <= 0 then
		return false, "Inventaire plein"
	end
	entry.count = (entry.count :: number) - added
	if (entry.count :: number) > 0 then
		return false, "+" .. added .. " " .. name .. " (inventaire plein)"
	end
	return true, "+" .. added .. " " .. name
end

local function onAction(player: Player, id: any, action: any, index: any)
	local lootable = typeof(id) == "number" and lootables[id]
	if not lootable then
		return
	end
	if action == "close" then
		close(lootable, player)
		return
	end

	-- Le joueur doit être vivant et assez près
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	if (root.Position - anchorPosition(lootable)).Magnitude > GameConfig.Inventory.interactDistance then
		close(lootable, player)
		return
	end

	local messages = {}
	if action == "take" and typeof(index) == "number" then
		local entry = lootable.entries[index]
		if entry then
			local taken, message = giveEntry(player, entry)
			if taken then
				table.remove(lootable.entries, index)
			end
			table.insert(messages, message)
		end
	elseif action == "takeAll" then
		for i = #lootable.entries, 1, -1 do
			local taken, message = giveEntry(player, lootable.entries[i])
			if taken then
				table.remove(lootable.entries, i)
			end
			table.insert(messages, message)
		end
	end

	if #messages > 0 then
		Remotes.Notify:FireClient(player, table.concat(messages, " · "), Color3.new(1, 1, 1))
	end
	refresh(lootable)
	checkEmpty(lootable)
end

-- API ---------------------------------------------------------------------------------

-- Conteneur du décor posé à un endroit (armoire, caisse...)
function ContainerService.spawnContainer(containerType: string, cframe: CFrame)
	local def = ContainerDefs.Containers[containerType]
	if not def then
		warn("[Conteneurs] Type inconnu : " .. tostring(containerType))
		return
	end
	local model = AssetLoader.get("Containers", containerType, function()
		return Placeholders.container(containerType, rng)
	end) :: Model
	model:PivotTo(cframe)
	model.Parent = folder
	local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	ContainerService.makeSearchable(anchor, containerType)
end

-- Rend fouillable un objet existant (coffre de voiture, ou conteneur ci-dessus)
function ContainerService.makeSearchable(anchor: BasePart | Attachment, containerType: string)
	local def = ContainerDefs.Containers[containerType]
	if not def then
		return
	end
	local lootable
	lootable = register(anchor, def.name, rollLoot(containerType), containerType, def.searchTime, function()
		task.delay(def.respawnTime, function()
			lootable.entries = rollLoot(containerType)
			lootable.empty = #lootable.entries == 0
			updatePrompt(lootable)
		end)
	end)
end

local function spawnBagModel(name: string, builder: () -> Instance, position: Vector3, lifetime: number): BasePart
	local model = AssetLoader.get("Props", name, builder) :: Model
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
	model.Parent = folder
	Debris:AddItem(model, lifetime)
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) :: BasePart
end

-- Sac lâché à la mort : tout ce que le joueur portait
function ContainerService.dropBag(position: Vector3, entries: { Entry }, ownerName: string)
	if #entries == 0 then
		return
	end
	local anchor = spawnBagModel("Bag", Placeholders.bag, position, GameConfig.BagLifetime)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(180, 26)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	billboard.MaxDistance = 60
	billboard.LightInfluence = 0
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextColor3 = Color3.fromRGB(255, 210, 120)
	label.Text = "Sac de " .. ownerName
	label.Parent = billboard

	local lootable
	lootable = register(anchor, "Sac de " .. ownerName, entries, nil, 0.8, function()
		lootables[lootable.id] = nil
		if anchor.Parent then
			anchor.Parent:Destroy()
		end
	end)
	task.delay(GameConfig.BagLifetime, function()
		closeForEveryone(lootable)
		lootables[lootable.id] = nil
	end)
end

-- Petit sac pour des objets jetés
function ContainerService.dropPouch(position: Vector3, entries: { Entry }, ownerName: string)
	local ground = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -20, 0))
	local anchor = spawnBagModel("Pouch", Placeholders.pouch, if ground then ground.Position else position, GameConfig.BagLifetime)
	local lootable
	lootable = register(anchor, "Objets de " .. ownerName, entries, nil, 0.3, function()
		lootables[lootable.id] = nil
		if anchor.Parent then
			anchor.Parent:Destroy()
		end
	end)
	task.delay(GameConfig.BagLifetime, function()
		lootables[lootable.id] = nil
	end)
end

function ContainerService.start(weaponService, inventoryService)
	WeaponService = weaponService
	InventoryService = inventoryService
	folder = Instance.new("Folder")
	folder.Name = "Containers"
	folder.Parent = workspace
	Remotes.ContainerAction.OnServerEvent:Connect(onAction)

	-- Ferme la fenêtre d'un joueur qui s'éloigne
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, lootable in pairs(lootables) do
				for viewer in pairs(lootable.viewers) do
					local root = viewer.Character and viewer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if not root or (root.Position - anchorPosition(lootable)).Magnitude > GameConfig.Inventory.interactDistance then
						close(lootable, viewer)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, lootable in pairs(lootables) do
			lootable.viewers[player] = nil
		end
	end)
end

return ContainerService
