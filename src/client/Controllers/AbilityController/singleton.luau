local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local player = Players.LocalPlayer
		local gui = player.PlayerGui
		local inputActionFolder = gui:FindFirstChild("InputActions")
		
		local UseAbility = inputActionFolder:FindFirstChild("UseAbility") :: InputAction

		UseAbility.Released:Connect(function(...) 
			EventHandler:fire("sendAbilityUse")
		end)
	end,
	events = {},
}