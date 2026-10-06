-- Définitions des monstres. Pour l'étape 1, un seul type : le Rôdeur.
-- Ajouter un monstre = ajouter une entrée ici (le comportement reste celui du Rôdeur
-- tant qu'on n'a pas codé d'autres comportements aux étapes suivantes).

local MonsterDefs = {}

MonsterDefs.Prowler = {
	name = "Rôdeur",
	assetName = "Prowler", -- ReplicatedStorage/Assets/Monsters/Prowler
	health = 60,
	walkSpeed = 15, -- en poursuite (le joueur court à 16 : on peut fuir, de justesse)
	wanderSpeed = 5,
	damage = 12,
	attackRange = 4.5, -- distance à laquelle il commence son attaque
	attackReach = 6, -- distance à laquelle l'attaque touche encore à la fin de l'élan
	attackWindup = 0.45, -- temps d'élan visible avant le coup : on peut esquiver
	attackCooldown = 1.3,
	sightRange = 35, -- il voit un joueur à cette distance (s'il n'y a pas de mur)
	hearingMultiplier = 1, -- multiplie le rayon de bruit des armes
	alertRadius = 40, -- en repérant un joueur, il alerte son groupe dans ce rayon
	giveUpDistance = 90, -- il abandonne la poursuite au-delà
	investigateTime = 15, -- secondes passées à chercher la source d'un bruit
	wanderRadius = 25,
	groupSize = { min = 2, max = 4 },
	skinColor = Color3.fromRGB(120, 150, 95),
	clothesColor = Color3.fromRGB(70, 60, 50),
	sounds = { alert = "ProwlerAlert", attack = "ProwlerAttack", death = "ProwlerDeath" },
}

return MonsterDefs
