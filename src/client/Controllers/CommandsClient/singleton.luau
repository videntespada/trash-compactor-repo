local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local COMMAND_PREFIX = "/"
local ALLOWED_IDS = { [299257961] = true, [8119156] = true }

local function hasPermission(userId: number): boolean
	return ALLOWED_IDS[userId] == true
end

return {
	init = function()
		local player = Players.LocalPlayer

		player.Chatted:Connect(function(message: string)
			local args = string.split(message, " ")
			local rawCommand = args[1]
			if not rawCommand or #rawCommand == 0 then
				return
			end
			local command = rawCommand:lower()
			if not string.match(command, "^" .. COMMAND_PREFIX) then
				return
			end

			if not hasPermission(player.UserId) then
				return
			end

			-- /ability [name] — client fires to server (legacy chat only)
			if command == COMMAND_PREFIX .. "ability" then
				local value = args[2]
				if value then
					EventHandler:fire("onCommandSend", "ability", value)
				else
					warn("Usage: /ability [name]")
				end
				return
			end

			-- /coins and /crowns are handled only by server TextChatCommand to avoid double-apply.
			-- If you use legacy chat and Chatted fires, the server still runs the command once via TextChatCommand.
			-- So we do not fire onCommandSend for coins/crowns here.
			if command == COMMAND_PREFIX .. "coins" then
				local value = args[2]
				local amount = value and tonumber(value)
				if not amount or amount <= 0 then
					warn("Usage: /coins [amount], e.g. /coins 100")
				end
				return
			end
			if command == COMMAND_PREFIX .. "crowns" then
				local value = args[2]
				local amount = value and tonumber(value)
				if not amount or amount <= 0 then
					warn("Usage: /crowns [amount], e.g. /crowns 5")
				end
			end
		end)
	end,
	events = {},
}
