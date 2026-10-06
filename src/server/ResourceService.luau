-- Ressources de la forêt : couper du bois en frappant les arbres avec une arme
-- blanche, et cueillir des baies sur les buissons. Les deux repoussent avec le temps.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)

local ResourceService = {}

local InventoryService
local rng = Random.new()
local cfg = GameConfig.Resources

local TREE_TAG = "Tree"
local WHITE = Color3.new(1, 1, 1)

function ResourceService.registerTree(tree: Model)
	CollectionService:AddTag(tree, TREE_TAG)
	tree:SetAttribute("Wood", cfg.treeWood)
end

-- Appelé par une arme blanche qui ne touche personne : y a-t-il un arbre devant ?
function ResourceService.tryHarvest(player: Player, root: BasePart, range: number, amount: number): boolean
	local best: Model?, bestDistance = nil, range + 2
	for _, tree in ipairs(CollectionService:GetTagged(TREE_TAG)) do
		local pivot = (tree :: Model):GetPivot().Position
		local offset = Vector3.new(pivot.X - root.Position.X, 0, pivot.Z - root.Position.Z)
		local distance = offset.Magnitude
		if distance < bestDistance and (distance < 1 or root.CFrame.LookVector:Dot(offset.Unit) > 0.3) then
			best, bestDistance = tree :: Model, distance
		end
	end
	if not best then
		return false
	end

	local wood = best:GetAttribute("Wood") or 0
	if wood <= 0 then
		Remotes.Notify:FireClient(player, "Cet arbre est épuisé, il repoussera", Color3.fromRGB(255, 200, 120))
		return true
	end
	local gained = math.min(amount, wood)
	local added = InventoryService.add(player, "Wood", gained)
	if added <= 0 then
		Remotes.Notify:FireClient(player, "Inventaire plein", Color3.fromRGB(255, 120, 120))
		return true
	end
	best:SetAttribute("Wood", wood - added)
	Remotes.Notify:FireClient(player, "+" .. added .. " bois", WHITE)
	SoundPlayer.playAt(root.Position + root.CFrame.LookVector * 3, "MeleeHit", 40)

	if wood - added <= 0 then
		local tree = best
		task.delay(cfg.treeRegrow, function()
			if tree.Parent then
				tree:SetAttribute("Wood", cfg.treeWood)
			end
		end)
	end
	return true
end

-- Buisson de baies : un ProximityPrompt "Cueillir"
function ResourceService.registerBush(bush: Model)
	local anchor = bush.PrimaryPart or bush:FindFirstChildWhichIsA("BasePart", true) :: BasePart
	local berries = bush:FindFirstChild("Berries")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Cueillir"
	prompt.ObjectText = "Buisson de baies"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local function setBerriesVisible(visible: boolean)
		if berries then
			for _, berry in ipairs(berries:GetDescendants()) do
				if berry:IsA("BasePart") then
					berry.Transparency = if visible then 0 else 1
				end
			end
		end
		prompt.Enabled = visible
	end

	prompt.Triggered:Connect(function(player)
		local amount = rng:NextInteger(cfg.berriesPerPick.min, cfg.berriesPerPick.max)
		local added = InventoryService.add(player, "Berries", amount)
		if added <= 0 then
			Remotes.Notify:FireClient(player, "Inventaire plein", Color3.fromRGB(255, 120, 120))
			return
		end
		Remotes.Notify:FireClient(player, "+" .. added .. " baies", WHITE)
		setBerriesVisible(false)
		task.delay(cfg.bushRegrow, setBerriesVisible, true)
	end)
end

function ResourceService.start(inventoryService)
	InventoryService = inventoryService
end

return ResourceService
