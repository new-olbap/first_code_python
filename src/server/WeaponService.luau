-- Armes côté serveur : création des outils, attaques, rechargement et usure.
--
-- Choix d'architecture : le client calcule la dispersion et affiche son tir tout de
-- suite (le tir paraît instantané), puis envoie les directions des balles. Le serveur
-- vérifie tout le reste (arme tenue, cadence, munitions, usure), refait le raycast
-- depuis la tête du personnage et décide seul des dégâts.
--
-- Une arme existe sous deux formes :
--   - un "item" : une simple table { weaponId, ammo, reserve, durability }
--     (au sol, dans un sac)
--   - un Tool dans le sac à dos du joueur, avec les mêmes valeurs en attributs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Placeholders = require(ReplicatedStorage.Shared.Placeholders)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local Combat = require(script.Parent.Combat)

local WeaponService = {}

export type Item = {
	weaponId: string,
	ammo: number,
	reserve: number,
	durability: number,
}

type HitInfo = { position: Vector3, damage: number, headshot: boolean, killed: boolean }

local MonsterService
local Projectiles
local lastAttack: { [Player]: number } = {}
local busy: { [Player]: boolean } = {} -- pendant l'élan d'un coup d'arme blanche

-- ITEMS ET OUTILS ---------------------------------------------------------------

function WeaponService.newItem(weaponId: string, durabilityRatio: number?): Item
	local def = WeaponDefs.Weapons[weaponId]
	return {
		weaponId = weaponId,
		ammo = def.magazine or 0,
		reserve = def.reserve or 0,
		durability = math.max(1, math.floor(def.maxDurability * (durabilityRatio or 1))),
	}
end

function WeaponService.createTool(item: Item): Tool
	local def = WeaponDefs.Weapons[item.weaponId]
	local asset = AssetLoader.get("Weapons", item.weaponId, function()
		return Placeholders.weaponTool(item.weaponId)
	end)

	-- Un vrai modèle peut être un Tool ou un Model contenant une pièce "Handle"
	local tool: Tool
	if asset:IsA("Tool") then
		tool = asset
	else
		tool = Instance.new("Tool")
		for _, child in ipairs(asset:GetChildren()) do
			child.Parent = tool
		end
		local handle = tool:FindFirstChild("Handle") :: BasePart?
		if handle then
			tool.Grip = CFrame.new(0, 0, handle.Size.Z / 2 - 0.4)
		end
		asset:Destroy()
	end

	tool.Name = def.name
	tool.ToolTip = def.name .. " (" .. WeaponDefs.Rarities[def.rarity].name .. ")"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	tool:SetAttribute("WeaponId", item.weaponId)
	tool:SetAttribute("Durability", item.durability)
	if def.kind ~= "melee" then
		tool:SetAttribute("Ammo", item.ammo)
		tool:SetAttribute("Reserve", item.reserve)
		tool:SetAttribute("Reloading", false)
	end
	return tool
end

function WeaponService.toolToItem(tool: Tool): Item?
	local weaponId = tool:GetAttribute("WeaponId")
	if typeof(weaponId) ~= "string" or not WeaponDefs.Weapons[weaponId] then
		return nil
	end
	return {
		weaponId = weaponId,
		ammo = tool:GetAttribute("Ammo") or 0,
		reserve = tool:GetAttribute("Reserve") or 0,
		durability = tool:GetAttribute("Durability") or 1,
	}
end

-- Toutes les armes d'un joueur (sac à dos + main)
function WeaponService.getTools(player: Player): { Tool }
	local tools = {}
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("WeaponId") then
					table.insert(tools, child)
				end
			end
		end
	end
	return tools
end

function WeaponService.findTool(player: Player, weaponId: string): Tool?
	for _, tool in ipairs(WeaponService.getTools(player)) do
		if tool:GetAttribute("WeaponId") == weaponId then
			return tool
		end
	end
	return nil
end

local function isAlive(player: Player): boolean
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Donne un item au joueur. Renvoie (item pris ?, message à afficher)
-- Si le joueur a déjà cette arme à munitions, on récupère seulement ses munitions.
function WeaponService.giveItem(player: Player, item: Item): (boolean, string?)
	local def = WeaponDefs.Weapons[item.weaponId]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or not isAlive(player) then
		return false, nil
	end

	local owned = WeaponService.findTool(player, item.weaponId)
	if owned then
		local ammo = item.ammo + item.reserve
		if def.kind ~= "melee" and ammo > 0 then
			owned:SetAttribute("Reserve", (owned:GetAttribute("Reserve") or 0) + ammo)
			return true, "+" .. ammo .. " munitions (" .. def.name .. ")"
		end
		return false, "Tu as déjà : " .. def.name
	end

	WeaponService.createTool(item).Parent = backpack
	return true, "Ramassé : " .. def.name .. " (" .. WeaponDefs.Rarities[def.rarity].name .. ")"
end

-- Ajoute des munitions de réserve à une arme possédée (flèches ramassées, debug)
function WeaponService.addReserve(player: Player, weaponId: string, amount: number): boolean
	local tool = WeaponService.findTool(player, weaponId)
	if not tool then
		return false
	end
	tool:SetAttribute("Reserve", (tool:GetAttribute("Reserve") or 0) + amount)
	return true
end

-- ATTAQUES ----------------------------------------------------------------------

local function getEquipped(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local weaponId = tool and tool:GetAttribute("WeaponId")
	local def = weaponId and WeaponDefs.Weapons[weaponId]
	if not tool or not def then
		return nil
	end
	return character, tool, def
end

local function wear(player: Player, tool: Tool, def)
	local durability = math.max(0, (tool:GetAttribute("Durability") or 0) - def.wearPerUse)
	tool:SetAttribute("Durability", durability)
	if durability == 0 then
		Remotes.Notify:FireClient(player, def.name .. " est cassée !", Color3.fromRGB(255, 120, 80))
		local handle = tool:FindFirstChild("Handle")
		if handle then
			SoundPlayer.playOn(handle, "WeaponBreak", 40)
		end
	end
end

-- Envoie un effet visuel à tous les joueurs sauf l'attaquant (lui l'a déjà affiché)
local function broadcastFx(shooter: Player, ...)
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= shooter then
			Remotes.WeaponFx:FireClient(other, ...)
		end
	end
end

local function getMuzzle(tool: Tool, fallback: Vector3): Vector3
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local muzzle = handle and handle:FindFirstChild("Muzzle") :: Attachment?
	if muzzle then
		return muzzle.WorldPosition
	end
	return if handle then handle.Position else fallback
end

-- Vérifie la liste de directions envoyée par le client
local function readDirections(directions: any, maxCount: number): { Vector3 }?
	if typeof(directions) ~= "table" or #directions < 1 or #directions > maxCount then
		return nil
	end
	local result = {}
	for _, direction in ipairs(directions) do
		if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 or direction.Magnitude > 1.5 then
			return nil
		end
		table.insert(result, direction.Unit)
	end
	return result
end

local function melee(player: Player, character: Model, tool: Tool, def)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	-- Animation de coup intégrée à Roblox
	local animation = Instance.new("StringValue")
	animation.Name = "toolanim"
	animation.Value = "Slash"
	animation.Parent = tool
	broadcastFx(player, "swing", tool:GetAttribute("WeaponId"), root.Position)

	-- Le coup touche après un court élan : il est lisible, et on peut le voir venir
	busy[player] = true
	task.delay(def.windup, function()
		busy[player] = nil
		if tool.Parent ~= character or not Combat.getAlive(character) then
			return
		end

		-- On frappe la cible la plus proche devant soi
		local best: Model?, bestDistance = nil, def.range
		for _, target in ipairs(Combat.getTargets(character)) do
			local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart
			local offset = targetRoot.Position - root.Position
			local distance = offset.Magnitude
			local inFront = distance < 1.5 or root.CFrame.LookVector:Dot(offset.Unit) > def.arc
			if distance <= bestDistance and inFront then
				best, bestDistance = target, distance
			end
		end

		wear(player, tool, def)
		MonsterService.reportNoise(root.Position, def.noise)
		if not best then
			return
		end
		local humanoid = best:FindFirstChildOfClass("Humanoid") :: Humanoid
		local dealt, killed = Combat.damage(humanoid, def.damage, {
			name = player.DisplayName,
			position = root.Position,
			weaponName = def.name,
		})
		if dealt > 0 then
			local hitPart = best:FindFirstChild("Head") or best:FindFirstChild("HumanoidRootPart")
			local hit: HitInfo = {
				position = (hitPart :: BasePart).Position,
				damage = dealt,
				headshot = false,
				killed = killed,
			}
			Remotes.HitConfirmed:FireClient(player, { hit }, "melee")
		end
	end)
end

local function shoot(player: Player, character: Model, tool: Tool, def, directions: { Vector3 })
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	tool:SetAttribute("Ammo", tool:GetAttribute("Ammo") - 1)
	wear(player, tool, def)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local origin = head.Position
	local endPoints = {}
	local damageByHumanoid: { [Humanoid]: { damage: number, position: Vector3, headshot: boolean } } = {}

	for _, direction in ipairs(directions) do
		local result = workspace:Raycast(origin, direction * def.range, params)
		table.insert(endPoints, if result then result.Position else origin + direction * def.range)
		if result then
			local humanoid = Combat.getHumanoidFromPart(result.Instance)
			if humanoid and humanoid.Health > 0 then
				local headshot = result.Instance.Name == "Head"
				local entry = damageByHumanoid[humanoid] or { damage = 0, position = result.Position, headshot = false }
				entry.damage += def.damage * (if headshot then GameConfig.HeadshotMultiplier else 1)
				entry.position = result.Position
				entry.headshot = entry.headshot or headshot
				damageByHumanoid[humanoid] = entry
			end
		end
	end

	broadcastFx(player, "shot", tool:GetAttribute("WeaponId"), getMuzzle(tool, origin), endPoints)

	local hits: { HitInfo } = {}
	for humanoid, entry in pairs(damageByHumanoid) do
		local dealt, killed = Combat.damage(humanoid, entry.damage, {
			name = player.DisplayName,
			position = origin,
			weaponName = def.name,
		})
		if dealt > 0 then
			table.insert(hits, { position = entry.position, damage = dealt, headshot = entry.headshot, killed = killed })
		end
	end
	if #hits > 0 then
		Remotes.HitConfirmed:FireClient(player, hits, "gun")
	end

	-- Le bruit du tir attire les monstres proches
	MonsterService.reportNoise(origin, def.noise)
end

local function shootArrow(player: Player, character: Model, tool: Tool, def, direction: Vector3)
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	tool:SetAttribute("Ammo", tool:GetAttribute("Ammo") - 1)
	wear(player, tool, def)

	local origin = head.Position + direction * 1.5
	local velocity = direction * def.projectileSpeed
	broadcastFx(player, "arrow", tool:GetAttribute("WeaponId"), origin, velocity)

	Projectiles.fire({
		owner = player,
		ignore = { character },
		origin = origin,
		velocity = velocity,
		gravity = def.gravity,
		damage = def.damage,
		weaponName = def.name,
	})
	MonsterService.reportNoise(origin, def.noise)
end

local function onAttack(player: Player, directions: any)
	local character, tool, def = getEquipped(player)
	if not character or busy[player] then
		return
	end
	if (tool:GetAttribute("Durability") or 0) <= 0 then
		return
	end

	-- Cadence : petite marge de tolérance pour la latence
	local now = os.clock()
	if now - (lastAttack[player] or 0) < def.cooldown * 0.8 then
		return
	end

	if def.kind == "melee" then
		lastAttack[player] = now
		melee(player, character, tool, def)
		return
	end

	if tool:GetAttribute("Reloading") or (tool:GetAttribute("Ammo") or 0) <= 0 then
		return
	end
	local checked = readDirections(directions, def.pellets)
	if not checked then
		return
	end
	lastAttack[player] = now
	if def.kind == "gun" then
		shoot(player, character, tool, def, checked)
	else
		shootArrow(player, character, tool, def, checked[1])
	end
end

local function onReload(player: Player)
	local character, tool, def = getEquipped(player)
	if not character or def.kind == "melee" or tool:GetAttribute("Reloading") then
		return
	end
	local ammo, reserve = tool:GetAttribute("Ammo"), tool:GetAttribute("Reserve")
	if ammo >= def.magazine or reserve <= 0 then
		return
	end

	tool:SetAttribute("Reloading", true)
	local handle = tool:FindFirstChild("Handle")
	if handle and def.sounds.reload then
		SoundPlayer.playOn(handle, def.sounds.reload, 30)
	end

	task.delay(def.reloadTime, function()
		if not tool.Parent then
			return
		end
		tool:SetAttribute("Reloading", false)
		-- Si le joueur a rangé l'arme pendant le rechargement, il est annulé
		if tool.Parent ~= player.Character then
			return
		end
		local currentAmmo = tool:GetAttribute("Ammo")
		local currentReserve = tool:GetAttribute("Reserve")
		local amount = math.min(def.magazine - currentAmmo, currentReserve)
		tool:SetAttribute("Ammo", currentAmmo + amount)
		tool:SetAttribute("Reserve", currentReserve - amount)
	end)
end

function WeaponService.start(monsterService, projectiles)
	MonsterService = monsterService
	Projectiles = projectiles
	Remotes.Attack.OnServerEvent:Connect(onAttack)
	Remotes.Reload.OnServerEvent:Connect(onReload)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
		busy[player] = nil
	end)
end

return WeaponService
