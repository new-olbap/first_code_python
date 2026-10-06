-- Point d'entrée du client (tourne sur l'ordinateur ou le téléphone de chaque joueur).

local Effects = require(script.Effects)
local InventoryClient = require(script.InventoryClient)
local Hud = require(script.Hud)
local WeaponController = require(script.WeaponController)
local InventoryUI = require(script.InventoryUI)
local DebugPanel = require(script.DebugPanel)

Effects.start()
InventoryClient.start()
Hud.start()
WeaponController.start(Hud)
InventoryUI.start(WeaponController)
DebugPanel.start(WeaponController)
