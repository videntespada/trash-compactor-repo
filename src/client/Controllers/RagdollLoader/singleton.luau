local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = workspace.CurrentCamera
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local head: Part = char:WaitForChild("Head") :: Part
local hum: Humanoid = char:WaitForChild("Humanoid") :: Humanoid

local noCamShake = true
local antiMove = false

local remote = ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("Ragdoll") :: RemoteEvent

local function focus(arg)
	local root = hum.RootPart

	if not root then
		return
	end

	if arg == "Focus" then
		if noCamShake then
			camera.CameraSubject = head
			root.CanCollide = false
		end
	elseif arg == "Unfocus" then
		if noCamShake then
			camera.CameraSubject = hum
			root.CanCollide = true
		end
	end
end
local function noMove(arg)
	if arg == "Stop" then
		if antiMove then
			hum.WalkSpeed = 0
			hum.PlatformStand = true
		end
	elseif arg == "Aan" then
		if antiMove then
			hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
			hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
			hum.JumpPower = game.StarterPlayer.CharacterJumpPower
			hum.PlatformStand = false
		end
	end
end

return {
	init = function()
		remote.OnClientEvent:Connect(function(arg, sec)
			if hum then
				if arg == "Make" then
					hum:ChangeState(Enum.HumanoidStateType.Physics) -- in ragdoll
					focus("Focus")
					noMove("Stop")
				elseif arg == "Destroy" then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp) -- out of ragdoll
					focus("Unfocus")
					noMove("Aan")
				end
				if arg == nil then
					if sec == "manualM" then
						hum:ChangeState(Enum.HumanoidStateType.Physics) -- in ragdoll
						focus("Focus")
						noMove("Stop")
					end
				end
				if arg == nil then
					if sec == "manualD" then
						hum:ChangeState(Enum.HumanoidStateType.GettingUp) -- out of ragdoll
						focus("Unfocus")
						noMove("Aan")
					end
				end
			end
		end)
	end,
	events = {},
}
