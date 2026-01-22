local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local types = require(script.Parent.types)

local state: types.RoundStates = "Lobby"
local currentEvent: types.EventStates = "None"
local lobbyTime = 30
local intermissionTime = 5
local roundLength = 60
local playersNeeded = 2

local playerStats: { [Player]: {
	kills: number,
	cash: number,
} } = {}

local AliveFolder = workspace:WaitForChild("Alive") :: Folder
local Map = workspace:WaitForChild("Map") :: Folder
local ScriptableFolder = Map:FindFirstChild("Scriptable") :: Folder
local FirePit = ScriptableFolder:FindFirstChild("Fire") :: Part
local ArenaSpawn = ScriptableFolder:FindFirstChild("Arena") :: Part
local LobbySpawn = ScriptableFolder:FindFirstChild("Lobby") :: SpawnLocation
local GarbageManSpawn = ScriptableFolder:FindFirstChild("Ramp") :: Part

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

local function teleportPlayers(to: "Round" | "Spawn")
	if to == "Round" then
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
	else
		local r = math.random
		local size = LobbySpawn.Size

		local function randomRel()
			return (r() * 2) - 1
		end

		for plr, _ in pairs(playerStats) do
			local character = plr.Character
			local offset = Vector3.new((size.X / 2) * randomRel(), size.Y / 2, (size.Z / 2) * randomRel())
			local possibleSpawn = (LobbySpawn.CFrame * CFrame.new(offset))

			character:PivotTo(possibleSpawn)
		end
	end
end

function addToRound(player: Player)
	player:AddTag("InRound")
	playerStats[player] = {
		cash = 0,
		kills = 0,
	}
end

function removeFromRound(player: Player)
	if player:HasTag("GarbageMan") then
		player:RemoveTag("GarbageMan")
	end
	player:RemoveTag("InRound")
	playerStats[player] = nil
end

local function transferPlayersToRound()
	for _, player in Players:GetPlayers() do
		if player:HasTag("AFK") then
			continue
		end
		addToRound(player)
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

local function onTouch(hitPart: BasePart)
	if not hitPart.Parent then
		return
	end
	-- warn(`[FirePit] Touched by: {hitPart.Name} (Parent: {hitPart.Parent.Name})`)

	-- ? Character validation
	local characterModel = hitPart.Parent
	if not characterModel or not characterModel:IsA("Model") then
		return
	end

	if characterModel.Parent ~= AliveFolder then
		-- warn(`[FirePit] Ignored {characterModel.Name}: Not in Alive folder (Currently in: {characterModel.Parent})`)
		return
	end

	local player = Players:GetPlayerFromCharacter(characterModel)
	if not player then
		-- warn(`[FirePit] ${characterModel.Name} does not have a player`)
		return
	end

	if not player:HasTag("InRound") then
		-- warn(`[FirePit] HIT {player.Name} but they have NO 'InRound' tag!`)
		return
	end

	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- warn(`[FirePit] KILLING {player.Name}! They were valid and InRound.`)

	-- ? Get total amount to remove, and kill
	humanoid:TakeDamage(humanoid.MaxHealth)

	-- ? remove from round
	removeFromRound(player)
end

return {
	init = function()
		local _onRemoved = CollectionService.TagRemoved:Connect(changePlayerCount)
		local _onAdd = CollectionService.TagAdded:Connect(changePlayerCount)

		-- Setup fire pit
		FirePit.Touched:Connect(onTouch)

		-- Own loop, since rounds continue indefinitely
		while true do
			if state == "Lobby" then
				local sounds = {
					"1848354536",
					"1841647093",
					"9047876673",
				}

				local currentMusic = nil
				local randomId = sounds[math.random(1, #sounds)]

				currentMusic = Instance.new("Sound")
				currentMusic.Parent = workspace
				currentMusic.SoundId = `rbxassetid://{randomId}`
				currentMusic.Volume = 1

				currentMusic.Ended:Connect(function()
					currentMusic:Destroy()
					currentMusic = nil
				end)

				while not checkForPlayers() do
					if not currentMusic or not currentMusic.IsPlaying then
						local randomId2 = sounds[math.random(1, #sounds)]

						currentMusic = Instance.new("Sound")
						currentMusic.Parent = workspace
						currentMusic.SoundId = `rbxassetid://{randomId2}`
						currentMusic.Volume = 1
						currentMusic:Play()
					end

					task.wait(1)
				end

				warn("We have enough players, starting")

				for i = 1, lobbyTime do
					local timeLeft = lobbyTime - i
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end

				transferPlayersToRound()

				local chosen = chooseGarbageMan()
				task.wait(4)
				warn(`${chosen} is the garbage man!`)
				if currentMusic then
					currentMusic:Stop()
					currentMusic:Destroy()
					currentMusic = nil
				end
				task.wait(3)

				teleportPlayers("Round")
				state = "InRound"
				continue
			end

			if state == "Intermission" then
				for i = 1, intermissionTime do
					local timeLeft = intermissionTime - i
					-- TODO: Show stats, small intermission
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end
				state = "Lobby"
				continue
			end

			if state == "InRound" then
				local roundMusic = Instance.new("Sound")
				roundMusic.Parent = workspace
				roundMusic.SoundId = `rbxassetid://{1846458016}`
				roundMusic.Volume = 1
				roundMusic.Looped = true
				roundMusic:Play()

				for i = 1, roundLength do
					local timeLeft = roundLength - i
					EventHandler:broadcast("changeTimerUI", timeLeft)

					local alivePlayers = Players:QueryDescendants(".InRound:not(.GarbageMan)") :: { Player }
					if #alivePlayers <= 0 then
						teleportPlayers("Spawn")
						break
					end

					-- TODO: Make Ice Event
					-- TODO: Make Avalanche Event
					-- TODO: Make Fog Event
					if currentEvent ~= "None" then
					end

					task.wait(1)
				end

				if roundMusic then
					roundMusic:Stop()
					roundMusic:Destroy()
				end

				-- ! Round End
				local players = getPlayerInRound()
				for _, player in ipairs(players) do
					-- TODO: Check stats/award cash here
					-- local plrStats = playerStats[player]

					removeFromRound(player)
				end
				table.clear(playerStats)

				local endSound = Instance.new("Sound")
				endSound.Parent = workspace
				endSound.SoundId = `rbxassetid://{1844584698}`
				endSound.Volume = 1
				endSound.Ended:Once(function()
					endSound:Destroy()
				end)
				endSound:Play()

				state = "Intermission"
				continue
			end
		end
	end,
	events = {
		"changeTimerUI",
		"changePlayerCount",
	},
}
