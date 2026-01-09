local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)

return {
	init = function()
		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function()
				-- * Add player to datastore
				Data.playerAdded(player)

				-- Everything else
				
			end)
		end)
	end,
	events = {},
}
