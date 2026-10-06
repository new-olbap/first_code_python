-- Dégâts et recherche de cibles, partagés par les armes et les monstres.
-- Tous les dégâts du jeu passent par Combat.damage : c'est le seul endroit
-- à modifier pour ajouter plus tard l'armure, la réputation, les primes...

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Combat = {}

export type DamageSource = {
	name: string, -- affiché sur l'écran de mort : "Tué par ..."
	position: Vector3?, -- d'où vient le coup (indicateur de direction pour la victime)
	weaponName: string?,
}

local targetFolders: { Instance } = {}

-- Les dossiers de PNJ (monstres, mannequins) que les armes blanches peuvent frapper
function Combat.registerTargetFolder(folder: Instance)
	table.insert(targetFolders, folder)
end

-- Retrouve le Humanoid (joueur, monstre, mannequin) à partir d'une pièce touchée
function Combat.getHumanoidFromPart(part: Instance): (Humanoid?, Model?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid, model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

-- Renvoie le Humanoid et la HumanoidRootPart d'un personnage s'il est vivant
function Combat.getAlive(model: Model?): (Humanoid?, BasePart?)
	if not model or not model.Parent then
		return nil, nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.Health > 0 then
		return humanoid, root
	end
	return nil, nil
end

-- Inflige des dégâts. Renvoie (dégâts réellement infligés, cible tuée ?)
function Combat.damage(humanoid: Humanoid, amount: number, source: DamageSource): (number, boolean)
	if humanoid.Health <= 0 or humanoid:GetAttribute("GodMode") then
		return 0, false
	end
	local character = humanoid.Parent
	if character and character:FindFirstChildOfClass("ForceField") then
		return 0, false -- protection d'apparition
	end

	local label = source.name
	if source.weaponName then
		label ..= " (" .. source.weaponName .. ")"
	end
	humanoid:SetAttribute("LastAttacker", label)

	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	local dealt = before - humanoid.Health

	local victim = character and Players:GetPlayerFromCharacter(character)
	if victim and source.position then
		Remotes.DamageTaken:FireClient(victim, source.position, dealt)
	end
	return dealt, humanoid.Health <= 0
end

-- Toutes les cibles vivantes (joueurs et PNJ), sauf "exclude"
function Combat.getTargets(exclude: Instance?): { Model }
	local targets = {}
	local function consider(model: Instance)
		if model ~= exclude and model:IsA("Model") and Combat.getAlive(model) then
			table.insert(targets, model)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			consider(player.Character)
		end
	end
	for _, folder in ipairs(targetFolders) do
		for _, model in ipairs(folder:GetChildren()) do
			consider(model)
		end
	end
	return targets
end

return Combat
