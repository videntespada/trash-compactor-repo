local AnimationFromVideoCreatorService = game:GetService("AnimationFromVideoCreatorService")
local Debris = game:GetService("Debris")
return {
	Cooldown = 3,
	init = function(player: Player, AssetFolder: Folder)
		local character = player.Character
		if not character then
			return
		end
		local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local Animator = Humanoid:FindFirstChildOfClass("Animator")

		-- Shield Aura Logic
		local ShieldAura = (AssetFolder:FindFirstChild("ShieldAura") :: Instance):Clone() :: Part
		ShieldAura.Parent = workspace:FindFirstChild("Ignore")
		ShieldAura.CFrame = character:GetPivot()
		local _, size = character:GetBoundingBox()
		ShieldAura.Size = size

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = character:FindFirstChild("HumanoidRootPart")
		weld.Part1 = ShieldAura
		weld.Parent = ShieldAura

		-- Shield Model
		local ShieldModel = (AssetFolder:FindFirstChild("Shield") :: Instance):Clone() :: Model
		ShieldModel.Parent = workspace:FindFirstChild("Ignore") :: Folder
		local Joint = ShieldModel:FindFirstChild("Joint") :: Motor6D
		Joint.Part0 = character:FindFirstChild("RightHand") :: MeshPart

		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://97393743863971"
		animation.Parent = character
		local track = Animator:LoadAnimation(animation)
		track:Play()
		track.Ended:Once(function()
			animation:Destroy()
		end)

		player:AddTag("hasShield")
		task.delay(5, function()
			if player:HasTag("hasShield") then
				player:RemoveTag("hasShield")
				ShieldModel:Destroy()
				ShieldAura:Destroy()
				track:Stop();
			end
		end)
	end,
}
