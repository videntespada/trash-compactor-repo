local Debris = game:GetService("Debris")

local COOLDOWN = 12
local DURATION = 4 -- static wall lifetime, protects team
local CAST_DISTANCE = 5 -- studs in front of player
local CAST_DOWN = 20
local SFX_WALL_ACTIVATE = "rbxassetid://124295521576078"

return {
	Cooldown = COOLDOWN,
	init = function(player: Player, AssetFolder: Folder)
		local WallModel = AssetFolder:FindFirstChild("Wall") :: Model
		local Map = workspace:WaitForChild("Map") :: Folder

		local filterTable = {}
		for _, v in ipairs(Map:GetDescendants()) do
			if v:IsA("Part") or v:IsA("MeshPart") then
				filterTable[#filterTable + 1] = v
			end
		end

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = filterTable
		params.FilterType = Enum.RaycastFilterType.Include

		local character = player.Character
		if not character then
			return
		end

		local charPivot = character:GetPivot()
		local castOrigin = (charPivot * CFrame.new(0, 0, -CAST_DISTANCE)).Position
		local castDirection = Vector3.new(0, -CAST_DOWN, 0)

		local result = workspace:Raycast(castOrigin, castDirection, params)

		if result then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local sound = Instance.new("Sound")
				sound.SoundId = SFX_WALL_ACTIVATE
				sound.Volume = 1
				sound.Parent = root
				sound:Play()
				Debris:AddItem(sound, 3)
			end
			local size = WallModel:GetExtentsSize()
			local hitPos = Vector3.new(result.Position.X, (result.Position.Y + (size.Y / 2)), result.Position.Z)
			local hitNormal = result.Normal

			local forward = charPivot.LookVector
			local right = forward:Cross(hitNormal).Unit
			local actualForward = hitNormal:Cross(right).Unit

			local finalCF = CFrame.fromMatrix(hitPos, right, hitNormal, -actualForward)

			local newWall = WallModel:Clone()
			newWall.Parent = workspace.Ignore
			newWall:PivotTo(finalCF)
			newWall:AddTag("WallObstacle")

			Debris:AddItem(newWall, DURATION)
		end

		local Humanoid = character:FindFirstChildOfClass("Humanoid")
		local Animator = Humanoid:FindFirstChildOfClass("Animator")
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://119753565288451"
		anim.Parent = character
		local animation = Animator:LoadAnimation(anim)
		animation.Looped = false
		animation:Play(0)
	end,
}
