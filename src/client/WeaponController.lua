-- Contrôles des armes : clic pour attaquer (maintenir pour les armes automatiques),
-- R pour recharger. Le client demande, le serveur décide.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local WeaponController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local equipped = nil -- { tool = ..., cfg = ... }
local holding = false
local lastAttack = 0
local toolConnections = {}

local GUN_CURSOR = "rbxasset://textures/GunCursor.png"

local function requestReload()
	if not equipped or equipped.cfg.kind ~= "gun" then
		return
	end
	local tool, cfg = equipped.tool, equipped.cfg
	if tool:GetAttribute("Reloading") then
		return
	end
	if tool:GetAttribute("Ammo") < cfg.magazine and tool:GetAttribute("Reserve") > 0 then
		Remotes.Reload:FireServer()
	end
end

local function attackOnce()
	if not equipped then
		return
	end
	local tool, cfg = equipped.tool, equipped.cfg
	local now = os.clock()
	if now - lastAttack < cfg.cooldown or tool:GetAttribute("Reloading") then
		return
	end
	if cfg.kind == "gun" and tool:GetAttribute("Ammo") <= 0 then
		requestReload()
		return
	end
	lastAttack = now
	Remotes.Fire:FireServer(mouse.Hit.Position)
end

local function onActivated()
	holding = true
	attackOnce()
	if equipped and equipped.cfg.automatic then
		local current = equipped
		task.spawn(function()
			while holding and equipped == current do
				attackOnce()
				task.wait(0.03)
			end
		end)
	end
end

local function onEquipped(tool)
	local weaponId = tool:GetAttribute("WeaponId")
	local cfg = weaponId and Config.Weapons[weaponId]
	if not cfg then
		return
	end
	equipped = { tool = tool, cfg = cfg }
	mouse.Icon = cfg.kind == "gun" and GUN_CURSOR or ""
	toolConnections[tool] = {
		tool.Activated:Connect(onActivated),
		tool.Deactivated:Connect(function()
			holding = false
		end),
	}
end

local function onUnequipped(tool)
	for _, connection in ipairs(toolConnections[tool] or {}) do
		connection:Disconnect()
	end
	toolConnections[tool] = nil
	if equipped and equipped.tool == tool then
		equipped = nil
		holding = false
		mouse.Icon = ""
	end
end

local function onCharacterAdded(character)
	equipped = nil
	holding = false
	mouse.Icon = ""
	mouse.TargetFilter = character
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onEquipped(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onUnequipped(child)
		end
	end)
end

-- Pour le HUD : l'arme actuellement tenue
function WeaponController.getEquipped()
	return equipped
end

function WeaponController.start(hud)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.R then
			requestReload()
		end
	end)

	Remotes.HitConfirmed.OnClientEvent:Connect(function(killed)
		hud.showHitMarker(killed)
	end)

	hud.setEquippedGetter(WeaponController.getEquipped)
	hud.onReloadPressed(requestReload)
end

return WeaponController
