-- Projectiles côté serveur (flèches). Chaque flèche avance un peu à chaque frame,
-- avec de la gravité ; un raycast entre l'ancienne et la nouvelle position détecte
-- les touches. Les flèches qui ratent se plantent et peuvent être ramassées.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ballistics = require(ReplicatedStorage.Shared.Ballistics)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local Combat = require(script.Parent.Combat)

local Projectiles = {}

local MAX_LIFETIME = 4

type Projectile = {
	owner: Player,
	position: Vector3,
	velocity: Vector3,
	gravity: number,
	damage: number,
	weaponName: string,
	params: RaycastParams,
	age: number,
}

local active: { Projectile } = {}

-- Appelé quand une flèche se plante dans le décor (branché par init.server)
Projectiles.onLanded = function(_cframe: CFrame) end

function Projectiles.fire(spec)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = spec.ignore
	table.insert(active, {
		owner = spec.owner,
		position = spec.origin,
		velocity = spec.velocity,
		gravity = spec.gravity,
		damage = spec.damage,
		weaponName = spec.weaponName,
		params = params,
		age = 0,
	})
end

local function onImpact(projectile: Projectile, result: RaycastResult)
	SoundPlayer.playAt(result.Position, "ArrowHit", 40)

	local humanoid = Combat.getHumanoidFromPart(result.Instance)
	if humanoid then
		if humanoid.Health <= 0 then
			return
		end
		local headshot = result.Instance.Name == "Head"
		local damage = projectile.damage * (if headshot then GameConfig.HeadshotMultiplier else 1)
		local dealt, killed = Combat.damage(humanoid, damage, {
			name = projectile.owner.DisplayName,
			position = projectile.position,
			weaponName = projectile.weaponName,
		})
		if dealt > 0 and projectile.owner.Parent then
			Remotes.HitConfirmed:FireClient(projectile.owner, {
				{ position = result.Position, damage = dealt, headshot = headshot, killed = killed },
			}, "arrow")
		end
		return
	end

	-- Raté : la flèche se plante dans le décor, pointe vers l'avant
	local direction = projectile.velocity.Unit
	Projectiles.onLanded(CFrame.lookAt(result.Position - direction * 0.8, result.Position + direction))
end

function Projectiles.start()
	RunService.Heartbeat:Connect(function(dt)
		for index = #active, 1, -1 do
			local projectile = active[index]
			local newPosition, newVelocity = Ballistics.step(projectile.position, projectile.velocity, projectile.gravity, dt)
			local result = workspace:Raycast(projectile.position, newPosition - projectile.position, projectile.params)
			projectile.age += dt
			if result then
				table.remove(active, index)
				onImpact(projectile, result)
			elseif projectile.age > MAX_LIFETIME or newPosition.Y < -50 then
				table.remove(active, index)
			else
				projectile.position = newPosition
				projectile.velocity = newVelocity
			end
		end
	end)
end

return Projectiles
