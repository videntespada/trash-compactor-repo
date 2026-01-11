local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local types = require(script.Parent.types)

local state: types.RoundStates = "Lobby"
local lobbyTime = 60
local intermissionTime = 15
local roundLength = 120
local playersNeeded = 3

local playerStats: { [Player]: {
	kills: number,
	cash: number,
} } = {}

local Map = workspace:WaitForChild("Map") :: Folder
local ScriptableFolder = Map:FindFirstChild("Scriptable") :: Folder
local ArenaSpawn = ScriptableFolder:FindFirstChild("Arena") :: Part
local GarbageManSpawn = ScriptableFolder:FindFirstChild("Ramp") :: Part

local function getTotalInRound(): { Player }
	local t = {}
	for i = 1, #CollectionService:GetTagged("InRound"), 1 do
		t[1 + #t] = CollectionService:GetTagged("InRound")[i] :: Player
	end

	return t
end

local function checkForPlayers(): boolean
	local enoughPlayers = #Players:GetPlayers() >= playersNeeded

	if not enoughPlayers then
		local totalPlayers = #Players:GetPlayers()
		warn(`Need ${playersNeeded - totalPlayers} more players to start.`)
		return false
	else
		return true
	end
end

local function getPlayerInRound(): { Player }
	local t = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if not player:HasTag("InRound") then
			continue
		end
		t[1 + #t] = player
	end

	return t
end

local function teleportPlayers()
	local r = math.random
	local size = ArenaSpawn.Size

	local function randomRel()
		return (r() * 2) - 1
	end

	for plr, _ in pairs(playerStats) do
		local character = plr.Character
		if plr:HasTag("GarbageMan") then
			character:PivotTo(GarbageManSpawn.CFrame)
			continue
		end
		local offset = Vector3.new((size.X / 2) * randomRel(), size.Y / 2, (size.Z / 2) * randomRel())
		local possibleSpawn = (ArenaSpawn.CFrame * CFrame.new(offset))

		character:PivotTo(possibleSpawn)
	end
end

local function transferPlayersToRound()
	for _, player in Players:GetPlayers() do
		if player:HasTag("AFK") then
			continue
		end
		player:AddTag("InRound")

		playerStats[player] = {
			cash = 0,
			kills = 0,
		}
		print(`Added ${player.Name} to round.`)
	end
end

local function changePlayerCount(tag: string)
	if tag == "InRound" then
		local amountCount = #CollectionService:GetTagged(tag)
		EventHandler:broadcast("changePlayerCount", amountCount)
	end
end

local function chooseGarbageMan()
	local total = 0

	for plr, _ in pairs(playerStats) do
		local chance = plr:GetAttribute("garbageChance") or 0
		total += chance
	end

	if total <= 0 then
		local players = {}
		for plr, _ in pairs(playerStats) do
			table.insert(players, plr)
		end
		print(players)
		local chosen = players[math.random(#players)]
		chosen:AddTag("GarbageMan")
		return chosen
	end

	local randomPoint = math.random() * total
	local currentCount = 0

	for plr, _ in pairs(playerStats) do
		local chance = plr:GetAttribute("garbageChance") or 0
		currentCount += chance

		if currentCount >= randomPoint then
			plr:AddTag("GarbageMan")
			return plr
		end
	end
end

return {
	init = function()
		local _onRemoved = CollectionService.TagRemoved:Connect(changePlayerCount)
		local _onAdd = CollectionService.TagAdded:Connect(changePlayerCount)

		-- Own loop, since rounds continue indefinitely
		while true do
			if state == "Lobby" then
				-- Re-wait until enough players
				if not checkForPlayers() then
					task.wait(4)
					continue
				end
				warn("We have enough players, starting")

				for i = 1, lobbyTime do
					local timeLeft = lobbyTime - i
					-- Countdown before round starts
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end

				transferPlayersToRound()

				local chosen = chooseGarbageMan()
				task.wait(4)
				warn(`${chosen} is the garbage man!`)
				task.wait(3)

				teleportPlayers()
				state = "InRound"
				continue
			end

			if state == "Intermission" then
				for i = 1, intermissionTime do
					local timeLeft = intermissionTime - i
					-- Show stats, small intermission
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end
				state = "Lobby"
				continue
			end

			if state == "InRound" then
				-- Round end
				task.delay(roundLength, function()
					local players = getPlayerInRound()
					for _, player in ipairs(players) do
						local plrStats = playerStats[player]

						-- plrStats.cash whatever
						player:RemoveTag("InRound")
					end
					table.clear(playerStats)

					state = "Intermission"
				end)

				-- Actual countdown
				for i = 1, roundLength do
					local timeLeft = roundLength - i

					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end
			end
		end
	end,
	events = {
		"changeTimerUI",
		"changePlayerCount",
	},
}
