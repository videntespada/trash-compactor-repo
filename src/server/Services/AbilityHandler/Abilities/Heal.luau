local Debris = game:GetService("Debris")
return {
	Cooldown = 3,
	init = function(player: Player, AssetFolder: Folder)
		local character = player.Character
		if not character then
			return
		end

		local HealPart = (AssetFolder:FindFirstChild("Heal") :: Instance):Clone() :: Part
		HealPart.Parent = workspace:FindFirstChild("Ignore")
		HealPart.CFrame = character:GetPivot()
		local _, size = character:GetBoundingBox()
		HealPart.Size = size

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = character:FindFirstChild("HumanoidRootPart")
		weld.Part1 = HealPart
		weld.Parent = HealPart

		local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
		Humanoid.Health += 20

		Debris:AddItem(HealPart, 5)
	end,
}
