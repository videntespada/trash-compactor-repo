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

		EventHandler:connect("TestEventServer", function()
			print("I recieved!")
		end)
	end,
	events = {
		"TestEvent",
		"TestEventServer",
	},
}
