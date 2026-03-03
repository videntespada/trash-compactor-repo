local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui

	task.spawn(function()
		while true do
			for _, item in ipairs(baseUI:GetDescendants()) do
				if item:IsA("ImageLabel") and item.Name == "Sunray" then
					item.Rotation = item.Rotation + 0.3
				end
			end
			task.wait()
		end
	end)
end
