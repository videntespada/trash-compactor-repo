local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local AliveFolder = workspace:WaitForChild("Alive") -- Define this once up here for speed

return {
	init = function()
		Players.PlayerAdded:Connect(function(player)
			Data.playerAdded(player)

			-- Set initial attributes
			player:SetAttribute("garbageChance", 0)

			player.CharacterAdded:Connect(function(character)
				task.wait()

				if character.Parent then -- Ensure they haven't been deleted instantly
					character.Parent = AliveFolder
				end
			end)
		end)

		Players.PlayerRemoving:Connect(function(player)
			-- Data.playerRemoving(player)
		end)
	end,
	events = {},
}
