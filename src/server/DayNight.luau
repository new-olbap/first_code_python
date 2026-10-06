-- Cycle jour/nuit et ambiance lumineuse.
-- Jour de 6h à 18h, nuit de 18h à 6h (durées dans GameConfig).
-- Les autres systèmes demandent DayNight.isNight() ou écoutent DayNight.NightChanged.
-- L'ambiance (brume, couleurs, bloom) change doucement entre le jour et la nuit.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DayNight = {}

local nightChangedEvent = Instance.new("BindableEvent")
DayNight.NightChanged = nightChangedEvent.Event

local cfg = GameConfig.DayNight
local cycleLength = cfg.dayLength + cfg.nightLength
local elapsed = (cfg.startClock - 6) / 12 * cfg.dayLength -- temps écoulé dans le cycle
local isNight = false

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local bloom: BloomEffect
local sunRays: SunRaysEffect

-- Deux ambiances : on passe de l'une à l'autre en douceur
local MOODS = {
	day = {
		lighting = {
			Ambient = Color3.fromRGB(95, 90, 85),
			OutdoorAmbient = Color3.fromRGB(135, 130, 120),
			Brightness = 2.4,
			ExposureCompensation = 0,
		},
		atmosphere = { Density = 0.32, Haze = 1.4, Color = Color3.fromRGB(200, 195, 180), Decay = Color3.fromRGB(110, 100, 90) },
		colorCorrection = { TintColor = Color3.fromRGB(255, 246, 232), Saturation = -0.05, Contrast = 0.08, Brightness = 0 },
	},
	night = {
		lighting = {
			Ambient = Color3.fromRGB(20, 22, 35),
			OutdoorAmbient = Color3.fromRGB(35, 40, 65),
			Brightness = 0.6,
			ExposureCompensation = -0.2,
		},
		atmosphere = { Density = 0.45, Haze = 2.2, Color = Color3.fromRGB(60, 70, 95), Decay = Color3.fromRGB(25, 25, 40) },
		colorCorrection = { TintColor = Color3.fromRGB(190, 205, 255), Saturation = -0.25, Contrast = 0.15, Brightness = -0.03 },
	},
}

function DayNight.isNight(): boolean
	return isNight
end

local function getOrCreate(className: string): any
	local existing = Lighting:FindFirstChildOfClass(className)
	if existing then
		return existing
	end
	local effect = Instance.new(className)
	effect.Parent = Lighting
	return effect
end

local function setupEffects()
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.3

	atmosphere = getOrCreate("Atmosphere")
	atmosphere.Offset = 0.1
	atmosphere.Glare = 0.4

	colorCorrection = getOrCreate("ColorCorrectionEffect")
	bloom = getOrCreate("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 28
	bloom.Threshold = 1.6
	sunRays = getOrCreate("SunRaysEffect")
	sunRays.Intensity = 0.06
	sunRays.Spread = 0.8
end

local function applyMood(name: string, duration: number)
	local mood = MOODS[name]
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, mood.lighting):Play()
	TweenService:Create(atmosphere, info, mood.atmosphere):Play()
	TweenService:Create(colorCorrection, info, mood.colorCorrection):Play()
end

local function applyNight(night: boolean, duration: number)
	isNight = night
	ReplicatedStorage:SetAttribute("IsNight", night)
	applyMood(if night then "night" else "day", duration)
	nightChangedEvent:Fire(night)
end

local function updateClock(): boolean
	local clock, night
	if elapsed < cfg.dayLength then
		clock = 6 + 12 * elapsed / cfg.dayLength
		night = false
	else
		clock = 18 + 12 * (elapsed - cfg.dayLength) / cfg.nightLength
		night = true
	end
	Lighting.ClockTime = clock % 24
	return night
end

-- Debug : saute au début du jour (8h) ou de la nuit (20h)
function DayNight.skipTo(night: boolean)
	if night then
		elapsed = cfg.dayLength + cfg.nightLength / 6
	else
		elapsed = cfg.dayLength / 6
	end
	applyNight(updateClock(), 2)
end

function DayNight.start()
	setupEffects()
	applyNight(updateClock(), 0)
	if not cfg.enabled then
		return
	end

	local sinceUpdate = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed = (elapsed + dt) % cycleLength
		sinceUpdate += dt
		if sinceUpdate >= 0.25 then
			sinceUpdate = 0
			local night = updateClock()
			if night ~= isNight then
				applyNight(night, 20) -- crépuscule / aube : 20 s de transition
			end
		end
	end)
end

return DayNight
