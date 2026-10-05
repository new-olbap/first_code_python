-- Interface : vie, arme et munitions, heure du jour, messages, écran de mort.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Hud = {}

local player = Players.LocalPlayer

local gui
local healthFill, healthText
local weaponName, ammoText
local clockText, nightWarning
local hitMarker, toast, damageFlash
local deathScreen, deathKiller, deathTimer
local reloadButton

local getEquipped = function()
	return nil
end
local toastVersion = 0

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function label(props, parent)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.5
	return create("TextLabel", props, parent)
end

local function buildGui()
	gui = create("ScreenGui", { Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

	-- Barre de vie (en bas à gauche)
	local healthBar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.fromOffset(240, 22),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, healthBar)
	healthFill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	}, healthBar)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, healthFill)
	healthText = label({ Size = UDim2.fromScale(1, 1), Text = "100", TextSize = 16, ZIndex = 2 }, healthBar)

	-- Arme et munitions (en bas à droite)
	weaponName = label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -48),
		Size = UDim2.fromOffset(260, 24),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 20,
		Text = "",
	}, gui)
	ammoText = label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(260, 32),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 30,
		Text = "",
	}, gui)

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
		Size = UDim2.fromOffset(400, 20),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 90, 90),
		Text = "La nuit tombe : les monstres sont plus nombreux et plus forts",
		Visible = false,
	}, gui)

	-- Message temporaire (ramassage, etc.)
	toast = label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(500, 28),
		TextSize = 20,
		Text = "",
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}, gui)

	-- Aide (en bas au centre)
	local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(500, 18),
		TextSize = 14,
		TextTransparency = 0.3,
		Text = isTouch and "Touche l'écran : attaquer" or "Clic : attaquer   ·   R : recharger   ·   E : ramasser   ·   1-9 : armes",
	}, gui)

	-- Bouton recharger pour les écrans tactiles
	reloadButton = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -90),
		Size = UDim2.fromOffset(110, 44),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0.3,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Text = "Recharger",
		Visible = false,
	}, gui)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, reloadButton)

	-- Marqueur de touche au centre de l'écran
	hitMarker = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		TextSize = 28,
		Text = "X",
		Visible = false,
	}, gui)

	-- Flash rouge quand on prend des dégâts
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

local function formatClock(clockTime)
	local hours = math.floor(clockTime)
	local minutes = math.floor((clockTime - hours) * 60)
	return string.format("%02d:%02d", hours, minutes)
end

local function update()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthText.Text = "Vie " .. math.ceil(humanoid.Health)
	end

	local current = getEquipped()
	if current then
		local cfg = current.cfg
		weaponName.Text = cfg.name
		weaponName.TextColor3 = Config.Rarities[cfg.rarity].color
		if cfg.kind == "gun" then
			if current.tool:GetAttribute("Reloading") then
				ammoText.Text = "Rechargement..."
			else
				ammoText.Text = current.tool:GetAttribute("Ammo") .. " / " .. current.tool:GetAttribute("Reserve")
			end
		else
			ammoText.Text = "Corps à corps"
		end
		reloadButton.Visible = UserInputService.TouchEnabled and cfg.kind == "gun"
	else
		weaponName.Text = ""
		ammoText.Text = ""
		reloadButton.Visible = false
	end

	local isNight = ReplicatedStorage:GetAttribute("IsNight") == true
	clockText.Text = (isNight and "NUIT  " or "JOUR  ") .. formatClock(Lighting.ClockTime)
	clockText.TextColor3 = isNight and Color3.fromRGB(150, 160, 255) or Color3.fromRGB(255, 230, 150)
	nightWarning.Visible = isNight
end

function Hud.showToast(text, color)
	toastVersion += 1
	local version = toastVersion
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.5
	task.delay(2.5, function()
		if version == toastVersion then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

function Hud.showHitMarker(killed)
	hitMarker.TextColor3 = killed and Color3.fromRGB(255, 60, 60) or Color3.new(1, 1, 1)
	hitMarker.Visible = true
	task.delay(killed and 0.3 or 0.1, function()
		hitMarker.Visible = false
	end)
end

function Hud.setEquippedGetter(getter)
	getEquipped = getter
end

function Hud.onReloadPressed(callback)
	reloadButton.Activated:Connect(callback)
end

local function onCharacterAdded(character)
	deathScreen.Visible = false
	local humanoid = character:WaitForChild("Humanoid")
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			damageFlash.BackgroundTransparency = 0.6
			TweenService:Create(damageFlash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		end
		lastHealth = health
	end)

	humanoid.Died:Connect(function()
		local killer = humanoid:GetAttribute("LastAttacker")
		deathKiller.Text = killer and ("Tué par " .. killer) or ""
		deathScreen.Visible = true
		task.spawn(function()
			for seconds = Config.RespawnTime, 1, -1 do
				if not deathScreen.Visible then
					return
				end
				deathTimer.Text = "Réapparition dans " .. seconds .. " s... (tu perds tes armes)"
				task.wait(1)
			end
		end)
	end)
end

function Hud.start()
	buildGui()

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	Remotes.Notify.OnClientEvent:Connect(Hud.showToast)
	RunService.Heartbeat:Connect(update)
end

return Hud
