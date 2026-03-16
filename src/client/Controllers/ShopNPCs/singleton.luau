local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
return {
	init = function()
		local BoothAvatars = workspace:WaitForChild("BoothAvatars") :: Folder

		for _, avatar in BoothAvatars:GetChildren() do
			if avatar:IsA("Model") then
				local humanoid = avatar:FindFirstChildWhichIsA("Humanoid", true)
				local animator = humanoid:FindFirstChildWhichIsA("Animator", true)
				if animator then
					if avatar.Name == "Initials" then
						local animation = Instance.new("Animation")
						animation.AnimationId = "rbxassetid://10714352626"
						animation.Parent = animator
						local track = animator:LoadAnimation(animation)
						track.Looped = true
						track:Play()
					elseif avatar.Name == "Bes_oke" then
						local animation = Instance.new("Animation")
						animation.AnimationId = "rbxassetid://10714066964"
						animation.Parent = animator
						local track = animator:LoadAnimation(animation)
						track.Looped = true
						track:Play()
					end
				end

				local humanoidRootPart = avatar:FindFirstChildWhichIsA("HumanoidRootPart", true)
				local proximityPrompt = avatar:FindFirstChild("ProximityPrompt") :: ProximityPrompt

				local lastOpenTime = 0
				local COOLDOWN = 1

				proximityPrompt.Triggered:Connect(function(player)
					local now = os.clock()
					if now - lastOpenTime < COOLDOWN then
						return
					end
					lastOpenTime = now

					local openSound = Instance.new("Sound")
					openSound.Parent = workspace
					openSound.SoundId = "rbxassetid://94923494962300"
					openSound.Volume = 0.8
					openSound.Ended:Once(function()
						openSound:Destroy()
					end)
					openSound:Play()

					if avatar.Name == "Initials" then
						ClientEvents.toggleUI:Fire("ShopFrame")
					elseif avatar.Name == "Bes_oke" then
						ClientEvents.toggleUI:Fire("AbilitiesFrame")
					end
				end)
			end
		end
	end,
	events = {},
}
