-- Charge un objet par son nom depuis ReplicatedStorage/Assets/<Catégorie>/<Nom>.
-- Si le modèle n'existe pas, on utilise le placeholder fourni (formes simples).
-- Pour remplacer un placeholder par un vrai modèle : glisse un modèle portant
-- exactement ce nom dans le bon dossier. Aucun code à changer (voir docs/ASSETS.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = {}

local warned = {}

local function findAsset(category: string, name: string): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild(category)
	return folder and folder:FindFirstChild(name)
end

-- Renvoie une copie de l'asset (ou du placeholder) et true si c'est un vrai modèle
function AssetLoader.get(category: string, name: string, buildPlaceholder: () -> Instance): (Instance, boolean)
	local asset = findAsset(category, name)
	if asset then
		return asset:Clone(), true
	end
	local key = category .. "/" .. name
	if not warned[key] then
		warned[key] = true
		print("[Assets] Placeholder utilisé pour " .. key)
	end
	return buildPlaceholder(), false
end

function AssetLoader.has(category: string, name: string): boolean
	return findAsset(category, name) ~= nil
end

return AssetLoader
