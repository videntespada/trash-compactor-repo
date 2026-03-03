return {
	init = function()
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
		local player = Players.LocalPlayer

		-- Configuration
		local COMMAND_PREFIX = "/"
		local ALLOWED_IDS = { 299257961, 8119156 }

		-- Helper function to check permissions locally (optional but good for UX)
		local function hasPermission(id)
			return table.find(ALLOWED_IDS, id) ~= nil
		end

		player.Chatted:Connect(function(message)
			-- Split the message into words
			local args = string.split(message, " ")
			local command = args[1]:lower()

			-- Check for the "ability" command
			if command == COMMAND_PREFIX .. "ability" then
				if not hasPermission(player.UserId) then
					print("You do not have permission to use this command.")
					return
				end

				local abilityValue = args[2]

				if abilityValue then
					-- Replicating the EventHandler:fire call
					-- Parameters: "onCommandSend", "ability", value
					EventHandler:fire("onCommandSend", "ability", abilityValue)
					print("Sent ability update: " .. abilityValue)
				else
					warn("Usage: /ability [name]")
				end
			end
		end)
	end,
	events = {},
}
