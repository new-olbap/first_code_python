-- Les Rôdeurs (GDD : faibles, en groupe, attirés par le bruit des tirs).
--
-- Comportement volontairement simple et lisible :
--   errer      : le groupe traîne autour de son point d'apparition, en marchant
--   enquêter   : un bruit (tir) dans son rayon d'ouïe -> il court vers la source
--   poursuivre : il voit un joueur (sans mur entre eux) -> il crie, alerte son
--                groupe et le poursuit
--   attaquer   : à portée, il s'arrête, prend son élan (surbrillance rouge) puis
--                frappe. Si le joueur recule pendant l'élan, le coup rate.
-- La nuit, les groupes sont plus nombreux et les Rôdeurs plus forts ; ceux de la
-- nuit disparaissent à l'aube s'ils ne chassent personne.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Shared.Animations)
local AssetLoader = require(ReplicatedStorage.Shared.AssetLoader)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MonsterDefs = require(ReplicatedStorage.Shared.MonsterDefs)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)
local Combat = require(script.Parent.Combat)
local Rigs = require(script.Parent.Rigs)

local MonsterService = {}

type State = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	def: any,
	zoneId: string,
	groupId: number,
	home: Vector3,
	night: boolean,
	chaseSpeed: number,
	damage: number,
	target: Model?,
	noisePosition: Vector3?,
	noiseUntil: number,
	nextWander: number,
	attacking: boolean,
	lastAttack: number,
	lastPosition: Vector3,
	tracks: { [string]: AnimationTrack },
	currentAnimation: string?,
}

local DayNight
local folder: Folder
local rng = Random.new()
local monsters: { [Model]: State } = {}
local nextGroupId = 0
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude

local cfg = GameConfig.Monsters
local def = MonsterDefs.Prowler

-- OUTILS --------------------------------------------------------------------------

local function countMonsters(zoneId: string?): (number, number)
	local total, groups, seen = 0, 0, {}
	for _, state in pairs(monsters) do
		total += 1
		if state.zoneId == zoneId and not seen[state.groupId] then
			seen[state.groupId] = true
			groups += 1
		end
	end
	return total, groups
end

local function nearestPlayerDistance(position: Vector3): number
	local best = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local _, root = Combat.getAlive(player.Character)
		if root then
			best = math.min(best, (root.Position - position).Magnitude)
		end
	end
	return best
end

local function inTestZone(position: Vector3): boolean
	local zone = ZoneDefs.TestZone
	return math.abs(position.X - zone.center.X) < zone.size.X / 2 + 10 and math.abs(position.Z - zone.center.Z) < zone.size.Z / 2 + 10
end

local function groundAt(x: number, z: number): RaycastResult?
	return workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), sightParams)
end

local function loadTracks(humanoid: Humanoid): { [string]: AnimationTrack }
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local tracks = {}
	for key, id in pairs(Animations) do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return (animator :: Animator):LoadAnimation(animation)
		end)
		if ok and track then
			track.Priority = if key == "Attack" then Enum.AnimationPriority.Action else Enum.AnimationPriority.Movement
			tracks[key] = track
		end
	end
	return tracks
end

local function playLoop(state: State, key: string)
	if state.currentAnimation == key then
		return
	end
	local old = state.currentAnimation and state.tracks[state.currentAnimation]
	if old then
		old:Stop(0.2)
	end
	local track = state.tracks[key]
	if track then
		track.Looped = true
		track:Play(0.2)
	end
	state.currentAnimation = key
end

local function playSound(state: State, key: string, distance: number)
	local head = state.model:FindFirstChild("Head") or state.root
	SoundPlayer.playOn(head, key, distance)
end

-- APPARITION -------------------------------------------------------------------------

local function spawnMonster(position: Vector3, zoneId: string, groupId: number, night: boolean)
	local nightCfg = GameConfig.Night
	local model = AssetLoader.get("Monsters", def.assetName, function()
		return Rigs.build(def.assetName, def.skinColor, def.clothesColor)
	end) :: Model
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		warn("[Monstres] Le modèle " .. def.assetName .. " doit contenir un Humanoid et une HumanoidRootPart")
		model:Destroy()
		return
	end

	humanoid.MaxHealth = def.health * (if night then nightCfg.healthMultiplier else 1)
	humanoid.Health = humanoid.MaxHealth
	humanoid.DisplayName = if night then def.name .. " enragé" else def.name
	humanoid.NameDisplayDistance = 40
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	humanoid.WalkSpeed = def.wanderSpeed

	model:SetAttribute("MonsterType", "Prowler")
	model:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil) -- le serveur garde la main sur ses déplacements
	end)

	local state: State = {
		model = model,
		humanoid = humanoid,
		root = root,
		def = def,
		zoneId = zoneId,
		groupId = groupId,
		home = position,
		night = night,
		chaseSpeed = def.walkSpeed * (if night then nightCfg.speedMultiplier else 1),
		damage = def.damage * (if night then nightCfg.damageMultiplier else 1),
		target = nil,
		noisePosition = nil,
		noiseUntil = 0,
		nextWander = 0,
		attacking = false,
		lastAttack = 0,
		lastPosition = position,
		tracks = loadTracks(humanoid),
		currentAnimation = nil,
	}
	monsters[model] = state

	humanoid.Died:Connect(function()
		monsters[model] = nil
		playSound(state, def.sounds.death, 60)
		task.delay(cfg.corpseTime, function()
			model:Destroy()
		end)
	end)
end

-- Fait apparaître un groupe autour de center. Renvoie le nombre de monstres créés.
local function spawnGroup(center: Vector3, zoneId: string, night: boolean, count: number?): number
	nextGroupId += 1
	local size = count or rng:NextInteger(def.groupSize.min, def.groupSize.max)
	local created = 0
	for _ = 1, size do
		if countMonsters() >= cfg.maxActive then
			break
		end
		local x = center.X + rng:NextNumber(-6, 6)
		local z = center.Z + rng:NextNumber(-6, 6)
		local ground = groundAt(x, z)
		if ground then
			spawnMonster(ground.Position, zoneId, nextGroupId, night)
			created += 1
		end
	end
	return created
end

-- Cherche un endroit au sol (pas sur un toit, ni dans un arbre), loin des joueurs
local function findSpawnPosition(zone): Vector3?
	for _ = 1, 12 do
		local x = zone.center.X + rng:NextNumber(-zone.size.X / 2 + 15, zone.size.X / 2 - 15)
		local z = zone.center.Z + rng:NextNumber(-zone.size.Z / 2 + 15, zone.size.Z / 2 - 15)
		local ground = groundAt(x, z)
		if
			ground
			and ground.Position.Y < 1
			and not inTestZone(ground.Position)
			and nearestPlayerDistance(ground.Position) >= cfg.minSpawnDistance
		then
			return ground.Position
		end
	end
	return nil
end

local function populate(maxGroupsPerZone: number)
	local night = DayNight.isNight()
	for _, zone in ipairs(ZoneDefs.Zones) do
		local wanted = zone.prowlerGroups * (if night then GameConfig.Night.groupMultiplier else 1)
		local _, groups = countMonsters(zone.id)
		for _ = 1, math.min(wanted - groups, maxGroupsPerZone) do
			if countMonsters() >= cfg.maxActive then
				return
			end
			local position = findSpawnPosition(zone)
			if position then
				spawnGroup(position, zone.id, night)
			end
		end
	end
end

-- IA -----------------------------------------------------------------------------

local function canSee(state: State, character: Model, range: number): boolean
	local _, targetRoot = Combat.getAlive(character)
	if not targetRoot then
		return false
	end
	local eye = state.root.Position + Vector3.new(0, 1.5, 0)
	local offset = targetRoot.Position - eye
	if offset.Magnitude > range then
		return false
	end
	local result = workspace:Raycast(eye, offset, sightParams)
	return result == nil or result.Instance:IsDescendantOf(character)
end

local function setTarget(state: State, character: Model, alertGroup: boolean)
	local wasHunting = state.target ~= nil
	state.target = character
	state.noisePosition = nil
	if not wasHunting and alertGroup then
		playSound(state, def.sounds.alert, 80)
		-- Il prévient les membres de son groupe proches
		for _, other in pairs(monsters) do
			if other ~= state and other.groupId == state.groupId and not other.target then
				if (other.root.Position - state.root.Position).Magnitude <= def.alertRadius then
					setTarget(other, character, false)
				end
			end
		end
	end
end

local function startAttack(state: State, target: Model, now: number)
	local _, targetRoot = Combat.getAlive(target)
	if not targetRoot then
		return
	end
	state.attacking = true
	state.lastAttack = now
	local root = state.root
	state.humanoid:MoveTo(root.Position) -- il s'arrête pour prendre son élan
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
	playLoop(state, "Idle")
	if state.tracks.Attack then
		state.tracks.Attack:Play(0.1)
	end
	playSound(state, def.sounds.attack, 50)

	-- Signal visuel : le Rôdeur rougit pendant l'élan
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 40, 40)
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 1
	highlight.Parent = state.model

	task.delay(def.attackWindup, function()
		highlight:Destroy()
		state.attacking = false
		if state.humanoid.Health <= 0 then
			return
		end
		local targetHumanoid, currentRoot = Combat.getAlive(target)
		if targetHumanoid and currentRoot and (currentRoot.Position - root.Position).Magnitude <= def.attackReach then
			Combat.damage(targetHumanoid, state.damage, { name = state.humanoid.DisplayName, position = root.Position })
		end
	end)
end

local function update(state: State, now: number, night: boolean)
	local humanoid, root = state.humanoid, state.root

	-- Trop loin de tout joueur : il dort (on économise le serveur)
	if nearestPlayerDistance(root.Position) > cfg.sleepDistance then
		if state.currentAnimation ~= "Idle" then
			humanoid:MoveTo(root.Position)
			playLoop(state, "Idle")
		end
		return
	end
	if state.attacking then
		return
	end

	-- La cible est-elle toujours valable ?
	if state.target then
		local _, targetRoot = Combat.getAlive(state.target)
		if not targetRoot or (targetRoot.Position - root.Position).Magnitude > def.giveUpDistance then
			-- Il va voir où il l'a perdu de vue
			state.noisePosition = if targetRoot then targetRoot.Position else nil
			state.noiseUntil = now + def.investigateTime
			state.target = nil
		end
	end

	-- Cherche un joueur visible
	if not state.target then
		local range = def.sightRange * (if night then GameConfig.Night.sightMultiplier else 1)
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and canSee(state, player.Character, range) then
				setTarget(state, player.Character, true)
				break
			end
		end
	end

	-- POURSUITE / ATTAQUE
	local target = state.target
	if target then
		local _, targetRoot = Combat.getAlive(target)
		if targetRoot then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= def.attackRange and now - state.lastAttack >= def.attackCooldown then
				startAttack(state, target, now)
				return
			end
			humanoid.WalkSpeed = state.chaseSpeed
			humanoid:MoveTo(targetRoot.Position)
			playLoop(state, "Run")
			-- Bloqué contre un obstacle ? Il saute.
			if (root.Position - state.lastPosition).Magnitude < 0.4 and distance > def.attackRange then
				humanoid.Jump = true
			end
			state.lastPosition = root.Position
			return
		end
	end

	-- À l'aube, les Rôdeurs de la nuit qui ne chassent personne disparaissent
	if state.night and not night then
		monsters[state.model] = nil
		state.model:Destroy()
		return
	end

	-- ENQUÊTE sur un bruit
	if state.noisePosition and now < state.noiseUntil then
		humanoid.WalkSpeed = state.chaseSpeed * 0.8
		humanoid:MoveTo(state.noisePosition)
		playLoop(state, "Run")
		if (root.Position - state.noisePosition).Magnitude < 6 then
			-- Arrivé : il reste dans le coin
			state.home = state.noisePosition
			state.noisePosition = nil
			state.nextWander = now + 2
		end
		return
	end

	-- ERRANCE
	humanoid.WalkSpeed = def.wanderSpeed
	if now >= state.nextWander then
		state.nextWander = now + rng:NextNumber(4, 9)
		local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * def.wanderRadius
		humanoid:MoveTo(state.home + offset)
	end
	playLoop(state, if humanoid.MoveDirection.Magnitude > 0.1 then "Walk" else "Idle")
end

-- API ------------------------------------------------------------------------------

-- Appelé à chaque attaque bruyante : les monstres dans le rayon vont voir
function MonsterService.reportNoise(position: Vector3, radius: number)
	local now = os.clock()
	for _, state in pairs(monsters) do
		if not state.target and (state.root.Position - position).Magnitude <= radius * def.hearingMultiplier then
			state.noisePosition = position + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
			state.noiseUntil = now + def.investigateTime
		end
	end
end

-- Debug et zone de test : un groupe à une position précise
function MonsterService.spawnGroupAt(position: Vector3, count: number): number
	return spawnGroup(position, "Debug", DayNight.isNight(), count)
end

function MonsterService.killAll(): number
	local count = 0
	for model, state in pairs(monsters) do
		state.humanoid.Health = 0
		monsters[model] = nil
		count += 1
	end
	return count
end

function MonsterService.start(dayNight)
	DayNight = dayNight

	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = workspace
	Combat.registerTargetFolder(folder)

	-- La vue des monstres ignore les autres monstres et les objets non solides
	sightParams.FilterDescendantsInstances = { folder }
	sightParams.RespectCanCollide = true

	populate(math.huge)

	-- Apparitions progressives des groupes manquants
	task.spawn(function()
		while true do
			task.wait(cfg.spawnInterval)
			populate(1)
		end
	end)

	-- Réflexion des monstres, quelques fois par seconde (pas à chaque frame)
	task.spawn(function()
		while true do
			task.wait(cfg.aiTick)
			local now = os.clock()
			local night = DayNight.isNight()
			for model, state in pairs(monsters) do
				if model.Parent and state.humanoid.Health > 0 then
					update(state, now, night)
				else
					monsters[model] = nil
				end
			end
		end
	end)
end

return MonsterService
