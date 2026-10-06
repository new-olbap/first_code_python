-- Inventaire des joueurs (tout ce qui n'est pas une arme : ressources, munitions,
-- nourriture, soins). Le serveur a la seule vraie copie ; le client reçoit une
-- copie à chaque changement pour l'afficher.
--
-- L'inventaire est une liste de cases { id, count }, au plus GameConfig.Inventory.slots.
-- Les armes, elles, sont des Tools dans la barre d'outils (voir WeaponService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefs = require(ReplicatedStorage.Shared.ItemDefs)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InventoryService = {}

export type Slot = { id: string, count: number }

local inventories: { [Player]: { Slot } } = {}
local deps: any = {}

local function getSlots(player: Player): { Slot }
	local slots = inventories[player]
	if not slots then
		slots = {}
		inventories[player] = slots
	end
	return slots
end

function InventoryService.sync(player: Player)
	Remotes.InventoryUpdate:FireClient(player, getSlots(player), GameConfig.Inventory.slots)
end

function InventoryService.count(player: Player, id: string): number
	local total = 0
	for _, slot in ipairs(getSlots(player)) do
		if slot.id == id then
			total += slot.count
		end
	end
	return total
end

-- Ajoute des objets. Renvoie la quantité vraiment ajoutée (moins si l'inventaire est plein).
function InventoryService.add(player: Player, id: string, count: number): number
	local def = ItemDefs.Items[id]
	if not def or count <= 0 then
		return 0
	end
	local slots = getSlots(player)
	local remaining = count
	-- D'abord compléter les piles existantes
	for _, slot in ipairs(slots) do
		if remaining <= 0 then
			break
		end
		if slot.id == id and slot.count < def.maxStack then
			local added = math.min(def.maxStack - slot.count, remaining)
			slot.count += added
			remaining -= added
		end
	end
	-- Puis de nouvelles cases
	while remaining > 0 and #slots < GameConfig.Inventory.slots do
		local added = math.min(def.maxStack, remaining)
		table.insert(slots, { id = id, count = added })
		remaining -= added
	end
	if remaining ~= count then
		InventoryService.sync(player)
	end
	return count - remaining
end

-- Retire des objets seulement si le joueur en a assez. Renvoie true si c'est fait.
function InventoryService.remove(player: Player, id: string, count: number): boolean
	if count <= 0 or InventoryService.count(player, id) < count then
		return false
	end
	local slots = getSlots(player)
	local remaining = count
	for index = #slots, 1, -1 do
		local slot = slots[index]
		if slot.id == id then
			local taken = math.min(slot.count, remaining)
			slot.count -= taken
			remaining -= taken
			if slot.count <= 0 then
				table.remove(slots, index)
			end
			if remaining <= 0 then
				break
			end
		end
	end
	InventoryService.sync(player)
	return true
end

-- Vérifie et retire un coût du type { Scrap = 2, Wood = 1 }
function InventoryService.hasAll(player: Player, cost: { [string]: number }): boolean
	for id, amount in pairs(cost) do
		if InventoryService.count(player, id) < amount then
			return false
		end
	end
	return true
end

function InventoryService.removeAll(player: Player, cost: { [string]: number }): boolean
	if not InventoryService.hasAll(player, cost) then
		return false
	end
	for id, amount in pairs(cost) do
		InventoryService.remove(player, id, amount)
	end
	return true
end

-- Vide l'inventaire (à la mort) et renvoie son contenu
function InventoryService.takeEverything(player: Player): { Slot }
	local slots = getSlots(player)
	inventories[player] = {}
	InventoryService.sync(player)
	return slots
end

local function onAction(player: Player, action: any, a: any, b: any)
	if action == "sync" then
		InventoryService.sync(player) -- le client vient de démarrer
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or typeof(action) ~= "string" then
		return
	end
	local slots = getSlots(player)

	if action == "use" and typeof(a) == "number" then
		local slot = slots[a]
		if slot then
			deps.SurvivalService.useItem(player, slot.id)
		end
	elseif action == "drop" and typeof(a) == "number" then
		local slot = slots[a]
		if not slot then
			return
		end
		local amount = math.clamp(math.floor(tonumber(b) or slot.count), 1, slot.count)
		local id = slot.id
		if InventoryService.remove(player, id, amount) then
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
			deps.ContainerService.dropPouch(root.Position + root.CFrame.LookVector * 2, {
				{ kind = "item", id = id, count = amount },
			}, player.DisplayName)
		end
	elseif action == "repair" and typeof(a) == "string" then
		local message, color = deps.WeaponService.repair(player, a)
		Remotes.Notify:FireClient(player, message, color)
	elseif action == "quickHeal" then
		deps.SurvivalService.quickHeal(player)
	elseif action == "dropWeapon" and typeof(a) == "string" then
		deps.WeaponService.dropWeapon(player, a)
	end
end

function InventoryService.start(dependencies)
	deps = dependencies
	Remotes.InventoryAction.OnServerEvent:Connect(onAction)
	Players.PlayerAdded:Connect(function(player)
		getSlots(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
	end)
end

return InventoryService
