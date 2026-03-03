local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return function(BombModel: Model, character: Model, Map: Folder, endPos)
	local copiedModel = BombModel:Clone() :: Model
	copiedModel.Parent = workspace:FindFirstChild("Ignore")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local function doEmit()
		for _, item in ipairs(copiedModel:GetDescendants()) do
			if item:IsA("ParticleEmitter") then
				item:Emit(item:GetAttribute("EmitCount"))
			end
		end
	end

	local function getQuadraticBezier(t, p0, p1, p2)
		return (1 - t) ^ 2 * p0 + 2 * (1 - t) * t * p1 + t ^ 2 * p2
	end

	local startPos = rootPart.CFrame
	local controlPos

	-- 5 studs above midway
	controlPos = startPos:Lerp(endPos, 0.5) * CFrame.new(0, 5, 0)

	local resolution = 25

	copiedModel:PivotTo(startPos)

	for i = 1, resolution do
		local t = i / resolution
		local pos = CFrame.new(getQuadraticBezier(t, startPos.Position, controlPos.Position, endPos.Position))

		copiedModel:PivotTo(copiedModel:GetPivot():Lerp(pos, 0.5))
		task.wait()
	end

	-- Add to GC, show particles and make it look invisible
	Debris:AddItem(copiedModel, 4)
	doEmit()
	for _, v in ipairs(copiedModel:GetDescendants()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.Transparency = 1
		end
	end

	EventHandler:fire("onBombFinish")
end
