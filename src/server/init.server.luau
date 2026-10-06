-- Point d'entrée du serveur : construit la carte, puis lance chaque système.
-- Chaque module a une seule responsabilité ; on les relie ici, dans un ordre précis.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Remotes) -- crée les RemoteEvents en premier
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)

local MapBuilder = require(script.MapBuilder)
local DayNight = require(script.DayNight)
local MonsterService = require(script.MonsterService)
local Projectiles = require(script.Projectiles)
local WeaponService = require(script.WeaponService)
local LootService = require(script.LootService)
local TestZone = require(script.TestZone)
local PlayerService = require(script.PlayerService)
local DebugService = require(script.DebugService)

-- On attend que la carte existe avant de faire apparaître les joueurs,
-- sinon ils tomberaient dans le vide.
Players.CharacterAutoLoads = false

local lootSpots = MapBuilder.build()

DayNight.start()
MonsterService.start(DayNight)
Projectiles.start()
WeaponService.start(MonsterService, Projectiles)
LootService.start(lootSpots, ZoneDefs.Zones, WeaponService)
Projectiles.onLanded = LootService.dropArrow
TestZone.build(LootService, MonsterService)
PlayerService.start(WeaponService, LootService, DebugService)
DebugService.start(WeaponService, MonsterService, DayNight)

Players.CharacterAutoLoads = true
for _, player in ipairs(Players:GetPlayers()) do
	if not player.Character then
		player:LoadCharacter()
	end
end

print("[Survie] Serveur prêt")
