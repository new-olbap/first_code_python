-- Faim, soif, soins et utilisation des objets (manger, boire, se bander).
-- Les jauges sont des attributs du joueur (Hunger, Thirst, de 0 à 100) :
-- le serveur les fait baisser, le client les affiche.
--   - jauge vide : on perd de la vie petit à petit
--   - faim ET soif au-dessus de 70 : on regagne de la vie lentement
-- La régénération automatique de Roblox est désactivée : il faut se soigner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefs = require(ReplicatedStorage.Shared.ItemDefs)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SurvivalService = {}

local InventoryService
local cfg = GameConfig.Survival
local using: { [Player]: boolean } = {}

local function clampGauge(value: number): number
	return math.clamp(value, 0, 100)
end

function SurvivalService.isUsing(player: Player): boolean
	return using[player] == true
end

function SurvivalService.setGauges(player: Player, hunger: number, thirst: number)
	player:SetAttribute("Hunger", clampGauge(hunger))
	player:SetAttribute("Thirst", clampGauge(thirst))
end

-- Utilise un objet : on attend useTime secondes, puis l'effet s'applique
function SurvivalService.useItem(player: Player, id: string)
	local def = ItemDefs.Items[id]
	if not def or not def.use or using[player] then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or InventoryService.count(player, id) <= 0 then
		return
	end
	if def.use.heal and not def.use.hunger and not def.use.thirst and humanoid.Health >= humanoid.MaxHealth then
		Remotes.Notify:FireClient(player, "Tu as déjà toute ta vie", Color3.fromRGB(255, 200, 120))
		return
	end

	using[player] = true
	player:SetAttribute("Using", true)
	Remotes.UseProgress:FireClient(player, def.name, def.useTime)
	task.delay(def.useTime, function()
		using[player] = nil
		player:SetAttribute("Using", false)
		if humanoid.Health <= 0 or player.Character ~= character then
			return
		end
		if not InventoryService.remove(player, id, 1) then
			return
		end
		local effect = def.use
		if effect.hunger or effect.thirst then
			SurvivalService.setGauges(
				player,
				(player:GetAttribute("Hunger") or 100) + (effect.hunger or 0),
				(player:GetAttribute("Thirst") or 100) + (effect.thirst or 0)
			)
		end
		if effect.heal then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + effect.heal)
		end
	end)
end

-- Utilise le meilleur soin disponible (touche H)
function SurvivalService.quickHeal(player: Player)
	for _, id in ipairs({ "Bandage", "Medkit" }) do
		if InventoryService.count(player, id) > 0 then
			SurvivalService.useItem(player, id)
			return
		end
	end
	Remotes.Notify:FireClient(player, "Aucun soin dans l'inventaire", Color3.fromRGB(255, 120, 120))
end

local function onCharacterAdded(player: Player, character: Model)
	SurvivalService.setGauges(player, cfg.respawnHunger, cfg.respawnThirst)
	using[player] = nil
	player:SetAttribute("Using", false)
	-- Pas de régénération automatique de Roblox : le script "Health" est retiré
	local health = character:WaitForChild("Health", 5)
	if health then
		health:Destroy()
	end
end

function SurvivalService.start(inventoryService)
	InventoryService = inventoryService

	local function onPlayerAdded(player: Player)
		SurvivalService.setGauges(player, 100, 100)
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
	Players.PlayerRemoving:Connect(function(player)
		using[player] = nil
	end)

	if not cfg.enabled then
		return
	end

	-- Une fois par seconde : les jauges baissent, et leurs effets s'appliquent
	task.spawn(function()
		local sinceDamage = 0
		while true do
			task.wait(1)
			sinceDamage += 1
			local damageTick = sinceDamage >= cfg.emptyDamageInterval
			if damageTick then
				sinceDamage = 0
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and not humanoid:GetAttribute("GodMode") then
					local hunger = (player:GetAttribute("Hunger") or 100) - 100 / cfg.hungerDuration
					local thirst = (player:GetAttribute("Thirst") or 100) - 100 / cfg.thirstDuration
					SurvivalService.setGauges(player, hunger, thirst)
					if (hunger <= 0 or thirst <= 0) and damageTick then
						humanoid:SetAttribute("LastAttacker", if thirst <= 0 then "la soif" else "la faim")
						humanoid:TakeDamage(cfg.emptyDamage)
					elseif hunger >= cfg.wellFedThreshold and thirst >= cfg.wellFedThreshold then
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + cfg.wellFedRegen)
					end
				end
			end
		end
	end)
end

return SurvivalService
