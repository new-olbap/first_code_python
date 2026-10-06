-- Interface : vie, arme (munitions et usure), réticule dynamique, marqueur de touche,
-- direction des dégâts reçus, heure du jour, messages et écran de mort.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local Effects = require(script.Parent.Effects)
local InventoryClient = require(script.Parent.InventoryClient)

local Hud = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local gui: ScreenGui
local healthFill: Frame, healthText: TextLabel
local gauges: { [string]: { fill: Frame, label: TextLabel } } = {}
local weaponName: TextLabel, ammoText: TextLabel, durabilityFill: Frame, durabilityBar: Frame
local clockText: TextLabel, nightWarning: TextLabel
local crosshair: Frame, crosshairBars: { Frame }
local hitMarker: Frame
local toast: TextLabel
local damageFlash: Frame
local damageIndicators: { Frame } = {}
local deathScreen: Frame, deathKiller: TextLabel, deathTimer: TextLabel
local reloadButton: TextButton

local getEquipped = function(): any
	return nil
end
local getSpread = function(): number
	return 0
end
local toastVersion = 0
local hitVersion = 0
local nextIndicator = 1

local WHITE = Color3.new(1, 1, 1)

local function create(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function label(props: { [string]: any }, parent: Instance): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.5
	return create("TextLabel", props, parent)
end

local function corner(parent: Instance, radius: number)
	create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function buildGui()
	gui = create("ScreenGui", { Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

	-- Vie (en bas à gauche)
	local healthBar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(240, 22),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
	}, gui)
	corner(healthBar, 6)
	healthFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 50, 50) }, healthBar)
	corner(healthFill, 6)
	healthText = label({ Size = UDim2.fromScale(1, 1), Text = "", TextSize = 15, ZIndex = 2 }, healthBar)

	-- Faim et soif (au-dessus de la vie)
	for index, info in ipairs({
		{ key = "Hunger", name = "Faim", color = Color3.fromRGB(220, 150, 60) },
		{ key = "Thirst", name = "Soif", color = Color3.fromRGB(70, 150, 230) },
	}) do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16 + (index - 1) * 124, 1, -44),
			Size = UDim2.fromOffset(116, 14),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.3,
		}, gui)
		corner(bar, 5)
		local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = info.color }, bar)
		corner(fill, 5)
		local text = label({ Size = UDim2.fromScale(1, 1), Text = info.name, TextSize = 11, ZIndex = 2 }, bar)
		gauges[info.key] = { fill = fill, label = text }
	end

	-- Arme (en bas à droite) : nom, munitions, barre d'usure
	weaponName = label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -62),
		Size = UDim2.fromOffset(280, 22),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 20,
		Text = "",
	}, gui)
	ammoText = label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -26),
		Size = UDim2.fromOffset(280, 34),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 32,
		Text = "",
	}, gui)
	durabilityBar = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(160, 6),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		Visible = false,
	}, gui)
	corner(durabilityBar, 3)
	durabilityFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(90, 200, 90) }, durabilityBar)
	corner(durabilityFill, 3)

	-- Heure (en haut au centre)
	clockText = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(240, 26),
		TextSize = 20,
		Text = "",
	}, gui)
	nightWarning = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(420, 20),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 90, 90),
		Text = "C'est la nuit : les Rôdeurs sont plus nombreux et plus forts",
		Visible = false,
	}, gui)

	-- Message temporaire
	toast = label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(600, 28),
		TextSize = 20,
		Text = "",
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}, gui)

	-- Aide
	label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(700, 18),
		TextSize = 13,
		TextTransparency = 0.35,
		Text = if isTouch
			then "Touche l'écran : attaquer"
			else "Clic : attaquer · Clic droit : viser · R : recharger · E : ramasser/fouiller · I : inventaire · H : se soigner · F2 : debug",
	}, gui)

	-- Bouton recharger (écrans tactiles)
	reloadButton = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -100),
		Size = UDim2.fromOffset(110, 44),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0.3,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Text = "Recharger",
		Visible = false,
	}, gui)
	corner(reloadButton, 8)

	-- Réticule : 4 traits qui s'écartent avec la dispersion
	crosshair = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)
	crosshairBars = {}
	for _, vertical in ipairs({ true, true, false, false }) do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = if vertical then UDim2.fromOffset(2, 9) else UDim2.fromOffset(9, 2),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
		}, crosshair)
		create("UIStroke", { Thickness = 1, Transparency = 0.5 }, bar)
		table.insert(crosshairBars, bar)
	end
	create("Frame", { -- point central
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(3, 3),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, crosshair)

	-- Marqueur de touche : une croix en X autour du réticule
	hitMarker = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)
	for _, angle in ipairs({ 45, 135, 225, 315 }) do
		local radians = math.rad(angle)
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(math.cos(radians) * 12, math.sin(radians) * 12),
			Size = UDim2.fromOffset(10, 2),
			Rotation = angle,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
		}, hitMarker)
	end

	-- Indicateurs de direction des dégâts reçus
	for _ = 1, 4 do
		local indicator = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(70, 8),
			BackgroundColor3 = Color3.fromRGB(230, 30, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, gui)
		corner(indicator, 4)
		table.insert(damageIndicators, indicator)
	end

	damageFlash = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(200, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, gui)

	-- Écran de mort
	deathScreen = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Visible = false,
		ZIndex = 10,
	}, gui)
	label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(600, 70),
		TextSize = 60,
		TextColor3 = Color3.fromRGB(220, 40, 40),
		Text = "TU ES MORT",
		ZIndex = 11,
	}, deathScreen)
	deathKiller = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 30),
		TextSize = 24,
		Text = "",
		ZIndex = 11,
	}, deathScreen)
	deathTimer = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.fromOffset(600, 24),
		TextSize = 18,
		TextTransparency = 0.2,
		Text = "",
		ZIndex = 11,
	}, deathScreen)
end

local function formatClock(clockTime: number): string
	local hours = math.floor(clockTime)
	local minutes = math.floor((clockTime - hours) * 60)
	return string.format("%02d:%02d", hours, minutes)
end

-- Convertit un angle de dispersion en pixels à l'écran
local function spreadToPixels(degrees: number): number
	local halfFov = math.rad(camera.FieldOfView / 2)
	return math.tan(math.rad(degrees)) / math.tan(halfFov) * camera.ViewportSize.Y / 2
end

local function update()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthText.Text = "Vie " .. math.ceil(humanoid.Health)
	end

	for key, gauge in pairs(gauges) do
		local value = player:GetAttribute(key) or 100
		gauge.fill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)
		gauge.label.Text = (if key == "Hunger" then "Faim " else "Soif ") .. math.floor(value)
		gauge.label.TextColor3 = if value < 20 then Color3.fromRGB(255, 120, 120) else WHITE
	end

	local eq = getEquipped()
	if eq then
		local def, tool = eq.def, eq.tool
		weaponName.Text = def.name
		weaponName.TextColor3 = WeaponDefs.Rarities[def.rarity].color

		local durability = (tool:GetAttribute("Durability") or 0) / def.maxDurability
		durabilityBar.Visible = true
		durabilityFill.Size = UDim2.fromScale(math.clamp(durability, 0, 1), 1)
		durabilityFill.BackgroundColor3 = if durability < GameConfig.WornThreshold
			then Color3.fromRGB(220, 70, 50)
			else Color3.fromRGB(90, 200, 90)

		if durability <= 0 then
			ammoText.Text = "CASSÉE"
			ammoText.TextColor3 = Color3.fromRGB(255, 90, 60)
		elseif def.kind == "melee" then
			ammoText.Text = "Corps à corps"
			ammoText.TextColor3 = WHITE
		elseif tool:GetAttribute("Reloading") then
			ammoText.Text = "Rechargement..."
			ammoText.TextColor3 = Color3.fromRGB(255, 220, 120)
		else
			ammoText.Text = eq.predictedAmmo .. " / " .. InventoryClient.count(def.ammoItem)
			ammoText.TextColor3 = if eq.predictedAmmo == 0 then Color3.fromRGB(255, 90, 60) else WHITE
		end
		reloadButton.Visible = isTouch and def.kind ~= "melee"

		-- Réticule (au centre ; sur mobile on vise en touchant, donc pas de réticule)
		crosshair.Visible = not isTouch
		local gap = if def.kind == "melee" then 0 else math.clamp(spreadToPixels(getSpread()), 3, 120) + 4
		local offsets = { UDim2.fromOffset(0, -gap), UDim2.fromOffset(0, gap), UDim2.fromOffset(-gap, 0), UDim2.fromOffset(gap, 0) }
		for index, bar in ipairs(crosshairBars) do
			bar.Visible = def.kind ~= "melee"
			bar.Position = offsets[index]
		end
	else
		weaponName.Text = ""
		ammoText.Text = ""
		durabilityBar.Visible = false
		reloadButton.Visible = false
		crosshair.Visible = false
	end

	local isNight = ReplicatedStorage:GetAttribute("IsNight") == true
	clockText.Text = (if isNight then "NUIT  " else "JOUR  ") .. formatClock(Lighting.ClockTime)
	clockText.TextColor3 = if isNight then Color3.fromRGB(150, 160, 255) else Color3.fromRGB(255, 230, 150)
	nightWarning.Visible = isNight
end

function Hud.showToast(text: string, color: Color3?)
	toastVersion += 1
	local version = toastVersion
	toast.Text = text
	toast.TextColor3 = color or WHITE
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.5
	task.delay(2.5, function()
		if version == toastVersion then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function showHitMarker(killed: boolean)
	hitVersion += 1
	local version = hitVersion
	local color = if killed then Color3.fromRGB(255, 50, 50) else WHITE
	for _, line in ipairs(hitMarker:GetChildren()) do
		(line :: Frame).BackgroundColor3 = color
	end
	hitMarker.Visible = true
	task.delay(if killed then 0.35 else 0.12, function()
		if version == hitVersion then
			hitMarker.Visible = false
		end
	end)
end

-- Barre rouge sur le bord de l'écran, tournée vers l'origine du coup
local function showDamageDirection(sourcePosition: Vector3)
	local relative = camera.CFrame:PointToObjectSpace(sourcePosition)
	local angle = math.atan2(relative.X, -relative.Z) -- 0 = devant, positif = à droite
	local indicator = damageIndicators[nextIndicator]
	nextIndicator = nextIndicator % #damageIndicators + 1
	local radius = 150
	indicator.Position = UDim2.new(0.5, math.sin(angle) * radius, 0.5, -math.cos(angle) * radius)
	indicator.Rotation = math.deg(angle)
	indicator.BackgroundTransparency = 0.1
	TweenService:Create(indicator, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
end

local function onCharacterAdded(character: Model)
	deathScreen.Visible = false
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			damageFlash.BackgroundTransparency = 0.65
			TweenService:Create(damageFlash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		end
		lastHealth = health
	end)

	humanoid.Died:Connect(function()
		local killer = humanoid:GetAttribute("LastAttacker")
		deathKiller.Text = if killer then "Tué par " .. tostring(killer) else ""
		deathScreen.Visible = true
		task.spawn(function()
			for seconds = GameConfig.RespawnTime, 1, -1 do
				if not deathScreen.Visible then
					return
				end
				deathTimer.Text = "Ton sac est resté sur place · réapparition dans " .. seconds .. " s"
				task.wait(1)
			end
		end)
	end)
end

function Hud.bindWeapons(equippedGetter, spreadGetter, reload: () -> ())
	getEquipped = equippedGetter
	getSpread = spreadGetter
	reloadButton.Activated:Connect(reload)
end

function Hud.start()
	buildGui()

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	Remotes.Notify.OnClientEvent:Connect(Hud.showToast)

	-- Retour de touche : marqueur, chiffres de dégâts, son
	Remotes.HitConfirmed.OnClientEvent:Connect(function(hits, kind)
		local anyKill = false
		for _, hit in ipairs(hits) do
			Effects.damageNumber(hit.position, hit.damage, hit.headshot, hit.killed)
			anyKill = anyKill or hit.killed
		end
		showHitMarker(anyKill)
		if kind == "melee" then
			local eq = getEquipped()
			if eq and eq.def.sounds.hit then
				SoundPlayer.play2D(eq.def.sounds.hit)
			end
		end
		SoundPlayer.play2D(if anyKill then "KillMarker" else "HitMarker")
	end)

	Remotes.DamageTaken.OnClientEvent:Connect(function(sourcePosition)
		showDamageDirection(sourcePosition)
		SoundPlayer.play2D("PlayerHurt")
	end)

	RunService.Heartbeat:Connect(update)
end

return Hud
