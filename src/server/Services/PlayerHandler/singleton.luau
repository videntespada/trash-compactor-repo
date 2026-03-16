local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local CheckDaily = require(ServerScriptService.Server.Services.PlayerHandler.Initializers.CheckDaily)
local CheckFreeRewards = require(ServerScriptService.Server.Services.PlayerHandler.Initializers.CheckFreeRewards)
local AliveFolder = workspace:WaitForChild("Alive")

return {
	init = function()
		Players.PlayerAdded:Connect(function(player)
			Data.playerAdded(player)

			local plrData = Data.grabData(player)
			if not plrData then
				warn("[PlayerHandler] No data for " .. player.Name .. " - skipping init")
				return
			end

			-- Test notification
			-- task.delay(4, function()
			-- 	EventHandler:fireClient(player, "sendNotification", `🗑️ Welcome to Trash Compactor!`, 137502807803779, "Positive")
			-- end)

			task.delay(5, function()
				EventHandler:fireClient(player, "changeCurrency", "crowns", plrData.crowns)
				EventHandler:fireClient(player, "changeCurrency", "coins", plrData.coins)
				-- Load Abilities to abilityframe
				EventHandler:fireClient(
					player,
					"loadAbilitiyInventoryData",
					plrData.abilityInventory,
					plrData.ability,
					plrData.crowns
				)
			end)

			-- ? Check for daily rewards
			CheckDaily(player)

			-- ? Check for free rewards
			if not plrData.claimedReward then
				CheckFreeRewards(player)
			else
				-- Force the UI to say that they did everything already
				EventHandler:fireClient(player, "freeRewardStatus", {
					gameFavorited = true,
					groupJoined = true,
					gameLiked = true,
				})
			end

			if plrData.passes.vip then
				player:SetAttribute("IsVIP", true)
			end

			-- Set initial attributes
			player:SetAttribute("garbageChance", 0)

			player.CharacterAdded:Connect(function(character)
				task.wait()

				if character.Parent then -- Ensure they haven't been deleted instantly
					character.Parent = AliveFolder

					-- ? Spawn effect
				end
			end)
		end)

		Players.PlayerRemoving:Connect(function(player)
			-- Data.playerRemoving(player)
		end)
	end,
	events = {
		"changeCurrency",
		"freeRewardStatus",
		"checkRewardStatus",
		"promptFavorite",
		"toggleFavorited",
		"promptJoinGroup",
		"toggleJoinedGroup",
		"loadAbilitiyInventoryData",
		"sendNotification",
	},
}
