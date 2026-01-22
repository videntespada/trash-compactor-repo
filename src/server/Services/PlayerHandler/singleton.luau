local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)

return {
	init = function()
		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(character)
				-- * Add player to datastore
				Data.playerAdded(player)

				-- Everything else

				-- Chance per round
				player:SetAttribute("garbageChance", 0)
				-- player:SetAttribute("currentPos", Vector3.zero)

				character.Parent = workspace:WaitForChild("Alive")
			end)
		end)
	end,
	events = {},
}
