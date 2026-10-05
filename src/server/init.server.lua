-- Point d'entrée du serveur : construit la carte puis lance chaque système.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.MapBuilder)
local DayNight = require(script.DayNight)
local MonsterService = require(script.MonsterService)
local WeaponService = require(script.WeaponService)
local LootService = require(script.LootService)

-- On attend que la carte existe avant de faire apparaître les joueurs,
-- sinon ils tomberaient dans le vide.
Players.CharacterAutoLoads = false
Players.RespawnTime = Config.RespawnTime

local map = MapBuilder.build()

DayNight.start()
MonsterService.start(DayNight)
WeaponService.start(MonsterService)
LootService.start(map.lootSpots, WeaponService)

Players.CharacterAutoLoads = true
for _, player in ipairs(Players:GetPlayers()) do
	if not player.Character then
		player:LoadCharacter()
	end
end

print("[Survie] Serveur prêt")
