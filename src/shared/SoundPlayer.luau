-- Joue les sons listés dans Sounds.luau. Utilisable côté serveur (tout le monde entend)
-- et côté client (seul ce joueur entend). Un son sans ID est ignoré.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage.Shared.Sounds)

local SoundPlayer = {}

local function makeSound(key: string): Sound?
	local info = Sounds[key]
	if not info or info.id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = info.id
	sound.Volume = info.volume or 0.5
	sound.PlaybackSpeed = info.pitch or 1
	return sound
end

-- Son 3D attaché à un objet : on l'entend de moins en moins loin
function SoundPlayer.playOn(parent: Instance, key: string, maxDistance: number?)
	local sound = makeSound(key)
	if not sound then
		return
	end
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = maxDistance or 120
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 6)
end

-- Son 3D à une position dans le monde
function SoundPlayer.playAt(position: Vector3, key: string, maxDistance: number?)
	if not Sounds[key] or Sounds[key].id == "" then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldPosition = position
	SoundPlayer.playOn(attachment, key, maxDistance)
	Debris:AddItem(attachment, 6)
end

-- Son "dans la tête" du joueur (client uniquement) : marqueur de touche, clic à vide...
function SoundPlayer.play2D(key: string)
	local sound = makeSound(key)
	if not sound then
		return
	end
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	Debris:AddItem(sound, 6)
end

return SoundPlayer
