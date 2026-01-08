local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		print("I started! ")

		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function()
				EventHandler:fireClient(player, "TestEvent")
			end)
		end)
	end,
	events = {
		"TestEvent",
	},
}
