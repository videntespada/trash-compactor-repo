local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local Template = require(ServerScriptService.Server.Modules.DataStore.Template)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local function sendSeeYouTomorrow(player: Player, nextDay: number)
	task.delay(1, function()
		EventHandler:fireClient(player, "sendNotification", `👋 See you tomorrow for Day {nextDay}!`, 137502807803779, "Normal")
	end)
end

local dayToFunction: { [number]: (player: Player, plrData: Template.TemplateType) -> () } = {
	[1] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 50)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 1 reward: +50 coins!", 4612378364, "Currency")
		sendSeeYouTomorrow(player, 2)
	end,
	[2] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 2 reward: +100 coins!", 4612378364, "Currency")
		sendSeeYouTomorrow(player, 3)
	end,
	[3] = function(player: Player, plrData: Template.TemplateType)
		ServerEvents.forceChooseGarbageMan:Fire(player)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 3 reward: You're the next Garbageman!", 4612378364, "Positive")
		sendSeeYouTomorrow(player, 4)
	end,
	[4] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 150)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 4 reward: +150 coins!", 4612378364, "Currency")
		sendSeeYouTomorrow(player, 5)
	end,
	[5] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 250)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 5 reward: +250 coins!", 4612378364, "Currency")
		sendSeeYouTomorrow(player, 6)
	end,
	[6] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 400)
		EventHandler:fireClient(player, "sendNotification", "🎁 Day 6 reward: +400 coins!", 4612378364, "Currency")
		sendSeeYouTomorrow(player, 7)
	end,
	[7] = function(player: Player, plrData: Template.TemplateType)
		plrData.abilityInventory[#plrData.abilityInventory + 1] = "Bat"
		EventHandler:fireClient(player, "sendNotification", "🦇 Day 7 reward: Bat Ability unlocked!", 4612378364, "Positive")
		sendSeeYouTomorrow(player, 1)
	end,
}

return {
	init = function()
		EventHandler:connect("claimDailyReward", function(player: Player)
			local plrData = Data.grabData(player)
			if not plrData then
				return
			end

			if plrData.dailyRewardsUnlocked then
				local claimed = plrData.claimedDailyDays or {}
				local nextDay: number? = nil
				for day = 1, 7 do
					if not table.find(claimed, day) then
						nextDay = day
						break
					end
				end
				if not nextDay then
					EventHandler:fireClient(player, "sendNotification", "🔄 All rewards claimed! Resets soon", 128635936514965, "Positive")
					EventHandler:fireClient(player, "updateDailyReward", 7, false, claimed)
					return
				end
				dayToFunction[nextDay](player, plrData)
				table.insert(claimed, nextDay)
				plrData.claimedDailyDays = claimed
				EventHandler:fireClient(player, "updateDailyReward", 7, false, claimed)
				return
			end

			if plrData.todayClaimed then
				warn(`${player.Name} has already claimed today's reward.`)
				return
			end
			dayToFunction[plrData.dayStreak](player, plrData)
			plrData.todayClaimed = true
			EventHandler:fireClient(player, "updateDailyReward", plrData.dayStreak, plrData.todayClaimed)
		end)
	end,
	events = {
		"claimDailyReward",
		"updateDailyReward",
	},
}
