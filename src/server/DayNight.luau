-- Cycle jour/nuit : jour de 6h à 18h, nuit de 18h à 6h (durées dans GameConfig).
-- Les autres systèmes demandent DayNight.isNight() ou écoutent DayNight.NightChanged.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DayNight = {}

local nightChangedEvent = Instance.new("BindableEvent")
DayNight.NightChanged = nightChangedEvent.Event

local cfg = GameConfig.DayNight
local cycleLength = cfg.dayLength + cfg.nightLength
local elapsed = (cfg.startClock - 6) / 12 * cfg.dayLength -- temps écoulé dans le cycle
local isNight = false

local DAY_AMBIENT = Color3.fromRGB(128, 128, 128)
local NIGHT_AMBIENT = Color3.fromRGB(25, 25, 45)

function DayNight.isNight(): boolean
	return isNight
end

local function applyNight(night: boolean)
	isNight = night
	ReplicatedStorage:SetAttribute("IsNight", night)
	Lighting.OutdoorAmbient = if night then NIGHT_AMBIENT else DAY_AMBIENT
	nightChangedEvent:Fire(night)
end

local function updateClock()
	local clock, night
	if elapsed < cfg.dayLength then
		clock = 6 + 12 * elapsed / cfg.dayLength
		night = false
	else
		clock = 18 + 12 * (elapsed - cfg.dayLength) / cfg.nightLength
		night = true
	end
	Lighting.ClockTime = clock % 24
	if night ~= isNight then
		applyNight(night)
	end
end

-- Debug : saute au début du jour (8h) ou de la nuit (20h)
function DayNight.skipTo(night: boolean)
	if night then
		elapsed = cfg.dayLength + cfg.nightLength / 6
	else
		elapsed = cfg.dayLength / 6
	end
	updateClock()
end

function DayNight.start()
	applyNight(false)
	updateClock()
	if not cfg.enabled then
		return
	end

	local sinceUpdate = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed = (elapsed + dt) % cycleLength
		sinceUpdate += dt
		if sinceUpdate >= 0.25 then
			sinceUpdate = 0
			updateClock()
		end
	end)
end

return DayNight
