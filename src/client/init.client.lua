-- Point d'entrée du client (tourne sur l'ordinateur ou le téléphone de chaque joueur).

local Hud = require(script.Hud)
local Effects = require(script.Effects)
local WeaponController = require(script.WeaponController)

Hud.start()
Effects.start()
WeaponController.start(Hud)
