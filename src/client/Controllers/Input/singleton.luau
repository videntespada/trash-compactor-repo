local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local player = Players.LocalPlayer

		UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				EventHandler:fire("onClick", player)
			end
		end)
	end,
	events = {},
}
