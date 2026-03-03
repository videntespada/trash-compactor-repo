local Debris = game:GetService("Debris")

return {
	Cooldown = 3,
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

		-- ? 5 studs in front of player
		local character = player.Character
		if not character then
			return
		end

		local charPivot = character:GetPivot()
		local castOrigin = (charPivot * CFrame.new(0, 0, -5)).Position
		local castDirection = Vector3.new(0, -20, 0)

		local result = workspace:Raycast(castOrigin, castDirection, params)

		if result then
			local size = WallModel:GetExtentsSize()
			local hitPos = Vector3.new(result.Position.X, (result.Position.Y + (size.Y / 2)), result.Position.Z)
			local hitNormal = result.Normal

			-- ? align Up vector to Surface Normal
			local forward = charPivot.LookVector
			local right = forward:Cross(hitNormal).Unit
			local actualForward = hitNormal:Cross(right).Unit

			local finalCF = CFrame.fromMatrix(hitPos, right, hitNormal, -actualForward)

			-- ? Instance the wall
			local newWall = WallModel:Clone()
			newWall.Parent = workspace.Ignore
			newWall:PivotTo(finalCF)

			newWall:AddTag("WallObstacle")

			Debris:AddItem(newWall, 5)
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
