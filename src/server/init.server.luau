-- Point d'entrée du serveur : construit la carte, puis lance chaque système.
-- Chaque module a une seule responsabilité ; on les relie ici, dans un ordre précis.
-- Les modules se reçoivent les uns les autres au démarrage (pas de require croisés).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Remotes) -- crée les RemoteEvents en premier
local ZoneDefs = require(ReplicatedStorage.Shared.ZoneDefs)

local MapBuilder = require(script.MapBuilder)
local DayNight = require(script.DayNight)
local MonsterService = require(script.MonsterService)
local Projectiles = require(script.Projectiles)
local InventoryService = require(script.InventoryService)
local SurvivalService = require(script.SurvivalService)
local ResourceService = require(script.ResourceService)
local ContainerService = require(script.ContainerService)
local WeaponService = require(script.WeaponService)
local LootService = require(script.LootService)
local TestZone = require(script.TestZone)
local PlayerService = require(script.PlayerService)
local DebugService = require(script.DebugService)

-- On attend que la carte existe avant de faire apparaître les joueurs,
-- sinon ils tomberaient dans le vide.
Players.CharacterAutoLoads = false

local map = MapBuilder.build()

local deps = {
	DayNight = DayNight,
	MonsterService = MonsterService,
	Projectiles = Projectiles,
	InventoryService = InventoryService,
	SurvivalService = SurvivalService,
	ResourceService = ResourceService,
	ContainerService = ContainerService,
	WeaponService = WeaponService,
	LootService = LootService,
	DebugService = DebugService,
}

DayNight.start()
MonsterService.start(DayNight)
Projectiles.start()
InventoryService.start(deps)
SurvivalService.start(InventoryService)
ResourceService.start(InventoryService)
WeaponService.start(deps)
ContainerService.start(WeaponService, InventoryService)
LootService.start(map.lootSpots, ZoneDefs.Zones, WeaponService, InventoryService)
Projectiles.onLanded = LootService.dropArrow

-- Ce que la carte a préparé : conteneurs, arbres, buissons, lampadaires
for _, spot in ipairs(map.containers) do
	ContainerService.spawnContainer(spot.containerType, spot.cframe)
end
for _, attachment in ipairs(map.embeddedContainers) do
	ContainerService.makeSearchable(attachment, attachment:GetAttribute("ContainerType"))
end
for _, tree in ipairs(map.trees) do
	ResourceService.registerTree(tree)
end
for _, bush in ipairs(map.bushes) do
	ResourceService.registerBush(bush)
end
local function setStreetLights(on: boolean)
	for _, light in ipairs(map.streetLights) do
		light.Enabled = on
	end
end
DayNight.NightChanged:Connect(setStreetLights)
setStreetLights(DayNight.isNight())

TestZone.build(LootService, MonsterService)
PlayerService.start(deps)
DebugService.start(deps)

Players.CharacterAutoLoads = true
for _, player in ipairs(Players:GetPlayers()) do
	if not player.Character then
		player:LoadCharacter()
	end
end

print("[Survie] Serveur prêt")
