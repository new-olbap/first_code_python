-- Cycle jour/nuit : 20 minutes de jour (6h -> 18h), 10 minutes de nuit (18h -> 6h).
-- Les autres systèmes peuvent demander DayNight.isNight() ou écouter DayNight.NightChanged.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DayNight = {}

local nightChangedEvent = Instance.new("BindableEvent")
DayNight.NightChanged = nightChangedEvent.Event

local isNight = false

local DAY_AMBIENT = Color3.fromRGB(128, 128, 128)
local NIGHT_AMBIENT = Color3.fromRGB(25, 25, 40)

function DayNight.isNight()
	return isNight
end

local function applyNight(night)
	isNight = night
	ReplicatedStorage:SetAttribute("IsNight", night)
	Lighting.OutdoorAmbient = night and NIGHT_AMBIENT or DAY_AMBIENT
	nightChangedEvent:Fire(night)
end

function DayNight.start()
	local cfg = Config.DayNight
	local cycleLength = cfg.dayLength + cfg.nightLength

	-- t = temps écoulé dans le cycle. De 0 à dayLength c'est le jour.
	local t = (cfg.startClock - 6) / 12 * cfg.dayLength
	local sinceUpdate = 0

	applyNight(false)

	RunService.Heartbeat:Connect(function(dt)
		t = (t + dt) % cycleLength
		sinceUpdate += dt
		if sinceUpdate < 0.25 then
			return
		end
		sinceUpdate = 0

		local clock, night
		if t < cfg.dayLength then
			clock = 6 + 12 * t / cfg.dayLength
			night = false
		else
			clock = 18 + 12 * (t - cfg.dayLength) / cfg.nightLength
			night = true
		end
		Lighting.ClockTime = clock % 24

		if night ~= isNight then
			applyNight(night)
		end
	end)
end

return DayNight
