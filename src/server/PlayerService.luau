-- Cycle de vie des joueurs : apparition, mort (le sac tombe au sol) et réapparition.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerService = {}

local WeaponService
local LootService

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true

-- À la mort, toutes les armes portées tombent dans un sac que tout le monde peut fouiller
local function dropEverything(player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local items = {}
	for _, tool in ipairs(WeaponService.getTools(player)) do
		local item = WeaponService.toolToItem(tool)
		if item then
			table.insert(items, item)
		end
		tool:Destroy()
	end

	groundParams.FilterDescendantsInstances = { character }
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), groundParams)
	local position = if ground then ground.Position else root.Position - Vector3.new(0, 3, 0)
	LootService.dropBag(position, items, player.DisplayName)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		dropEverything(player, character)
	end)
end

function PlayerService.start(weaponService, lootService, debugService)
	WeaponService = weaponService
	LootService = lootService
	Players.RespawnTime = GameConfig.RespawnTime

	local function onPlayerAdded(player: Player)
		player:SetAttribute("DebugAllowed", debugService.isAllowed(player))
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
