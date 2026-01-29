local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local Template = require(ServerScriptService.Server.Modules.DataStore.Template)
local SECONDS_IN_A_DAY = 86400

local function getCurrentDayID(): number
	return math.floor(os.time() / SECONDS_IN_A_DAY)
end

return function(player: Player)
	local plrData: Template.TemplateType
	local s, result = pcall(Data.grabData, player)
	if not s then
		warn("Unable to grab data")
		return
	else
		plrData = result
	end

	-- ? Compare
	local currDayID = getCurrentDayID()
	local lastClaimID = math.floor(plrData.lastLogin / SECONDS_IN_A_DAY)

	if currDayID > lastClaimID then
		-- ? Check for streak break
		-- If the difference is exactly 1, keep
		-- If >1, bring back down to 1
		if currDayID - lastClaimID == 1 then
			plrData.dayStreak += 1
		else
			plrData.dayStreak = 1
		end
		warn(`Reward given for streak ${plrData.dayStreak}`)

		plrData.lastLogin = os.time()
	end
end
