local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local ProfileStore = require(script.Parent.ProfileStore)
local Template = require(script.Parent.Template)

local DataStoreService = game:GetService("DataStoreService")
local CrownsLeaderboardStore = DataStoreService:GetOrderedDataStore("CrownsLeaderboard_v2")
local CoinsLeaderboardStore = DataStoreService:GetOrderedDataStore("CoinsLeaderboard_v2")

local PlayerStore = ProfileStore.New("_*99288f7^%237.024", Template)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function updateLeaderstats(player: Player, coins: number, crowns: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		local coinsVal = Instance.new("IntValue")
		coinsVal.Name = "Coins"
		coinsVal.Value = coins
		coinsVal.Parent = leaderstats
		local crownsVal = Instance.new("IntValue")
		crownsVal.Name = "Trophies"
		crownsVal.Value = crowns
		crownsVal.Parent = leaderstats
	else
		local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue?
		local crownsVal = leaderstats:FindFirstChild("Crowns") :: IntValue?
		if coinsVal then
			coinsVal.Value = coins
		end
		if crownsVal then
			crownsVal.Value = crowns
		end
	end
end

local function playerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function(): boolean
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Unable to load data - rejoin")
		end)
		if player.Parent == Players then
			Profiles[player] = profile
			updateLeaderstats(player, profile.Data.coins, profile.Data.crowns)
			-- Sync to leaderboard stores so this player appears even before any currency change
			task.spawn(function()
				pcall(function()
					CoinsLeaderboardStore:SetAsync(player.UserId, profile.Data.coins)
				end)
				pcall(function()
					CrownsLeaderboardStore:SetAsync(player.UserId, profile.Data.crowns)
				end)
			end)
		else
			profile:EndSession()
		end
	else
		player:Kick("Unable to load data - rejoin")
	end
end

local function grabData(player: Player): nil | Template.TemplateType
	local profile = Profiles[player]
	if not profile then
		return nil
	end

	return profile.Data
end

local function mutateCurrency(player: Player, currency: "coins" | "crowns", to: number)
	local data = grabData(player)
	local increment = 0

	increment = to
	if data.passes["2x_coins"] then
		increment *= 2
	end
	data[currency] = increment
	updateLeaderstats(player, data.coins, data.crowns)

	if currency == "crowns" then
		task.spawn(function()
			local ok, err = pcall(function()
				CrownsLeaderboardStore:SetAsync(player.UserId, data.crowns)
			end)
			if not ok then
				warn(`[Data] Error setting crowns leaderboard for {player.Name}: {err}`)
			end
		end)
	elseif currency == "coins" then
		task.spawn(function()
			local ok, err = pcall(function()
				CoinsLeaderboardStore:SetAsync(player.UserId, data.coins)
			end)
			if not ok then
				warn(`[Data] Error setting coins leaderboard for {player.Name}: {err}`)
			end
		end)
	end

	EventHandler:fireClient(player, "changeCurrency", currency, increment)
end

local DEBUG_LEADERBOARD = true
local function debugData(msg: string)
	if DEBUG_LEADERBOARD then
		print("[Data.Leaderboard]", msg)
	end
end

local function getTop20Crowns(limit: number): { { rank: number, userId: number?, username: string, value: number } }
	limit = limit or 20
	debugData(`getTop20Crowns(limit={limit})`)
	local ok, pages = pcall(function()
		return CrownsLeaderboardStore:GetSortedAsync(false, limit)
	end)
	if not ok or not pages then
		warn("[Data] Error getting top crowns:", pages)
		debugData(`getTop20Crowns FAILED ok={ok}, pages={pages}`)
		return {}
	end
	local topPage = pages:GetCurrentPage()
	local results = {}

	for rank, entry in ipairs(topPage) do
		local key = entry.key or entry.Key
		local rawValue = entry.value or entry.Value
		local userId = (type(key) == "number") and key or tonumber(key)
		local crowns = tonumber(rawValue) or 0

		local username = "Unknown"
		if userId and userId > 0 then
			local nameOk, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk and name then
				username = name
			end
		end
		table.insert(results, {
			rank = rank,
			userId = userId,
			username = username,
			value = crowns,
		})
		debugData(`  crowns #{rank}: userId={userId} username={username} crowns={crowns}`)
	end
	debugData(`getTop20Crowns returned #results={#results}`)
	return results
end

local function getTop20Coins(limit: number): { { rank: number, userId: number?, username: string, value: number } }
	limit = limit or 20
	debugData(`getTop20Coins(limit={limit})`)
	local ok, pages = pcall(function()
		return CoinsLeaderboardStore:GetSortedAsync(false, limit)
	end)
	if not ok or not pages then
		warn("[Data] Error getting top coins:", pages)
		debugData(`getTop20Coins FAILED ok={ok}, pages={pages}`)
		return {}
	end
	local topPage = pages:GetCurrentPage()
	local results = {}

	for rank, entry in ipairs(topPage) do
		local key = entry.key or entry.Key
		local rawValue = entry.value or entry.Value
		local userId = (type(key) == "number") and key or tonumber(key)
		local coins = tonumber(rawValue) or 0

		local username = "Unknown"
		if userId and userId > 0 then
			local nameOk, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk and name then
				username = name
			end
		end
		table.insert(results, {
			rank = rank,
			userId = userId,
			username = username,
			value = coins,
		})
		debugData(`  coins #{rank}: userId={userId} username={username} coins={coins}`)
	end
	debugData(`getTop20Coins returned #results={#results}`)
	return results
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

return {
	playerAdded = playerAdded,
	grabData = grabData,
	mutateCurrency = mutateCurrency,
	getTop20Crowns = getTop20Crowns,
	getTop20Coins = getTop20Coins,
}
