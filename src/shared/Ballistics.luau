-- Calculs de tir partagés par le client et le serveur, pour que les deux
-- voient exactement la même dispersion et la même trajectoire de flèche.

local Ballistics = {}

-- Tourne une direction au hasard dans un cône de "degrees" degrés
function Ballistics.applySpread(direction: Vector3, degrees: number, rng: Random): Vector3
	if degrees <= 0 then
		return direction
	end
	-- racine carrée : les balles se répartissent dans tout le cône, pas seulement au centre
	local angle = math.rad(degrees * math.sqrt(rng:NextNumber()))
	local roll = rng:NextNumber(0, 2 * math.pi)
	local frame = CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, 0, roll) * CFrame.Angles(angle, 0, 0)
	return frame.LookVector
end

-- Fait avancer un projectile de dt secondes (gravité simple)
function Ballistics.step(position: Vector3, velocity: Vector3, gravity: number, dt: number): (Vector3, Vector3)
	local newVelocity = velocity - Vector3.new(0, gravity * dt, 0)
	local newPosition = position + (velocity + newVelocity) * 0.5 * dt
	return newPosition, newVelocity
end

return Ballistics
