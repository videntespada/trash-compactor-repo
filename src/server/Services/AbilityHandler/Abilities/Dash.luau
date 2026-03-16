local Debris = game:GetService("Debris")

local COOLDOWN = 4
local DURATION = 0.15 -- burst length
local BURST_SPEED = 65 -- studs/s
local SFX_DASH_ACTIVATE = "rbxassetid://127294362110618"

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
			sound.SoundId = SFX_DASH_ACTIVATE
			sound.Volume = 1
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 3)
		end
		local p = (AssetFolder:FindFirstChild("DashEffect") :: Part):Clone() :: Part
		if not p then
			return
		end
		local Dash = p :: Part
		local decalFolder = Dash:FindFirstChild("End") :: Part
		local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		local Humanoid = character:FindFirstChildOfClass("Humanoid")
		local Animator = Humanoid:FindFirstChildOfClass("Animator")

		Dash.Parent = workspace:FindFirstChild("Ignore")
		Dash.Position = root.Position

		local forward = root.CFrame.LookVector
		local direction = -Vector3.new(forward.X, 0, forward.Z)

		Dash.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
		for _, dash in ipairs(Dash:GetDescendants()) do
			if dash:IsA("ParticleEmitter") then
				dash:Emit(dash:GetAttribute("EmitCount"))
			end
		end

		local frameCount = 16
		local fps = 12
		for _, child in ipairs(decalFolder:GetChildren()) do
			if child:IsA("Decal") then
				child.Transparency = 1
			end
		end
		task.spawn(function()
			while true do
				for i = 1, frameCount do
					local frameName = tostring(i)
					local currentDecal = decalFolder:FindFirstChild(frameName)
					if currentDecal then
						currentDecal.Transparency = 0
						task.wait(1 / fps)
						currentDecal.Transparency = 1
					end
				end
				task.wait()
			end
		end)

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://128847747984922"
		anim.Parent = character
		local animation = Animator:LoadAnimation(anim)
		animation.Looped = false
		animation:Play(0)

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
		bv.Velocity = root.CFrame.LookVector * BURST_SPEED
		bv.Parent = root
		Debris:AddItem(bv, DURATION)
	end,
}
