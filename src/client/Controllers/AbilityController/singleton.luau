local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ThrowBomb = require(StarterPlayer.StarterPlayerScripts.Client.VFX.ThrowBomb)
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

		EventHandler:connectClient("bombVFX", function(BombModel: Model, character: Model, Map: Folder, endPos)
			ThrowBomb(BombModel, character, Map, endPos)
		end)
	end,
	events = {},
}
