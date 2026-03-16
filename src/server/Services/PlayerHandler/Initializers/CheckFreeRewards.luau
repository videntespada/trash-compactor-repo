local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

-- Server
local statusTable: { [Player]: {
	gameFavorited: boolean,
	gameLiked: boolean,
	groupJoined: boolean,
} } = {}

return function(player: Player)
	statusTable[player] = {
		gameFavorited = false,
		groupJoined = false,
		gameLiked = false,
	}

	EventHandler:connect("toggleJoinedGroup", function(plr, to: boolean)
		if statusTable[plr] then
			statusTable[plr].groupJoined = to
		end
	end)

	EventHandler:connect("toggleFavorited", function(plr, to: boolean)
		if statusTable[plr] then
			statusTable[plr].gameFavorited = to
			statusTable[plr].gameLiked = to
		end
	end)

	EventHandler:connect("checkRewardStatus", function(player: Player)
		local plrData = Data.grabData(player)
		local s = statusTable[player]

		if s.gameFavorited and s.gameLiked and s.groupJoined then
			if not plrData.claimedReward then
				plrData.claimedReward = true
				Data.mutateCurrency(player, "coins", plrData.coins + 500)
			end
		else
			if not s.gameFavorited then
				EventHandler:fireClient(player, "promptFavorite")
			elseif not s.groupJoined then
				EventHandler:fireClient(player, "promptJoinGroup")
			end
		end

		EventHandler:fireClient(player, "freeRewardStatus", statusTable[player])
	end)
end
