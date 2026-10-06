-- Contrôles des armes côté joueur.
--   Clic gauche : attaquer (maintenir pour le fusil d'assaut)
--   Clic droit  : viser (zoom, meilleure précision)
--   R           : recharger
--
-- Avec une arme en main sur ordinateur, la caméra passe "par-dessus l'épaule" :
-- la souris est bloquée au centre et le personnage tourne avec la caméra, comme
-- dans la plupart des jeux de tir.
--
-- Ressenti immédiat : le client calcule la dispersion, affiche le tir et le recul
-- tout de suite, puis envoie les directions au serveur qui décide des dégâts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Ballistics = require(ReplicatedStorage.Shared.Ballistics)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local Effects = require(script.Parent.Effects)
local InventoryClient = require(script.Parent.InventoryClient)

local WeaponController = {}

type Equipped = {
	tool: Tool,
	def: any,
	weaponId: string,
	predictedAmmo: number,
	connections: { RBXScriptConnection },
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local rng = Random.new()

local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local DEFAULT_FOV = 70
local SHOULDER_OFFSET = Vector3.new(1.75, 0.4, 0)

local equipped: Equipped? = nil
local character: Model? = nil
local holding = false
local aiming = false
local lastAttack = 0
local bloom = 0 -- dispersion accumulée par les tirs rapprochés (degrés)
local recoilPitch, recoilYaw = 0, 0 -- décalage de caméra dû au recul (degrés)
local currentRecoilRecovery = 10
local lastBrokenWarning = 0
local openMenus: { [string]: boolean } = {} -- un menu est ouvert : on libère la souris
local mouseFree = false

local Hud

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude

local function getHumanoid(): Humanoid?
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function durabilityRatio(eq: Equipped): number
	return (eq.tool:GetAttribute("Durability") or 0) / eq.def.maxDurability
end

-- Dispersion actuelle en degrés (utilisée aussi par le réticule du HUD)
function WeaponController.getSpread(): number
	local eq = equipped
	if not eq or eq.def.kind == "melee" then
		return 0
	end
	local spread = eq.def.spread
	local humanoid = getHumanoid()
	local moving = humanoid
		and (humanoid.MoveDirection.Magnitude > 0.1 or humanoid.FloorMaterial == Enum.Material.Air)
	local total = math.min(spread.base + bloom, spread.max) + (if moving then spread.moving else 0)
	if aiming then
		total *= 0.6
	end
	if durabilityRatio(eq) < GameConfig.WornThreshold then
		total *= GameConfig.WornSpreadMultiplier
	end
	return total
end

function WeaponController.getEquipped(): Equipped?
	return equipped
end

function WeaponController.isAiming(): boolean
	return aiming
end

-- Point visé : le centre de l'écran (ordinateur) ou l'endroit touché (mobile)
local function getAimPoint(): Vector3
	if isTouch then
		return mouse.Hit.Position
	end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, aimParams)
	return if result then result.Position else ray.Origin + ray.Direction * 1000
end

local function getMuzzle(tool: Tool, fallback: Vector3): Vector3
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local muzzle = handle and handle:FindFirstChild("Muzzle") :: Attachment?
	if muzzle then
		return muzzle.WorldPosition
	end
	return if handle then handle.Position else fallback
end

local function requestReload()
	local eq = equipped
	if not eq or eq.def.kind == "melee" or eq.tool:GetAttribute("Reloading") then
		return
	end
	if (eq.tool:GetAttribute("Ammo") or 0) < eq.def.magazine and InventoryClient.count(eq.def.ammoItem) > 0 then
		Remotes.Reload:FireServer()
	end
end

local function attack()
	local eq = equipped
	local humanoid = getHumanoid()
	if not eq or not character or not humanoid or humanoid.Health <= 0 or player:GetAttribute("Using") then
		return
	end
	local def = eq.def
	local now = os.clock()
	if now - lastAttack < def.cooldown then
		return
	end
	if (eq.tool:GetAttribute("Durability") or 0) <= 0 then
		if now - lastBrokenWarning > 1.5 then
			lastBrokenWarning = now
			Hud.showToast(def.name .. " est cassée", Color3.fromRGB(255, 120, 80))
		end
		return
	end

	-- Arme blanche : le serveur gère l'élan et la touche
	if def.kind == "melee" then
		lastAttack = now
		Remotes.Attack:FireServer()
		local handle = eq.tool:FindFirstChild("Handle")
		if handle and def.sounds.swing then
			SoundPlayer.playOn(handle, def.sounds.swing, 40)
		end
		return
	end

	if eq.tool:GetAttribute("Reloading") then
		return
	end
	if eq.predictedAmmo <= 0 then
		lastAttack = now
		if def.sounds.empty then
			SoundPlayer.play2D(def.sounds.empty)
		end
		requestReload()
		return
	end

	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	lastAttack = now
	eq.predictedAmmo -= 1

	local origin = head.Position
	local aim = getAimPoint() - origin
	if aim.Magnitude < 0.1 then
		return
	end
	aim = aim.Unit
	local spread = WeaponController.getSpread()
	local directions = {}
	for i = 1, def.pellets do
		directions[i] = Ballistics.applySpread(aim, spread, rng)
	end

	-- Affichage immédiat
	if def.kind == "gun" then
		local endPoints = {}
		for i, direction in ipairs(directions) do
			local result = workspace:Raycast(origin, direction * def.range, aimParams)
			endPoints[i] = if result then result.Position else origin + direction * def.range
		end
		Effects.shot(eq.weaponId, getMuzzle(eq.tool, origin), endPoints)
	else
		Effects.arrow(eq.weaponId, origin + directions[1] * 1.5, directions[1] * def.projectileSpeed, { character })
	end

	Remotes.Attack:FireServer(directions)

	-- Recul et dispersion qui monte
	bloom += def.spread.perShot
	local kick = if aiming then 0.7 else 1
	recoilPitch += def.recoil.vertical * kick
	recoilYaw += rng:NextNumber(-def.recoil.horizontal, def.recoil.horizontal) * kick
	currentRecoilRecovery = def.recoil.recovery

	-- L'arc encoche automatiquement la flèche suivante
	if def.kind == "bow" and eq.predictedAmmo <= 0 then
		task.delay(0.15, requestReload)
	end
end

local function onActivated()
	holding = true
	attack()
	local eq = equipped
	if eq and eq.def.automatic then
		task.spawn(function()
			while holding and equipped == eq do
				task.wait()
				attack()
			end
		end)
	end
end

local function setCombatCamera(enabled: boolean)
	local humanoid = getHumanoid()
	if isTouch or not humanoid then
		return
	end
	humanoid.AutoRotate = not enabled
	humanoid.CameraOffset = if enabled then SHOULDER_OFFSET else Vector3.zero
	if not enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	UserInputService.MouseIconEnabled = not enabled
end

local function onEquipped(tool: Tool)
	local weaponId = tool:GetAttribute("WeaponId")
	local def = typeof(weaponId) == "string" and WeaponDefs.Weapons[weaponId]
	if not def then
		return
	end
	local eq: Equipped = {
		tool = tool,
		def = def,
		weaponId = weaponId :: string,
		predictedAmmo = tool:GetAttribute("Ammo") or 0,
		connections = {},
	}
	table.insert(eq.connections, tool.Activated:Connect(onActivated))
	table.insert(eq.connections, tool.Deactivated:Connect(function()
		holding = false
	end))
	-- Le serveur a toujours raison : on se recale sur ses munitions
	table.insert(eq.connections, tool:GetAttributeChangedSignal("Ammo"):Connect(function()
		eq.predictedAmmo = tool:GetAttribute("Ammo") or 0
	end))
	equipped = eq
	bloom = 0
	setCombatCamera(true)
end

local function onUnequipped(tool: Tool)
	local eq = equipped
	if eq and eq.tool == tool then
		for _, connection in ipairs(eq.connections) do
			connection:Disconnect()
		end
		equipped = nil
		holding = false
		aiming = false
		setCombatCamera(false)
	end
end

local function onCharacterAdded(newCharacter: Model)
	character = newCharacter
	equipped = nil
	holding = false
	aiming = false
	UserInputService.MouseIconEnabled = true
	aimParams.FilterDescendantsInstances = { newCharacter, Effects.folder }
	newCharacter.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onEquipped(child)
		end
	end)
	newCharacter.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onUnequipped(child)
		end
	end)
end

-- Appelé à chaque image, juste après la caméra de Roblox
local function onRenderStep(dt: number)
	local eq = equipped
	local humanoid = getHumanoid()

	-- La dispersion redescend quand on arrête de tirer
	if eq and eq.def.kind ~= "melee" then
		bloom = math.max(0, bloom - eq.def.spread.recovery * dt)
	end

	-- Recul : la caméra monte puis revient doucement
	if math.abs(recoilPitch) > 0.001 or math.abs(recoilYaw) > 0.001 then
		camera.CFrame *= CFrame.Angles(math.rad(recoilPitch), math.rad(recoilYaw), 0)
		local decay = math.exp(-currentRecoilRecovery * dt)
		recoilPitch *= decay
		recoilYaw *= decay
	end

	-- Visée : zoom progressif
	local targetFov = if aiming and eq and eq.def.aimFov then eq.def.aimFov else DEFAULT_FOV
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 12)

	-- Caméra d'épaule : souris au centre, le personnage regarde où vise la caméra
	if eq and not isTouch and not mouseFree and humanoid and humanoid.Health > 0 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.01 then
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
			end
		end
	end
end

-- Un menu (inventaire, debug...) libère la souris tant qu'il est ouvert
function WeaponController.setMouseFree(menu: string, open: boolean)
	if open then
		openMenus[menu] = true
	else
		openMenus[menu] = nil
	end
	local free = next(openMenus) ~= nil
	mouseFree = free
	if free then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseIconEnabled = equipped == nil or isTouch
	end
end

function WeaponController.start(hud)
	Hud = hud
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	RunService:BindToRenderStep("WeaponController", Enum.RenderPriority.Camera.Value + 1, onRenderStep)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			requestReload()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = equipped ~= nil and equipped.def.kind ~= "melee"
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = false
		end
	end)

	hud.bindWeapons(WeaponController.getEquipped, WeaponController.getSpread, requestReload)
end

return WeaponController
