-- Copie locale de l'inventaire, envoyée par le serveur à chaque changement.
-- Elle sert seulement à l'affichage (HUD, fenêtre d'inventaire) : le serveur
-- garde la vraie version et vérifie toutes les actions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InventoryClient = {}

InventoryClient.slots = {} :: { { id: string, count: number } }
InventoryClient.capacity = 24

local changedEvent = Instance.new("BindableEvent")
InventoryClient.Changed = changedEvent.Event

function InventoryClient.count(id: string): number
	local total = 0
	for _, slot in ipairs(InventoryClient.slots) do
		if slot.id == id then
			total += slot.count
		end
	end
	return total
end

function InventoryClient.start()
	Remotes.InventoryUpdate.OnClientEvent:Connect(function(slots, capacity)
		InventoryClient.slots = slots
		InventoryClient.capacity = capacity
		changedEvent:Fire()
	end)
	Remotes.InventoryAction:FireServer("sync")
end

return InventoryClient
