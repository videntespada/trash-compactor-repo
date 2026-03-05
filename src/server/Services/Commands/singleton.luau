local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

return {
	init = function()
		local allowedUsers = {
			[299257961] = true,
			[8119156] = true,
		}

		local function giveCoins(player: Player, amount: number)
			local plrData = Data.grabData(player)
			Data.mutateCurrency(player, "coins", plrData.coins + amount)
			print(`Gave {player.Name} {amount} coins`)
		end

		local function giveCrowns(player: Player, amount: number)
			local plrData = Data.grabData(player)
			Data.mutateCurrency(player, "crowns", plrData.crowns + amount)
			print(`Gave {player.Name} {amount} crowns`)
		end

		local function parseAmount(message: string): number?
			local s = message:match("%d+")
			return s and tonumber(s)
		end

		-- Text Chat commands (works when player.Chatted does not fire)
		pcall(function()
			local coinsCmd = Instance.new("TextChatCommand")
			coinsCmd.Name = "CoinsCommand"
			coinsCmd.PrimaryAlias = "/coins"
			coinsCmd.SecondaryAlias = "/coin"
			coinsCmd.Triggered:Connect(function(textSource, message)
				local player = Players:GetPlayerByUserId(textSource.UserId)
				if not player or not allowedUsers[player.UserId] then return end
				local amount = parseAmount(message)
				if amount and amount > 0 then giveCoins(player, amount) end
			end)
			coinsCmd.Parent = TextChatService

			local crownsCmd = Instance.new("TextChatCommand")
			crownsCmd.Name = "CrownsCommand"
			crownsCmd.PrimaryAlias = "/crowns"
			crownsCmd.SecondaryAlias = "/crown"
			crownsCmd.Triggered:Connect(function(textSource, message)
				local player = Players:GetPlayerByUserId(textSource.UserId)
				if not player or not allowedUsers[player.UserId] then return end
				local amount = parseAmount(message)
				if amount and amount > 0 then giveCrowns(player, amount) end
			end)
			crownsCmd.Parent = TextChatService
		end)

		-- Legacy chat / client-fired commands
		EventHandler:connect("onCommandSend", function(who: Player, what: string, value: string)
			if not allowedUsers[who.UserId] then
				warn("Not applicable player.")
				return
			end

			if what == "ability" then
				local plrData = Data.grabData(who)
				plrData.ability = value
			elseif what == "giveCoins" then
				local amount = tonumber(value)
				if amount and amount > 0 then
					giveCoins(who, amount)
				else
					warn("coins command requires a positive number, e.g. /coins 100")
				end
			elseif what == "giveCrowns" then
				local amount = tonumber(value)
				if amount and amount > 0 then
					giveCrowns(who, amount)
				else
					warn("crowns command requires a positive number, e.g. /crowns 5")
				end
			end
		end)
	end,
	events = {
		"onCommandSend",
	},
}
