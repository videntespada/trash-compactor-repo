local Debris = game:GetService("Debris")
return {
	Cooldown = 3,
	init = function(player: Player, AssetFolder: Folder)
		local character = player.Character
		if not character then
			return
		end
		local p = (AssetFolder:FindFirstChild("DashEffect") :: Instance):Clone() :: Instance
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
		-- Emit particles
		for _, dash in ipairs(Dash:GetDescendants()) do
			if dash:IsA("ParticleEmitter") then
				dash:Emit(dash:GetAttribute("EmitCount"))
			end
		end

		local frameCount = 16
		local fps = 12

		-- Initial setup: Hide all frames
		for _, child in ipairs(decalFolder:GetChildren()) do
			if child:IsA("Decal") then
				child.Transparency = 1
			end
		end

		-- Animation Loop
		task.spawn(function()
			while true do
				for i = 1, frameCount do
					local frameName = tostring(i)
					local currentDecal = decalFolder:FindFirstChild(frameName)

					if currentDecal then
						currentDecal.Transparency = 0 -- Show frame
						task.wait(1 / fps)
						currentDecal.Transparency = 1 -- Hide frame
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
		-- in lookdirection, slightly upwards
		bv.Velocity = (root.CFrame.LookVector * 75)
		bv.Parent = root
		Debris:AddItem(bv, 0.1)
	end,
}
