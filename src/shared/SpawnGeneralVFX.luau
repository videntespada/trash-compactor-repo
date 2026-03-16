--!strict
-- Spawns a VFX from ReplicatedStorage.Assets.GeneralVFX: clone the part by name,
-- position at cframe, parent to Ignore, emit all ParticleEmitters with EmitCount, then Debris.
-- Use for: TrashHit (HammerHit), Heal, Dash, etc.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DEFAULT_DURATION = 5

local function spawnGeneralVFX(name: string, cframe: CFrame, duration: number?): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local generalVFX = assets:FindFirstChild("GeneralVFX") :: Folder?
	if not generalVFX then
		return nil
	end
	local template = generalVFX:FindFirstChild(name)
	if not template then
		return nil
	end
	local clone = template:Clone()
	local ignore = Workspace:FindFirstChild("Ignore")
	if not ignore then
		clone:Destroy()
		return nil
	end
	if clone:IsA("Model") then
		clone:PivotTo(cframe)
	elseif clone:IsA("BasePart") then
		clone.CFrame = cframe
	end
	clone.Parent = ignore
	for _, desc in clone:GetDescendants() do
		if desc:IsA("ParticleEmitter") then
			local emitCount = desc:GetAttribute("EmitCount")
			if emitCount ~= nil then
				local n = type(emitCount) == "number" and emitCount or tonumber(tostring(emitCount))
				if n and n > 0 then
					desc:Emit(n)
				end
			end
		end
	end
	Debris:AddItem(clone, duration or DEFAULT_DURATION)
	return clone
end

return spawnGeneralVFX
