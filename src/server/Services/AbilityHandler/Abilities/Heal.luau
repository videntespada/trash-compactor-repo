local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpawnGeneralVFX = require(ReplicatedStorage.Shared.SpawnGeneralVFX)

local COOLDOWN = 8
local HEAL_AMOUNT = 25
local VISUAL_DURATION = 5
local SFX_HEAL_ACTIVATE = "rbxassetid://97544615417272"

return {
	Cooldown = COOLDOWN,
	init = function(player: Player, AssetFolder: Folder)
		local character = player.Character
		if not character then
			return
		end
		SpawnGeneralVFX("Heal", character:GetPivot(), 4)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local sound = Instance.new("Sound")
			sound.SoundId = SFX_HEAL_ACTIVATE
			sound.Volume = 1
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 3)
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
		Humanoid.Health += HEAL_AMOUNT

		Debris:AddItem(HealPart, VISUAL_DURATION)
	end,
}
