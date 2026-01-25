local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local camera = workspace.CurrentCamera
local plr = Players.LocalPlayer

-- We do NOT define char/hum here. They become stale after death.

local noCamShake = true
local antiMove = false

local remote = ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("Ragdoll") :: RemoteEvent

-- Helper function to get the CURRENT valid character components
local function getCharacterComponents()
	local char = plr.Character
	if not char then
		return nil, nil, nil
	end

	local head = char:FindFirstChild("Head")
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") -- Safe check for root too

	return char, head, hum, root
end

local function focus(arg)
	local _, head, hum, root = getCharacterComponents()

	-- Safety checks: If we are dead/loading, stop.
	if not root or not head or not hum then
		return
	end

	if arg == "Focus" then
		if noCamShake then
			camera.CameraSubject = head
			root.CanCollide = false
		end
	elseif arg == "Unfocus" then
		if noCamShake then
			-- Reset to Humanoid so standard Roblox camera behavior returns
			camera.CameraSubject = hum
			root.CanCollide = true
		end
	end
end

local function noMove(arg)
	local _, _, hum, _ = getCharacterComponents()
	if not hum then
		return
	end

	if arg == "Stop" then
		if antiMove then
			hum.WalkSpeed = 0
			hum.PlatformStand = true
		end
	elseif arg == "Aan" then
		if antiMove then
			hum.WalkSpeed = 16 -- Default fallback or fetch from StarterPlayer
			hum.JumpHeight = 7.2
			hum.JumpPower = 50
			hum.PlatformStand = false
		end
	end
end

-- SAFETY NET: Reset camera when a new character spawns
plr.CharacterAdded:Connect(function(newChar)
	local hum = newChar:WaitForChild("Humanoid", 10)
	if hum then
		camera.CameraSubject = hum
		camera.CameraType = Enum.CameraType.Custom
	end
end)

return {
	init = function()
		remote.OnClientEvent:Connect(function(arg, sec)
			local _, _, hum, _ = getCharacterComponents()

			-- If the player is dead/respawning, 'hum' might be nil. Guard against that.
			if not hum then
				return
			end

			-- Handling "Make" (Ragdoll)
			if arg == "Make" or sec == "manualM" then
				hum:ChangeState(Enum.HumanoidStateType.Physics)
				focus("Focus")
				noMove("Stop")

			-- Handling "Destroy" (Unragdoll)
			elseif arg == "Destroy" or sec == "manualD" then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				focus("Unfocus")
				noMove("Aan")
			end
		end)
	end,
	events = {},
}
