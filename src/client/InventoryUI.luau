-- Fenêtres d'inventaire et de fouille.
--   I : ouvrir / fermer l'inventaire (cases, objet choisi, armes et réparation)
--   H : utiliser un soin
-- Fouiller un conteneur (maintenir E) ouvre sa fenêtre à côté de l'inventaire.
-- Chaque bouton envoie une demande au serveur, qui vérifie et répond.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ItemDefs = require(ReplicatedStorage.Shared.ItemDefs)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WeaponDefs = require(ReplicatedStorage.Shared.WeaponDefs)
local InventoryClient = require(script.Parent.InventoryClient)

local InventoryUI = {}

local player = Players.LocalPlayer

local WeaponController
local gui: ScreenGui
local inventoryPanel: Frame, slotGrid: Frame, detail: Frame, weaponList: Frame
local detailTitle: TextLabel, detailText: TextLabel, detailButtons: Frame
local containerPanel: Frame, containerTitle: TextLabel, containerList: ScrollingFrame
local progressBar: Frame, progressFill: Frame, progressLabel: TextLabel

local selectedSlot: number? = nil
local openContainerId: number? = nil

local PANEL_COLOR = Color3.fromRGB(22, 24, 30)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(60, 140, 80)
local GREY = Color3.fromRGB(70, 72, 80)
local RED = Color3.fromRGB(150, 60, 60)

local function create(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function corner(parent: Instance, radius: number)
	create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function text(props: { [string]: any }, parent: Instance): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextSize = props.TextSize or 14
	return create("TextLabel", props, parent)
end

local function button(parent: Instance, label: string, color: Color3, onClick: () -> ()): TextButton
	local b = create("TextButton", {
		BackgroundColor3 = color,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Text = label,
		AutoButtonColor = true,
	}, parent)
	corner(b, 6)
	b.Activated:Connect(onClick)
	return b
end

local function clear(frame: Instance)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function updateMouse()
	WeaponController.setMouseFree("inventory", inventoryPanel.Visible or containerPanel.Visible)
end

local function costText(cost: { [string]: number }): string
	local parts = {}
	for id, amount in pairs(cost) do
		table.insert(parts, amount .. " " .. ItemDefs.Items[id].name)
	end
	return table.concat(parts, ", ")
end

local function canAfford(cost: { [string]: number }): boolean
	for id, amount in pairs(cost) do
		if InventoryClient.count(id) < amount then
			return false
		end
	end
	return true
end

-- INVENTAIRE ----------------------------------------------------------------------

local function refreshDetail()
	clear(detailButtons)
	local slot = selectedSlot and InventoryClient.slots[selectedSlot]
	if not slot then
		detailTitle.Text = "Choisis un objet"
		detailText.Text = "Clique sur une case pour voir ce que tu peux en faire."
		return
	end
	local def = ItemDefs.Items[slot.id]
	detailTitle.Text = def.name .. "  ×" .. slot.count
	detailTitle.TextColor3 = def.color:Lerp(WHITE, 0.4)
	local lines = { ItemDefs.Categories[def.category].name }
	if def.use then
		if def.use.hunger then
			table.insert(lines, "+" .. def.use.hunger .. " faim")
		end
		if def.use.thirst then
			table.insert(lines, "+" .. def.use.thirst .. " soif")
		end
		if def.use.heal then
			table.insert(lines, "+" .. def.use.heal .. " vie")
		end
		table.insert(lines, def.useTime .. " s")
	end
	detailText.Text = table.concat(lines, " · ")

	local index = selectedSlot
	if def.use then
		button(detailButtons, "Utiliser", GREEN, function()
			Remotes.InventoryAction:FireServer("use", index)
		end)
	end
	button(detailButtons, "Jeter 1", GREY, function()
		Remotes.InventoryAction:FireServer("drop", index, 1)
	end)
	button(detailButtons, "Jeter tout", RED, function()
		Remotes.InventoryAction:FireServer("drop", index)
	end)
end

local function refreshSlots()
	clear(slotGrid)
	for index = 1, InventoryClient.capacity do
		local slot = InventoryClient.slots[index]
		local def = slot and ItemDefs.Items[slot.id]
		local cell = create("TextButton", {
			BackgroundColor3 = if def then def.color:Lerp(Color3.new(0, 0, 0), 0.45) else Color3.fromRGB(40, 42, 50),
			BackgroundTransparency = if def then 0 else 0.3,
			Text = "",
			AutoButtonColor = def ~= nil,
			LayoutOrder = index,
		}, slotGrid)
		corner(cell, 6)
		if index == selectedSlot and def then
			create("UIStroke", { Color = WHITE, Thickness = 2 }, cell)
		end
		if def then
			text({ Size = UDim2.new(1, -4, 0.6, 0), Position = UDim2.fromOffset(2, 2), Text = def.short, TextSize = 11, TextWrapped = true }, cell)
			text({
				Size = UDim2.new(1, -6, 0.4, 0),
				Position = UDim2.new(0, 0, 0.6, -2),
				Text = "×" .. slot.count,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, cell)
			cell.Activated:Connect(function()
				selectedSlot = index
				refreshSlots()
			end)
		end
	end
	refreshDetail()
end

local function getWeapons(): { Tool }
	local tools = {}
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("WeaponId") then
					table.insert(tools, child)
				end
			end
		end
	end
	return tools
end

local function refreshWeapons()
	clear(weaponList)
	create("UIListLayout", { Padding = UDim.new(0, 6) }, weaponList)
	local tools = getWeapons()
	if #tools == 0 then
		text({ Size = UDim2.new(1, 0, 0, 20), Text = "Aucune arme", TextColor3 = Color3.fromRGB(160, 160, 160) }, weaponList)
	end
	for _, tool in ipairs(tools) do
		local weaponId = tool:GetAttribute("WeaponId") :: string
		local def = WeaponDefs.Weapons[weaponId]
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Color3.fromRGB(35, 37, 45) }, weaponList)
		corner(row, 6)
		local durability = (tool:GetAttribute("Durability") or 0) / def.maxDurability
		text({
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(1, -16, 0, 18),
			Text = def.name .. "  ·  état " .. math.floor(durability * 100) .. " %",
			TextColor3 = WeaponDefs.Rarities[def.rarity].color,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local buttons = create("Frame", { Position = UDim2.fromOffset(8, 26), Size = UDim2.new(1, -16, 0, 26), BackgroundTransparency = 1 }, row)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, buttons)
		local affordable = canAfford(def.repairCost)
		local repair = button(buttons, "Réparer (" .. costText(def.repairCost) .. ")", if affordable and durability < 1 then GREEN else GREY, function()
			Remotes.InventoryAction:FireServer("repair", weaponId)
		end)
		repair.Size = UDim2.new(0.72, 0, 1, 0)
		repair.TextScaled = true
		local drop = button(buttons, "Jeter", RED, function()
			Remotes.InventoryAction:FireServer("dropWeapon", weaponId)
		end)
		drop.Size = UDim2.new(0.25, 0, 1, 0)
	end
end

local function refreshInventory()
	if inventoryPanel.Visible then
		refreshSlots()
		refreshWeapons()
	end
end

function InventoryUI.toggle()
	inventoryPanel.Visible = not inventoryPanel.Visible
	selectedSlot = nil
	refreshInventory()
	updateMouse()
end

-- CONTENEUR -----------------------------------------------------------------------

local function closeContainer()
	if openContainerId then
		Remotes.ContainerAction:FireServer(openContainerId, "close")
	end
	openContainerId = nil
	containerPanel.Visible = false
	updateMouse()
end

local function showContainer(id: number?, title: string?, entries: { any }?)
	if not id or not entries then
		openContainerId = nil
		containerPanel.Visible = false
		updateMouse()
		return
	end
	openContainerId = id
	containerTitle.Text = title or "Conteneur"
	clear(containerList)
	create("UIListLayout", { Padding = UDim.new(0, 6) }, containerList)
	for index, entry in ipairs(entries) do
		local name, color
		if entry.kind == "weapon" then
			local def = WeaponDefs.Weapons[entry.id]
			name = def.name .. "  ·  état " .. math.floor(entry.durability * 100) .. " %"
			color = WeaponDefs.Rarities[def.rarity].color
		else
			local def = ItemDefs.Items[entry.id]
			name = def.name .. "  ×" .. entry.count
			color = def.color:Lerp(WHITE, 0.4)
		end
		local row = create("Frame", { Size = UDim2.new(1, -8, 0, 34), BackgroundColor3 = Color3.fromRGB(35, 37, 45) }, containerList)
		corner(row, 6)
		text({ Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -100, 1, 0), Text = name, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, row)
		local take = button(row, "Prendre", GREEN, function()
			Remotes.ContainerAction:FireServer(id, "take", index)
		end)
		take.AnchorPoint = Vector2.new(1, 0.5)
		take.Position = UDim2.new(1, -6, 0.5, 0)
		take.Size = UDim2.fromOffset(80, 24)
	end
	if #entries == 0 then
		text({ Size = UDim2.new(1, 0, 0, 24), Text = "Vide", TextColor3 = Color3.fromRGB(160, 160, 160) }, containerList)
	end
	containerPanel.Visible = true
	updateMouse()
end

-- BARRE DE PROGRESSION ------------------------------------------------------------

local progressVersion = 0
local function showProgress(name: string, duration: number)
	progressVersion += 1
	local version = progressVersion
	progressLabel.Text = name .. "..."
	progressFill.Size = UDim2.fromScale(0, 1)
	progressBar.Visible = true
	TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) }):Play()
	task.delay(duration + 0.1, function()
		if version == progressVersion then
			progressBar.Visible = false
		end
	end)
end

-- CONSTRUCTION ----------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", { Name = "InventoryUI", ResetOnSpawn = false, DisplayOrder = 5, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

	-- Inventaire
	inventoryPanel = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0.5, -8, 0.5, 0),
		Size = UDim2.fromOffset(440, 520),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.05,
		Visible = false,
	}, gui)
	corner(inventoryPanel, 10)
	text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 26), Text = "INVENTAIRE", TextSize = 18, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left }, inventoryPanel)
	text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 26), Text = "I pour fermer", TextSize = 12, TextColor3 = Color3.fromRGB(150, 150, 160), TextXAlignment = Enum.TextXAlignment.Right }, inventoryPanel)

	slotGrid = create("Frame", { Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -28, 0, 232), BackgroundTransparency = 1 }, inventoryPanel)
	create("UIGridLayout", { CellSize = UDim2.fromOffset(64, 54), CellPadding = UDim2.fromOffset(5, 5), SortOrder = Enum.SortOrder.LayoutOrder }, slotGrid)

	detail = create("Frame", { Position = UDim2.fromOffset(14, 280), Size = UDim2.new(1, -28, 0, 72), BackgroundColor3 = Color3.fromRGB(32, 34, 42) }, inventoryPanel)
	corner(detail, 6)
	detailTitle = text({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 18), Text = "", TextXAlignment = Enum.TextXAlignment.Left }, detail)
	detailText = text({ Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -20, 0, 16), Text = "", TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(190, 190, 200), TextXAlignment = Enum.TextXAlignment.Left }, detail)
	detailButtons = create("Frame", { Position = UDim2.fromOffset(10, 42), Size = UDim2.new(1, -20, 0, 24), BackgroundTransparency = 1 }, detail)
	create("UIGridLayout", { CellSize = UDim2.fromOffset(110, 24), CellPadding = UDim2.fromOffset(6, 0) }, detailButtons)

	text({ Position = UDim2.fromOffset(14, 360), Size = UDim2.new(1, -28, 0, 20), Text = "ARMES", TextSize = 14, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left }, inventoryPanel)
	weaponList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 384),
		Size = UDim2.new(1, -28, 1, -394),
		BackgroundTransparency = 1,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, inventoryPanel)

	-- Conteneur fouillé
	containerPanel = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, 8, 0.5, 0),
		Size = UDim2.fromOffset(360, 360),
		BackgroundColor3 = PANEL_COLOR,
		BackgroundTransparency = 0.05,
		Visible = false,
	}, gui)
	corner(containerPanel, 10)
	containerTitle = text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 26), Text = "", TextSize = 18, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left }, containerPanel)
	containerList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 42),
		Size = UDim2.new(1, -28, 1, -92),
		BackgroundTransparency = 1,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, containerPanel)
	local footer = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.new(1, -28, 0, 32), BackgroundTransparency = 1 }, containerPanel)
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 1, 0), CellPadding = UDim2.fromOffset(8, 0) }, footer)
	button(footer, "Tout prendre", GREEN, function()
		if openContainerId then
			Remotes.ContainerAction:FireServer(openContainerId, "takeAll")
		end
	end)
	button(footer, "Fermer", GREY, closeContainer)

	-- Barre de progression (manger, boire, se soigner)
	progressBar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -160),
		Size = UDim2.fromOffset(260, 22),
		BackgroundColor3 = Color3.fromRGB(30, 30, 35),
		BackgroundTransparency = 0.2,
		Visible = false,
	}, gui)
	corner(progressBar, 6)
	progressFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 190, 110) }, progressBar)
	corner(progressFill, 6)
	progressLabel = text({ Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 2 }, progressBar)

	-- Bouton pour les écrans tactiles
	if UserInputService.TouchEnabled then
		local open = button(gui, "SAC", Color3.fromRGB(40, 42, 50), InventoryUI.toggle)
		open.AnchorPoint = Vector2.new(1, 0)
		open.Position = UDim2.new(1, -16, 0, 90)
		open.Size = UDim2.fromOffset(70, 34)
	end
end

function InventoryUI.start(weaponController)
	WeaponController = weaponController
	build()

	InventoryClient.Changed:Connect(refreshInventory)
	Remotes.ContainerOpen.OnClientEvent:Connect(showContainer)
	Remotes.UseProgress.OnClientEvent:Connect(showProgress)

	-- Les armes changent (ramassage, usure) : on rafraîchit la liste si elle est ouverte
	task.spawn(function()
		while true do
			task.wait(1)
			if inventoryPanel.Visible then
				refreshWeapons()
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.I then
			InventoryUI.toggle()
		elseif input.KeyCode == Enum.KeyCode.H then
			Remotes.InventoryAction:FireServer("quickHeal")
		elseif input.KeyCode == Enum.KeyCode.Escape and containerPanel.Visible then
			closeContainer()
		end
	end)

	player.CharacterAdded:Connect(function()
		inventoryPanel.Visible = false
		closeContainer()
	end)
end

return InventoryUI
