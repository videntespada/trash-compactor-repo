local Debris = game:GetService("Debris")

local COOLDOWN = 12
local DURATION = 4 -- invulnerable window
local SFX_SHIELD_ACTIVATE = "rbxassetid://118634997930608"

return {
	Cooldown = COOLDOWN,
	init = function(player: Player, AssetFolder: Folder)
		local character = player.Character
		if not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local sound = Instance.new("Sound")
			sound.SoundId = SFX_SHIELD_ACTIVATE
			sound.Volume = 1
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 3)
		end
		local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local Animator = Humanoid:FindFirstChildOfClass("Animator")

		local ShieldAura = (AssetFolder:FindFirstChild("ShieldAura") :: Instance):Clone() :: Part
		ShieldAura.Parent = workspace:FindFirstChild("Ignore")
		ShieldAura.CFrame = character:GetPivot()
		local _, size = character:GetBoundingBox()
		ShieldAura.Size = size

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = character:FindFirstChild("HumanoidRootPart")
		weld.Part1 = ShieldAura
		weld.Parent = ShieldAura

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
		task.delay(DURATION, function()
			if player:HasTag("hasShield") then
				player:RemoveTag("hasShield")
				ShieldModel:Destroy()
				ShieldAura:Destroy()
				track:Stop()
			end
		end)
	end,
}
