-- Gère les armes côté serveur : création des outils, tirs, coups au corps à corps
-- et rechargement. Le serveur décide toujours si un tir touche (anti-triche).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Combat = require(script.Parent.Combat)

local WeaponService = {}

local MonsterService
local rng = Random.new()
local lastAttack = {} -- [joueur] = moment de sa dernière attaque

function WeaponService.createTool(weaponId)
	local cfg = Config.Weapons[weaponId]
	local rarity = Config.Rarities[cfg.rarity]

	local tool = Instance.new("Tool")
	tool.Name = cfg.name
	tool.ToolTip = cfg.name .. " (" .. rarity.name .. ")"
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", weaponId)
	if cfg.kind == "gun" then
		tool:SetAttribute("Ammo", cfg.magazine)
		tool:SetAttribute("Reserve", cfg.reserve)
		tool:SetAttribute("Reloading", false)
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = cfg.size
	handle.Color = cfg.color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	-- L'arme est tenue par son extrémité et pointe vers l'avant
	tool.Grip = CFrame.new(0, cfg.size.Y / 2 - 0.4, 0)
	return tool
end

local function findOwnedTool(player, weaponId)
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, item in ipairs(container and container:GetChildren() or {}) do
			if item:IsA("Tool") and item:GetAttribute("WeaponId") == weaponId then
				return item
			end
		end
	end
	return nil
end

-- Donne une arme au joueur. Renvoie (ramassée ?, message à afficher)
function WeaponService.give(player, weaponId)
	local cfg = Config.Weapons[weaponId]
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not backpack or not humanoid or humanoid.Health <= 0 then
		return false, nil
	end

	local owned = findOwnedTool(player, weaponId)
	if owned then
		if cfg.kind == "gun" then
			owned:SetAttribute("Reserve", owned:GetAttribute("Reserve") + cfg.magazine)
			return true, "+" .. cfg.magazine .. " munitions (" .. cfg.name .. ")"
		end
		return false, "Tu as déjà : " .. cfg.name
	end

	WeaponService.createTool(weaponId).Parent = backpack
	return true, "Ramassé : " .. cfg.name .. " (" .. Config.Rarities[cfg.rarity].name .. ")"
end

-- Renvoie le personnage, l'arme tenue et sa config, si le joueur peut attaquer
local function getEquipped(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local weaponId = tool and tool:GetAttribute("WeaponId")
	local cfg = weaponId and Config.Weapons[weaponId]
	if not cfg then
		return nil
	end
	return character, tool, cfg
end

-- Tourne une direction au hasard dans un cône de "degrees" degrés
local function applySpread(direction, degrees)
	if degrees <= 0 then
		return direction
	end
	local angle = math.rad(rng:NextNumber(0, degrees))
	local roll = rng:NextNumber(0, 2 * math.pi)
	local frame = CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, 0, roll) * CFrame.Angles(angle, 0, 0)
	return frame.LookVector
end

local function melee(player, character, tool, cfg)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- Joue l'animation de coup d'épée de Roblox
	local animation = Instance.new("StringValue")
	animation.Name = "toolanim"
	animation.Value = "Slash"
	animation.Parent = tool

	-- On frappe la cible la plus proche devant soi
	local best, bestDistance = nil, cfg.range
	for _, target in ipairs(Combat.getTargets(character)) do
		local offset = target.HumanoidRootPart.Position - root.Position
		local distance = offset.Magnitude
		local inFront = distance < 1 or root.CFrame.LookVector:Dot(offset.Unit) > 0.2
		if distance <= bestDistance and inFront then
			best, bestDistance = target, distance
		end
	end

	if best then
		local killed = Combat.damage(best:FindFirstChildOfClass("Humanoid"), cfg.damage, player.DisplayName)
		Remotes.HitConfirmed:FireClient(player, killed)
	end
end

local function shoot(player, character, tool, cfg, targetPosition)
	local ammo = tool:GetAttribute("Ammo") or 0
	local head = character:FindFirstChild("Head")
	if ammo <= 0 or not head then
		return
	end

	local origin = head.Position
	local aim = targetPosition - origin
	if aim.Magnitude < 0.01 then
		return
	end
	aim = aim.Unit
	tool:SetAttribute("Ammo", ammo - 1)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local handle = tool:FindFirstChild("Handle")
	local muzzle = handle and handle.Position or origin
	local endPoints = {}
	local damageByHumanoid = {}

	for _ = 1, cfg.pellets do
		local direction = applySpread(aim, cfg.spread)
		local result = workspace:Raycast(origin, direction * cfg.range, params)
		table.insert(endPoints, result and result.Position or origin + direction * cfg.range)

		if result then
			local humanoid = Combat.getHumanoidFromPart(result.Instance)
			if humanoid and humanoid.Health > 0 then
				local damage = cfg.damage
				if result.Instance.Name == "Head" then
					damage *= Config.HeadshotMultiplier
				end
				damageByHumanoid[humanoid] = (damageByHumanoid[humanoid] or 0) + damage
			end
		end
	end

	Remotes.ShotFired:FireAllClients(muzzle, endPoints)

	local hit, killed = false, false
	for humanoid, damage in pairs(damageByHumanoid) do
		hit = true
		if Combat.damage(humanoid, damage, player.DisplayName) then
			killed = true
		end
	end
	if hit then
		Remotes.HitConfirmed:FireClient(player, killed)
	end

	-- Le bruit du tir attire les monstres proches
	MonsterService.reportNoise(origin, cfg.noise)
end

local function onFire(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end
	local character, tool, cfg = getEquipped(player)
	if not character or tool:GetAttribute("Reloading") then
		return
	end

	-- Le serveur vérifie la cadence de tir (petite marge pour la latence)
	local now = os.clock()
	if now - (lastAttack[player] or 0) < cfg.cooldown * 0.85 then
		return
	end
	lastAttack[player] = now

	if cfg.kind == "melee" then
		melee(player, character, tool, cfg)
	else
		shoot(player, character, tool, cfg, targetPosition)
	end
end

local function onReload(player)
	local character, tool, cfg = getEquipped(player)
	if not character or cfg.kind ~= "gun" or tool:GetAttribute("Reloading") then
		return
	end
	if tool:GetAttribute("Ammo") >= cfg.magazine or tool:GetAttribute("Reserve") <= 0 then
		return
	end

	tool:SetAttribute("Reloading", true)
	task.delay(cfg.reloadTime, function()
		if not tool.Parent then
			return
		end
		tool:SetAttribute("Reloading", false)
		local ammo = tool:GetAttribute("Ammo")
		local reserve = tool:GetAttribute("Reserve")
		local amount = math.min(cfg.magazine - ammo, reserve)
		tool:SetAttribute("Ammo", ammo + amount)
		tool:SetAttribute("Reserve", reserve - amount)
	end)
end

function WeaponService.start(monsterService)
	MonsterService = monsterService
	Remotes.Fire.OnServerEvent:Connect(onFire)
	Remotes.Reload.OnServerEvent:Connect(onReload)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

return WeaponService
