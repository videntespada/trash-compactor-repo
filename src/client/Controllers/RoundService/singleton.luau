local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		print("I started! ")

		EventHandler:connectClient("TestEvent", function()
			print("I recieved!")
			EventHandler:clean("TestEvent")
		end)
	end,
	events = {
		"TestEvent",
	},
}
