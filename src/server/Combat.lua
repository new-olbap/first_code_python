-- Petites fonctions de combat partagées par les armes et les monstres.

local Players = game:GetService("Players")

local Combat = {}

-- Retrouve le Humanoid (joueur ou monstre) à partir d'une pièce touchée
function Combat.getHumanoidFromPart(part)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid, model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- Inflige des dégâts. attackerName sert à afficher "Tué par ..." à l'écran.
-- Renvoie true si la cible vient de mourir.
function Combat.damage(humanoid, amount, attackerName)
	if humanoid.Health <= 0 then
		return false
	end
	humanoid:SetAttribute("LastAttacker", attackerName)
	-- TakeDamage ne fait rien si la cible a un champ de force (protection d'apparition)
	humanoid:TakeDamage(amount)
	return humanoid.Health <= 0
end

-- Liste de toutes les cibles vivantes (joueurs et monstres), sauf "exclude"
function Combat.getTargets(exclude)
	local targets = {}
	local function consider(model)
		if model == exclude then
			return
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			table.insert(targets, model)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			consider(player.Character)
		end
	end
	local monsters = workspace:FindFirstChild("Monstres")
	if monsters then
		for _, monster in ipairs(monsters:GetChildren()) do
			consider(monster)
		end
	end
	return targets
end

return Combat
