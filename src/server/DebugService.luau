-- Commandes du panneau de debug (touche F2 côté client).
-- Le serveur vérifie toujours que le joueur a le droit de s'en servir :
-- dans Studio, le propriétaire du jeu, ou un UserId listé dans GameConfig.Debug.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)

local DebugService = {}

local WeaponService
local MonsterService
local DayNight
local InventoryService
local SurvivalService

function DebugService.isAllowed(player: Player): boolean
	local cfg = GameConfig.Debug
	if cfg.allowInStudio and RunService:IsStudio() then
		return true
	end
	if cfg.allowCreator and game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(cfg.adminUserIds, player.UserId) ~= nil
end

local TELEPORTS = {
	spawn = ZoneDefs.SpawnPosition,
	town = Vector3.new(0, 0, -200),
	test = ZoneDefs.TestZone.center + Vector3.new(0, 0, ZoneDefs.TestZone.size.Z / 2 - 6),
}

local actions: { [string]: (Player, Model, any) -> string? } = {
	give = function(player, _, weaponId)
		if typeof(weaponId) ~= "string" or not WeaponDefs.Weapons[weaponId] then
			return nil
		end
		local _, message = WeaponService.giveItem(player, WeaponService.newItem(weaponId, 1))
		return message
	end,

	prowlers = function(_, character, count)
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local amount = math.clamp(tonumber(count) or 3, 1, 10)
		local position = root.Position + root.CFrame.LookVector * 30
		return MonsterService.spawnGroupAt(position, amount) .. " Rôdeurs devant toi"
	end,

	killMonsters = function()
		return MonsterService.killAll() .. " monstres supprimés"
	end,

	heal = function(_, character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		humanoid.Health = humanoid.MaxHealth
		return "Soigné"
	end,

	refill = function(player)
		for _, tool in ipairs(WeaponService.getTools(player)) do
			local def = WeaponDefs.Weapons[tool:GetAttribute("WeaponId")]
			tool:SetAttribute("Durability", def.maxDurability)
			if def.ammoItem then
				tool:SetAttribute("Ammo", def.magazine)
				InventoryService.add(player, def.ammoItem, def.magazine * 3)
			end
		end
		return "Armes réparées, chargées, + 3 chargeurs chacune"
	end,

	kit = function(player)
		local kit = {
			Wood = 30,
			Scrap = 20,
			Cloth = 10,
			Bandage = 5,
			Medkit = 1,
			CannedFood = 2,
			WaterBottle = 2,
			AmmoPistol = 36,
			AmmoShotgun = 12,
			AmmoRifle = 60,
			Arrow = 15,
		}
		for id, count in pairs(kit) do
			InventoryService.add(player, id, count)
		end
		return "Kit de survie ajouté à l'inventaire"
	end,

	starve = function(player)
		SurvivalService.setGauges(player, 8, 8)
		return "Faim et soif presque vides"
	end,

	feed = function(player)
		SurvivalService.setGauges(player, 100, 100)
		return "Faim et soif à 100"
	end,

	wear = function(player)
		-- Abîme les armes à 20 % pour tester l'effet de l'usure
		for _, tool in ipairs(WeaponService.getTools(player)) do
			local def = WeaponDefs.Weapons[tool:GetAttribute("WeaponId")]
			tool:SetAttribute("Durability", math.max(1, math.floor(def.maxDurability * 0.2)))
		end
		return "Armes usées à 20 %"
	end,

	day = function()
		DayNight.skipTo(false)
		return "Il fait jour"
	end,

	night = function()
		DayNight.skipTo(true)
		return "Il fait nuit"
	end,

	god = function(_, character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		local enabled = not humanoid:GetAttribute("GodMode")
		humanoid:SetAttribute("GodMode", enabled)
		return if enabled then "Mode dieu activé" else "Mode dieu désactivé"
	end,

	teleport = function(_, character, place)
		local target = TELEPORTS[place]
		if not target then
			return nil
		end
		character:PivotTo(CFrame.new(target + Vector3.new(0, 4, 0)))
		return "Téléporté"
	end,
}

function DebugService.start(deps)
	WeaponService = deps.WeaponService
	MonsterService = deps.MonsterService
	DayNight = deps.DayNight
	InventoryService = deps.InventoryService
	SurvivalService = deps.SurvivalService

	Remotes.Debug.OnServerEvent:Connect(function(player, action, argument)
		if not DebugService.isAllowed(player) or typeof(action) ~= "string" or not actions[action] then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end
		local message = actions[action](player, character, argument)
		if message then
			Remotes.Notify:FireClient(player, "[Debug] " .. message, Color3.fromRGB(120, 220, 255))
		end
	end)
end

return DebugService
