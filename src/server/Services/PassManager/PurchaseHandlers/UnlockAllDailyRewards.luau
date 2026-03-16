local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

return {
	id = "3554152542",
	init = function(player: Player)
		local plrData = Data.grabData(player)
		if not plrData then
			return
		end
		plrData.dailyRewardsUnlocked = true
		if not plrData.claimedDailyDays then
			plrData.claimedDailyDays = {}
		end
		-- Backfill so already-claimed streak days are not claimable again
		for i = 1, math.min(7, plrData.dayStreak - 1) do
			if not table.find(plrData.claimedDailyDays, i) then
				table.insert(plrData.claimedDailyDays, i)
			end
		end
		if plrData.todayClaimed and plrData.dayStreak >= 1 and plrData.dayStreak <= 7 then
			if not table.find(plrData.claimedDailyDays, plrData.dayStreak) then
				table.insert(plrData.claimedDailyDays, plrData.dayStreak)
			end
		end
		EventHandler:fireClient(player, "updateDailyReward", 7, false, plrData.claimedDailyDays)
		return true
	end,
}