local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local Template = require(ServerScriptService.Server.Modules.DataStore.Template)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local dayToFunction: { [number]: (player: Player, plrData: Template.TemplateType) -> () } = {
	[1] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
		EventHandler:fireClient(player, "sendNotification", `You claimed your daily reward! You earned 100 coins.`)
		task.delay(1, function()
			EventHandler:fireClient(player, "sendNotification", `Thanks for playing! Come back tomorrow for your next reward.`)
		end)
	end,
	[2] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
		EventHandler:fireClient(player, "sendNotification", `You claimed your daily reward! You earned 100 coins.`)
		task.delay(1, function()
			EventHandler:fireClient(player, "sendNotification", `Thanks for playing! Come back tomorrow for your next reward.`)
		end)
	end,
	[3] = function(player: Player, plrData: Template.TemplateType)
		ServerEvents.forceChooseGarbageMan:Fire(player)
		EventHandler:fireClient(player, "sendNotification", `You claimed your daily reward! You became the Garbage Man.`)
		task.delay(1, function()
			EventHandler:fireClient(player, "sendNotification", `Thanks for playing! Come back tomorrow for your next reward.`)
		end)
	end,
	[4] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
	end,
	[5] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
	end,
	[6] = function(player: Player, plrData: Template.TemplateType)
		Data.mutateCurrency(player, "coins", plrData.coins + 100)
	end,
	[7] = function(player: Player, plrData: Template.TemplateType)
		plrData.abilityInventory[#plrData.abilityInventory + 1] = "Bat"
	end,
}

return {
	init = function()
		EventHandler:connect("claimDailyReward", function(player: Player)
			local plrData = Data.grabData(player)
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
