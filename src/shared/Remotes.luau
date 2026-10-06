-- Les RemoteEvents permettent au client (le joueur) et au serveur de se parler.
-- Le serveur les crée, le client attend qu'ils existent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Attack", -- client -> serveur : "j'attaque" (+ directions des balles pour les armes à feu)
	"Reload", -- client -> serveur : "je recharge"
	"WeaponFx", -- serveur -> autres joueurs : afficher un tir, un coup, une flèche
	"HitConfirmed", -- serveur -> attaquant : liste des touches (marqueur + chiffres de dégâts)
	"DamageTaken", -- serveur -> victime : d'où vient le coup (indicateur de direction)
	"Notify", -- serveur -> joueur : petit message à l'écran
	"Debug", -- client -> serveur : actions du panneau de debug
}

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
	end
	for _, name in ipairs(NAMES) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		Remotes[name] = remote
	end
	folder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in ipairs(NAMES) do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
