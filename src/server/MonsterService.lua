-- Les Rôdeurs : faibles, en groupe, attirés par le bruit des tirs (GDD).
-- Chaque zone garde un nombre de monstres, doublé la nuit.
-- Les monstres "de nuit" disparaissent au lever du jour s'ils ne chassent personne.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Combat = require(script.Parent.Combat)

local MonsterService = {}

local DayNight
local rng = Random.new()
local folder
local template
local monsters = {} -- [modèle] = état du monstre

local AI_TICK = 0.3
local NOISE_MEMORY = 15 -- secondes pendant lesquelles un monstre suit un bruit

-- Rig de secours très simple si CreateHumanoidModelFromDescription échoue
local function buildSimpleRig(cfg)
	local model = Instance.new("Model")
	local function bodyPart(name, size, offset, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.CFrame = CFrame.new(offset)
		part.Parent = model
		return part
	end
	local root = bodyPart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), cfg.clothesColor)
	root.Transparency = 1
	local pieces = {
		bodyPart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), cfg.clothesColor),
		bodyPart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), cfg.skinColor),
		bodyPart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), cfg.clothesColor),
		bodyPart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), cfg.clothesColor),
	}
	for _, piece in ipairs(pieces) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = piece
		weld.Parent = piece
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

local function buildTemplate()
	local cfg = Config.Monsters.Rodeur
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = cfg.skinColor
	description.LeftArmColor = cfg.skinColor
	description.RightArmColor = cfg.skinColor
	description.TorsoColor = cfg.clothesColor
	description.LeftLegColor = cfg.clothesColor
	description.RightLegColor = cfg.clothesColor

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[Survie] Rig R15 indisponible, utilisation d'un rig simple :", model)
		model = buildSimpleRig(cfg)
	end
	model.Name = cfg.name
	template = model
end

local function countInZone(zoneId)
	local count = 0
	for _, state in pairs(monsters) do
		if state.zoneId == zoneId then
			count += 1
		end
	end
	return count
end

local function isFarFromPlayers(position)
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - position).Magnitude < Config.MonsterMinSpawnDistance then
			return false
		end
	end
	return true
end

-- Cherche un endroit au sol (pas sur un toit ni dans un arbre), loin des joueurs
local function findSpawnPosition(zone)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }

	for _ = 1, 10 do
		local x = zone.center.X + rng:NextNumber(-zone.size.X / 2 + 15, zone.size.X / 2 - 15)
		local z = zone.center.Z + rng:NextNumber(-zone.size.Z / 2 + 15, zone.size.Z / 2 - 15)
		local result = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0), params)
		if result and result.Position.Y < 1 and isFarFromPlayers(result.Position) then
			return result.Position
		end
	end
	return nil
end

local function spawnMonster(zone, night)
	local position = findSpawnPosition(zone)
	if not position then
		return
	end

	local cfg = Config.Monsters.Rodeur
	local nightCfg = Config.Night
	local model = template:Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")

	humanoid.MaxHealth = cfg.health * (night and nightCfg.healthMultiplier or 1)
	humanoid.Health = humanoid.MaxHealth
	humanoid.DisplayName = night and (cfg.name .. " enragé") or cfg.name
	humanoid.NameDisplayDistance = 40
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged

	model:SetAttribute("Monster", "Rodeur")
	model:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
	model.Parent = folder
	-- Le serveur garde le contrôle de la physique du monstre
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local state = {
		humanoid = humanoid,
		root = root,
		zoneId = zone.id,
		home = position,
		night = night,
		chaseSpeed = cfg.walkSpeed * (night and nightCfg.speedMultiplier or 1),
		damage = cfg.damage * (night and nightCfg.damageMultiplier or 1),
		lastAttack = 0,
		nextWander = 0,
		noisePosition = nil,
		noiseTime = 0,
		lastPosition = position,
	}
	monsters[model] = state

	humanoid.Died:Connect(function()
		monsters[model] = nil
		task.delay(4, function()
			model:Destroy()
		end)
	end)
end

local function findClosestPlayer(position, range)
	local best, bestDistance = nil, range
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = character, distance
			end
		end
	end
	return best, bestDistance
end

local function updateMonster(model, state, now)
	local cfg = Config.Monsters.Rodeur
	local night = DayNight.isNight()
	local humanoid, root = state.humanoid, state.root

	local detectRange = cfg.detectRange * (night and Config.Night.detectMultiplier or 1)
	local target, distance = findClosestPlayer(root.Position, detectRange)

	if target then
		humanoid.WalkSpeed = state.chaseSpeed
		humanoid:MoveTo(target.HumanoidRootPart.Position)

		-- Bloqué contre un obstacle ? On saute.
		if (root.Position - state.lastPosition).Magnitude < 0.5 then
			humanoid.Jump = true
		end
		state.lastPosition = root.Position

		if distance <= cfg.attackRange and now - state.lastAttack >= cfg.attackCooldown then
			state.lastAttack = now
			Combat.damage(target:FindFirstChildOfClass("Humanoid"), state.damage, humanoid.DisplayName)
		end
		return
	end

	-- Au lever du jour, les monstres de la nuit qui ne chassent personne disparaissent
	if state.night and not night then
		monsters[model] = nil
		model:Destroy()
		return
	end

	humanoid.WalkSpeed = cfg.wanderSpeed

	if state.noisePosition and now - state.noiseTime < NOISE_MEMORY then
		humanoid.WalkSpeed = state.chaseSpeed
		humanoid:MoveTo(state.noisePosition)
		if (root.Position - state.noisePosition).Magnitude < 6 then
			state.noisePosition = nil
		end
		return
	end

	-- Sinon, il erre autour de son point d'apparition
	if now >= state.nextWander then
		state.nextWander = now + rng:NextNumber(4, 9)
		local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * cfg.wanderRadius
		humanoid:MoveTo(state.home + offset)
	end
end

-- Appelé à chaque tir : les monstres dans le rayon vont voir ce qui se passe
function MonsterService.reportNoise(position, radius)
	local now = os.clock()
	for _, state in pairs(monsters) do
		if (state.root.Position - position).Magnitude <= radius then
			state.noisePosition = position + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
			state.noiseTime = now
		end
	end
end

local function populate(maxPerZone)
	local night = DayNight.isNight()
	for _, zone in ipairs(Config.Zones) do
		local wanted = zone.monsters * (night and Config.Night.countMultiplier or 1)
		local missing = math.min(wanted - countInZone(zone.id), maxPerZone)
		for _ = 1, missing do
			spawnMonster(zone, night)
		end
	end
end

function MonsterService.start(dayNight)
	DayNight = dayNight

	folder = Instance.new("Folder")
	folder.Name = "Monstres"
	folder.Parent = workspace

	buildTemplate()
	populate(math.huge)

	-- Apparition progressive des monstres manquants
	task.spawn(function()
		while true do
			task.wait(Config.MonsterSpawnInterval)
			populate(2)
		end
	end)

	-- Intelligence des monstres
	task.spawn(function()
		while true do
			task.wait(AI_TICK)
			local now = os.clock()
			for model, state in pairs(monsters) do
				if model.Parent and state.humanoid.Health > 0 then
					updateMonster(model, state, now)
				else
					monsters[model] = nil
				end
			end
		end
	end)
end

return MonsterService
