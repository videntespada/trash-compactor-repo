local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame

	for _, v in ipairs(HUD:GetDescendants()) do
		if v:FindFirstChild("BG") then
			local bg = v:FindFirstChild("BG") :: ImageLabel

			local startPos = bg.Position

			local offset = UDim2.fromScale(0.1, -0.1)
			local targetPos = startPos + offset

			task.spawn(function()
				local speed = 0.8

				local connection
				connection = RunService.RenderStepped:Connect(function()
					if not bg.Parent then
						connection:Disconnect()
						return
					end

					local currentTime = os.clock() * speed
					local alpha = (math.sin(currentTime) + 1) / 2

					bg.Position = startPos:Lerp(targetPos, alpha)
				end)
			end)
		end
	end
end
