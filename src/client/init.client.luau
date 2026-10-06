-- Point d'entrée du client (tourne sur l'ordinateur ou le téléphone de chaque joueur).

local Effects = require(script.Effects)
local Hud = require(script.Hud)
local WeaponController = require(script.WeaponController)
local DebugPanel = require(script.DebugPanel)

Effects.start()
Hud.start()
WeaponController.start(Hud)
DebugPanel.start(WeaponController)
