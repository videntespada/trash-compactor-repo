local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local ProfileStore = require(script.Parent.ProfileStore)
local Template = require(script.Parent.Template)

local PlayerStore = ProfileStore.New("_*99288f7^%237.022", Template)
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
	EventHandler:fireClient(player, "changeCurrency", currency, increment)
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

return {
	playerAdded = playerAdded,
	grabData = grabData,
	mutateCurrency = mutateCurrency,
}
