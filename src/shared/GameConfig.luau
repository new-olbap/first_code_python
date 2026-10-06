-- Réglages généraux du jeu. Les armes, monstres et zones ont leurs propres fichiers
-- (WeaponDefs, MonsterDefs, ZoneDefs). Chaque valeur "à équilibrer" est listée
-- dans docs/A_EQUILIBRER.md.

local GameConfig = {}

GameConfig.RespawnTime = 5 -- secondes avant de réapparaître
GameConfig.SpawnProtection = 3 -- secondes d'invincibilité après l'apparition
GameConfig.HeadshotMultiplier = 1.5

-- Butin au sol
GameConfig.LootRespawnTime = 90 -- une arme ramassée réapparaît après ce délai
GameConfig.LootDurability = { min = 0.55, max = 1 } -- état des armes trouvées (en % de l'usure max)

-- Sac lâché à la mort
GameConfig.BagLifetime = 300 -- secondes avant que le sac disparaisse
GameConfig.ArrowPickupLifetime = 60 -- une flèche plantée reste ramassable ce temps

-- Seuil d'usure : en dessous, l'arme devient moins précise
GameConfig.WornThreshold = 0.3
GameConfig.WornSpreadMultiplier = 1.6

-- Cycle jour/nuit (normalement prévu à l'étape 2, gardé car il rend les Rôdeurs plus tendus)
GameConfig.DayNight = {
	enabled = true,
	dayLength = 20 * 60,
	nightLength = 10 * 60,
	startClock = 8, -- heure au démarrage du serveur
}

-- La nuit, les monstres sont plus nombreux et plus forts
GameConfig.Night = {
	groupMultiplier = 2,
	healthMultiplier = 1.5,
	damageMultiplier = 1.4,
	speedMultiplier = 1.15,
	sightMultiplier = 1.3,
}

-- Limites pour garder un serveur fluide à 20-40 joueurs
GameConfig.Monsters = {
	maxActive = 40, -- jamais plus de monstres que ça sur la carte
	spawnInterval = 5, -- secondes entre deux vérifications de population
	minSpawnDistance = 60, -- pas d'apparition sous le nez d'un joueur
	sleepDistance = 250, -- au-delà, un monstre ne réfléchit plus (économie de calcul)
	aiTick = 0.25, -- secondes entre deux "réflexions" de l'IA
	corpseTime = 4,
}

-- Outils de test : panneau de debug (touche F2) et zone de test près du départ
GameConfig.Debug = {
	allowInStudio = true, -- tout le monde a le panneau quand on teste dans Studio
	allowCreator = true, -- le propriétaire du jeu l'a aussi en ligne
	adminUserIds = {}, -- ajoute ici les UserId de tes amis testeurs, ex. { 12345678 }
	testZoneEnabled = true, -- à passer à false avant la sortie publique
}

return GameConfig
