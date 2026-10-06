-- Cycle de vie des joueurs : apparition, mort (le sac tombe au sol) et réapparition.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerService = {}

local WeaponService
local InventoryService
local ContainerService

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true

-- À la mort, tout ce que le joueur porte (armes et inventaire) tombe dans un sac
-- que tout le monde peut fouiller
local function dropEverything(player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local entries = {}
	for _, tool in ipairs(WeaponService.getTools(player)) do
		local item = WeaponService.toolToItem(tool)
		if item then
			table.insert(entries, { kind = "weapon", item = item })
		end
		tool:Destroy()
	end
	for _, slot in ipairs(InventoryService.takeEverything(player)) do
		table.insert(entries, { kind = "item", id = slot.id, count = slot.count })
	end

	groundParams.FilterDescendantsInstances = { character }
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), groundParams)
	local position = if ground then ground.Position else root.Position - Vector3.new(0, 3, 0)
	ContainerService.dropBag(position, entries, player.DisplayName)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		dropEverything(player, character)
	end)
end

function PlayerService.start(deps)
	WeaponService = deps.WeaponService
	InventoryService = deps.InventoryService
	ContainerService = deps.ContainerService
	local debugService = deps.DebugService
	Players.RespawnTime = GameConfig.RespawnTime

	local function onPlayerAdded(player: Player)
		player:SetAttribute("DebugAllowed", debugService.isAllowed(player))
		InventoryService.sync(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return PlayerService
