-- Réglages généraux du jeu. Les armes, monstres et zones ont leurs propres fichiers
-- (WeaponDefs, MonsterDefs, ZoneDefs). Chaque valeur "à équilibrer" est listée
-- dans docs/A_EQUILIBRER.md.

local GameConfig = {}

GameConfig.RespawnTime = 5 -- secondes avant de réapparaître
GameConfig.SpawnProtection = 3 -- secondes d'invincibilité après l'apparition
GameConfig.HeadshotMultiplier = 1.5

-- Inventaire (étape 2)
GameConfig.Inventory = {
	slots = 24, -- nombre de cases
	maxWeapons = 5, -- armes dans la barre d'outils (touches 1 à 5)
	interactDistance = 12, -- distance max pour prendre dans un conteneur
}

-- Faim et soif (étape 2, version légère : à tester, voir docs/A_EQUILIBRER.md)
GameConfig.Survival = {
	enabled = true,
	hungerDuration = 40 * 60, -- secondes pour passer de 100 à 0
	thirstDuration = 30 * 60,
	emptyDamage = 1, -- dégâts quand une jauge est vide...
	emptyDamageInterval = 2, -- ...toutes les N secondes
	wellFedThreshold = 70, -- au-dessus (faim ET soif), on regagne de la vie
	wellFedRegen = 0.5, -- vie par seconde
	respawnHunger = 80,
	respawnThirst = 80,
}

-- Ressources de la forêt
GameConfig.Resources = {
	treeWood = 30, -- bois dans un arbre avant qu'il soit épuisé
	treeRegrow = 300, -- secondes pour qu'un arbre épuisé se régénère
	berriesPerPick = { min = 2, max = 4 },
	bushRegrow = 150,
}

-- Butin au sol (en plus petite quantité que dans les conteneurs)
GameConfig.LootRespawnTime = 120 -- une arme ramassée réapparaît après ce délai
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
