local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local isSimilar = require(ReplicatedStorage.Shared.Fusion.Utility.isSimilar)
return {
	Cooldown = 5,
	init = function(player: Player, AssetFolder: Folder)
		local Map = workspace:WaitForChild("Map") :: Folder
		local BombModel = AssetFolder:FindFirstChild("Bomb") :: Model
		local character = player.Character
		if not character then
			return
		end

		local startPos = character:FindFirstChild("HumanoidRootPart").CFrame
		local endPos

		-- find the end position
		local filterTable = {}
		for _, v in ipairs(Map:GetDescendants()) do
			if v:IsA("Part") or v:IsA("MeshPart") then
				filterTable[#filterTable+1] = v
			end
		end
		local raycastFrom = (startPos * CFrame.new(0, 0, -10)).Position
		local raycastDir = Vector3.yAxis * -99
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = filterTable
		local posRay = workspace:Raycast(raycastFrom, raycastDir, params)

		if posRay then
			local _, size = BombModel:GetBoundingBox()
			endPos = CFrame.new(posRay.Position.X, posRay.Position.Y + size.Y / 2, posRay.Position.Z)
		else
			-- Default to raycastFrom
			endPos = raycastFrom
		end

		local Humanoid = character:FindFirstChildOfClass("Humanoid")
		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://91380500276956"
		anim.Parent = character
		local animation = Animator:LoadAnimation(anim)
		animation.Looped = false
		animation:Play(0)

		local finalPos: Vector3
		if typeof(endPos) == "CFrame" then
			finalPos = endPos.Position
		else
			finalPos = endPos
		end

		ServerEvents.sendBombLocation:Fire(endPos)
		EventHandler:broadcast("bombVFX", BombModel, player.Character, Map, endPos)
	end,
}
