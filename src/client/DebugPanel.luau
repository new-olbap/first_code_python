-- Panneau de debug (touche F2, ou bouton DEBUG sur mobile) pour tester vite :
-- donner une arme, faire venir des Rôdeurs, changer l'heure, se téléporter...
-- Il n'apparaît que si le serveur a autorisé le joueur (attribut DebugAllowed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)

local DebugPanel = {}

local player = Players.LocalPlayer

local function makeButton(parent: Instance, text: string, color: Color3, onClick: () -> ())
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextWrapped = true
	button.Text = text
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	button.Activated:Connect(onClick)
end

local function build(weaponController)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 16, 0.5, 0)
	panel.Size = UDim2.fromOffset(330, 470)
	panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panel.BackgroundTransparency = 0.1
	panel.Visible = false
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 32)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(120, 220, 255)
	title.Text = "DEBUG (F2 pour fermer)"
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(10, 36)
	list.Size = UDim2.new(1, -20, 1, -46)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(148, 36)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.Parent = list

	local function send(action: string, argument: any?)
		Remotes.Debug:FireServer(action, argument)
	end

	local weaponColor = Color3.fromRGB(70, 90, 140)
	for _, weaponId in ipairs(WeaponDefs.Order) do
		makeButton(list, WeaponDefs.Weapons[weaponId].name, weaponColor, function()
			send("give", weaponId)
		end)
	end

	local actionColor = Color3.fromRGB(60, 120, 80)
	local dangerColor = Color3.fromRGB(150, 60, 60)
	makeButton(list, "3 Rôdeurs devant moi", dangerColor, function()
		send("prowlers", 3)
	end)
	makeButton(list, "Supprimer les monstres", dangerColor, function()
		send("killMonsters")
	end)
	makeButton(list, "Soigner", actionColor, function()
		send("heal")
	end)
	makeButton(list, "Réparer + munitions", actionColor, function()
		send("refill")
	end)
	makeButton(list, "Kit de survie", actionColor, function()
		send("kit")
	end)
	makeButton(list, "Faim/soif au minimum", dangerColor, function()
		send("starve")
	end)
	makeButton(list, "Faim/soif à 100", actionColor, function()
		send("feed")
	end)
	makeButton(list, "Usure à 20 %", actionColor, function()
		send("wear")
	end)
	makeButton(list, "Mode dieu", actionColor, function()
		send("god")
	end)
	makeButton(list, "Jour", Color3.fromRGB(150, 130, 50), function()
		send("day")
	end)
	makeButton(list, "Nuit", Color3.fromRGB(60, 60, 130), function()
		send("night")
	end)
	makeButton(list, "TP départ", Color3.fromRGB(90, 90, 90), function()
		send("teleport", "spawn")
	end)
	makeButton(list, "TP ville", Color3.fromRGB(90, 90, 90), function()
		send("teleport", "town")
	end)
	makeButton(list, "TP zone de test", Color3.fromRGB(90, 90, 90), function()
		send("teleport", "test")
	end)

	local function toggle()
		panel.Visible = not panel.Visible
		weaponController.setMouseFree("debug", panel.Visible)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
			toggle()
		end
	end)

	-- Bouton pour les écrans tactiles
	if UserInputService.TouchEnabled then
		local open = Instance.new("TextButton")
		open.AnchorPoint = Vector2.new(0, 0)
		open.Position = UDim2.fromOffset(16, 90)
		open.Size = UDim2.fromOffset(70, 30)
		open.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
		open.TextColor3 = Color3.fromRGB(120, 220, 255)
		open.Font = Enum.Font.GothamBold
		open.TextSize = 13
		open.Text = "DEBUG"
		open.Parent = gui
		open.Activated:Connect(toggle)
	end
end

function DebugPanel.start(weaponController)
	if player:GetAttribute("DebugAllowed") then
		build(weaponController)
		return
	end
	-- L'autorisation peut arriver juste après le chargement
	local connection
	connection = player:GetAttributeChangedSignal("DebugAllowed"):Connect(function()
		if player:GetAttribute("DebugAllowed") then
			connection:Disconnect()
			build(weaponController)
		end
	end)
end

return DebugPanel
