-- Liste des sons du jeu. Pour mettre un vrai son :
--   1. Dans Studio : Toolbox > Audio (ou Creator Store), trouve un son.
--   2. Copie son ID (le nombre dans l'adresse) et écris "rbxassetid://<ID>" ici.
-- Un son laissé vide ("") est simplement ignoré.
-- Les sons "rbxasset://" sont fournis avec Roblox Studio ; remplace-les si tu veux mieux.

local Sounds = {
	-- Armes à feu
	PistolShot = { id = "", volume = 0.8 },
	ShotgunShot = { id = "", volume = 1 },
	RifleShot = { id = "", volume = 0.7 },
	DryFire = { id = "", volume = 0.6 }, -- clic quand le chargeur est vide
	Reload = { id = "", volume = 0.6 },

	-- Arc
	BowShot = { id = "", volume = 0.6 },
	BowReload = { id = "", volume = 0.5 },
	ArrowHit = { id = "", volume = 0.6 },

	-- Armes blanches
	MeleeSwing = { id = "rbxasset://sounds/swordslash.wav", volume = 0.6 },
	MeleeSwingHeavy = { id = "rbxasset://sounds/swordslash.wav", volume = 0.8, pitch = 0.7 },
	MeleeHit = { id = "", volume = 0.7 },

	-- Retours de touche (joués seulement pour l'attaquant)
	HitMarker = { id = "", volume = 0.5 },
	KillMarker = { id = "", volume = 0.7 },

	-- Rôdeur
	ProwlerAlert = { id = "", volume = 0.9 },
	ProwlerAttack = { id = "", volume = 0.8 },
	ProwlerDeath = { id = "", volume = 0.8 },

	-- Joueur
	PlayerHurt = { id = "", volume = 0.6 },
	Pickup = { id = "", volume = 0.5 },
	WeaponBreak = { id = "", volume = 0.8 },
}

return Sounds
