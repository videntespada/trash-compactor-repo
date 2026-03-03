local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local allowedUsers = {
			[299257961] = true,
			[8119156] = true,
		}

		EventHandler:connect("onCommandSend", function(who: Player, what: string, value: string)
			if not allowedUsers[who.UserId] then
				warn("Not applicable player.")
				return
			end

			if what == "ability" then
				local plrData = Data.grabData(who)
				print(plrData.ability)
				plrData.ability = value
				print(plrData.ability)
			end
		end)
	end,
	events = {
		"onCommandSend",
	},
}
