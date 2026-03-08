local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local subscribe = Charm.subscribe
local computed = Charm.computed

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local RagdollModule = require(ReplicatedStorage.Shared.RagdollModule)
local types = require(script.Parent.types)

local roundState = atom("None")
local eventQueue = atom({})
local timeCounter = atom(0)
local playerStates = atom({})
local isProcessingEvents = atom(false)
local showGarbageManPurchase = atom(false)
local garbageMan = atom(nil)
local nextGarbageManTable: { Player } = {}
local diedConnections: { [Player]: RBXScriptConnection } = {}

-- Anti-AFK: if garbageman doesn't throw within 20s of round start, round ends
local hasThrownThisRound = atom(false)
local forceEndRoundAfk = atom(false)
local AFK_WARN_SECONDS = 10
local AFK_END_SECONDS = 20

local RUSH_THRESHOLD_SECONDS = 20 -- When this many seconds left, throw cooldown is reduced

local lobbyTime = 15
local intermissionTime = 5
local roundLength = 60
local playersNeeded = 2

local eventFunctions: { [string]: (timeLeft: number, ...any) -> () } = {}

local AliveFolder = workspace:WaitForChild("Alive") :: Folder
local IgnoreFolder = workspace:WaitForChild("Ignore") :: Folder
local Map = workspace:WaitForChild("Map") :: Folder

local IgnoreTrashFolder = IgnoreFolder:FindFirstChild("Trash") :: Folder
local RoundEvents = script.Parent:WaitForChild("RoundEvents") :: Folder
local ScriptableFolder = Map:FindFirstChild("Scriptable") :: Folder
local FirePit = ScriptableFolder:FindFirstChild("Fire") :: Part
local ArenaSpawn = ScriptableFolder:FindFirstChild("Arena") :: Part
local LobbySpawn = ScriptableFolder:FindFirstChild("Lobby") :: SpawnLocation
local GarbageManSpawn = ScriptableFolder:FindFirstChild("Ramp") :: Part

local function checkForPlayers(): boolean
	local enoughPlayers = #Players:GetPlayers() >= playersNeeded

	if not enoughPlayers then
		local totalPlayers = #Players:GetPlayers()
		-- warn(`Need ${playersNeeded - totalPlayers} more players to start.`)
		return false
	else
		return true
	end
end

local function teleportPlayers(to: "Round" | "Spawn")
	local r = math.random
	local t = playerStates()
	local function randomRel()
		return (r() * 2) - 1
	end

	if to == "Round" then
		local size = ArenaSpawn.Size
		for plr, _ in pairs(t) do
			local character = plr.Character
			if plr == garbageMan() then
				character:PivotTo(GarbageManSpawn.CFrame)
				continue
			end
			local offset = Vector3.new((size.X / 2) * randomRel(), size.Y / 2, (size.Z / 2) * randomRel())
			local possibleSpawn = (ArenaSpawn.CFrame * CFrame.new(offset))

			character:PivotTo(possibleSpawn)
		end
	else
		local size = LobbySpawn.Size

		for plr, _ in pairs(t) do
			local character = plr.Character
			local offset = Vector3.new((size.X / 2) * randomRel(), size.Y / 2, (size.Z / 2) * randomRel())
			local possibleSpawn = (LobbySpawn.CFrame * CFrame.new(offset))

			character:PivotTo(possibleSpawn)
		end
	end
end

function addDeathConnection(player: Player)
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if not humanoid then
		warn("Couldn't find Humanoid")
		return
	end

	local conn = humanoid.Died:Connect(function()
		playerStates(function(old)
			local new = table.clone(old)
			new[player] = nil
			return new
		end)
		local states = playerStates()
		local gm = garbageMan()
		local survivorsLeft = 0
		for plr, _ in pairs(states) do
			if plr ~= gm then survivorsLeft += 1 end
		end
		local showBottomButtons = survivorsLeft > 0
		EventHandler:fireClient(player, "onDeathScreen", true, showBottomButtons)
	end)

	diedConnections[player] = conn
end

local function transferPlayersToRound()
	for _, player in Players:GetPlayers() do
		if player:HasTag("AFK") then
			continue
		end
		playerStates(function(new)
			new = table.clone(new)
			new[player] = {
				cash = 0,
				kills = 0,
				survivedTime = 0,
			}
			return new
		end)
	end
end

local function chooseGarbageMan()
	--! Immediately check if someone purchased to become garbage man next round.
	if #nextGarbageManTable > 0 then
		local chosen = nextGarbageManTable[1]
		table.remove(nextGarbageManTable, 1)

		if chosen and chosen.Parent == Players then
			if garbageMan() == nil then
				garbageMan(chosen)
			end

			for i, waitingPlr in ipairs(nextGarbageManTable) do
				warn(`{waitingPlr.Name} is still in queue (Position {i}).`)
				EventHandler:fireClient(waitingPlr, "sendNotification", `You are still in the queue for Garbage Man. You will be chosen in {i} rounds.`)
			end

			return chosen
		else
			return chooseGarbageMan()
		end
	end

	-- ? Choosing logic: weight = baseChance * (2x Garbage Man pass 2x)
	local function getGarbageManMultiplier(plr: Player): number
		local mult = 1
		local plrData = Data.grabData(plr)
		if plrData and plrData.passes["2x_garbage_man"] then
			mult *= 2
		end
		return mult
	end

	local total = 0
	local t = playerStates()

	for plr, _ in pairs(t) do
		local baseChance = plr:GetAttribute("garbageChance") or 0
		local multiplier = getGarbageManMultiplier(plr)
		total += (baseChance * multiplier)
	end

	-- Adjusted Fallback: If no one has "garbageChance" (total is 0),
	-- we give everyone a base weight but still respect 2x Garbage Man pass.
	if total <= 0 then
		local weightedPlayers = {}
		local fallbackTotal = 0

		for plr, _ in pairs(t) do
			local weight = getGarbageManMultiplier(plr)
			table.insert(weightedPlayers, { player = plr, weight = weight })
			fallbackTotal += weight
		end

		if fallbackTotal == 0 then
			return nil
		end -- Server is empty

		local randomPoint = math.random() * fallbackTotal
		local currentCount = 0

		for _, entry in ipairs(weightedPlayers) do
			currentCount += entry.weight
			if currentCount >= randomPoint then
				garbageMan(entry.player)
				return entry.player
			end
		end
	end

	local randomPoint = math.random() * total
	local currentCount = 0

	for plr, _ in pairs(t) do
		local baseChance = plr:GetAttribute("garbageChance") or 0
		local multiplier = getGarbageManMultiplier(plr)
		currentCount += (baseChance * multiplier)

		if currentCount >= randomPoint then
			garbageMan(plr)
			return plr
		end
	end

	return nil
end

local function onTouch(hitPart: BasePart)
	local characterModel = hitPart.Parent
	if not characterModel or not characterModel:IsA("Model") then
		warn("No character.")
		return
	end

	local player = Players:GetPlayerFromCharacter(characterModel)
	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")

	if not player or not humanoid or humanoid.Health <= 0 then
		warn("No player, or humanoid is dead/nil")
		return
	end
	if not playerStates()[player] then
		warn("Player isn't in round.")
		return
	end

	humanoid.Health = 0

	local states = playerStates()
	local gm = garbageMan()
	local survivorsExcludingThis = 0
	for plr, _ in pairs(states) do
		if plr ~= gm and plr ~= player then survivorsExcludingThis += 1 end
	end
	local showBottomButtons = survivorsExcludingThis > 0
	EventHandler:fireClient(player, "onDeathScreen", true, showBottomButtons)

	task.defer(function()
		if playerStates()[player] then
			RagdollModule.Ragdoll(characterModel)
			playerStates(function(old)
				local new = table.clone(old)
				new[player] = nil
				return new
			end)
		end
	end)
end

local function processQueue()
	if isProcessingEvents() then
		return
	end

	isProcessingEvents(true)

	task.spawn(function()
		while roundState() == "InRound" do
			local queue = eventQueue()

			-- ? if empty, stop
			if #queue == 0 then
				break
			end

			local nextEventName = queue[1]

			-- ? Pop first
			eventQueue(function(old): { "Avalanche" | "Fog" | "Ice" | "None" }
				local new = table.clone(old)
				table.remove(new, 1)
				return new
			end)

			local handler = eventFunctions[nextEventName]
			if handler then
				local timeLeft = lobbyTime - timeCounter()
				handler(timeLeft)
			end

			if roundState() ~= "InRound" then
				break
			end

			task.wait(1)
		end

		isProcessingEvents(false)
	end)
end

local function awardRewards()
	local finalStates = playerStates()
	local gm: Player = garbageMan()
	local survivorsLeft = 0
	local COINS_PER_SECOND = 0.5
	local COINS_PER_KILL = 1.3
	local WIN_BONUS_COINS = 10

	-- Count remaining survivors
	for plr, stats in pairs(finalStates) do
		if plr ~= gm then
			survivorsLeft += 1
		end
	end

	local survivorsWon = survivorsLeft > 0
	local gmWon = survivorsLeft == 0

	--  Handle Survivor Rewards
	for plr, stats in pairs(finalStates) do
		if plr ~= gm then
			local plrData = Data.grabData(plr)
			-- Participating Coins (Based on survival time/participation)
			local timeSurvived = stats.survivedTime
			local coinsEarned = math.floor(timeSurvived * COINS_PER_SECOND)
			local crownsEarned = 0

			if survivorsWon then
				--  Add Win Bonus & Trophy
				coinsEarned += WIN_BONUS_COINS
				crownsEarned = 1
				plrData.crowns += 1
			end

			local earnedParts: { string } = {}
			if coinsEarned > 0 then
				table.insert(earnedParts, `{coinsEarned} coins`)
			end
			if crownsEarned > 0 then
				table.insert(earnedParts, `{crownsEarned} trophy`)
			end
			local earnedSuffix = #earnedParts > 0 and (" You earned " .. table.concat(earnedParts, " and ") .. ".") or ""

			if survivorsWon then
				EventHandler:fireClient(plr, "sendNotification", "You won the round!" .. earnedSuffix)
			else
				EventHandler:fireClient(plr, "sendNotification", "You survived the round!" .. earnedSuffix)
			end
			Data.mutateCurrency(plr, "coins", plrData.coins + coinsEarned)
			Data.mutateCurrency(plr, "crowns", plrData.crowns + crownsEarned)
		end
	end

	-- Handle Garbage Man Rewards
	if gm then
		-- Participation Coins
		local coinsRewarded = 25
		local crownsEarned = 0
		local gmData = Data.grabData(gm)
		local gmState = playerStates()[gm]

		if gmWon then
			-- Trophy for eliminating everyone
			crownsEarned += 1

			-- Reward per death
			coinsRewarded += math.floor(gmState.kills * COINS_PER_KILL)
		end

		local gmEarnedParts: { string } = {}
		if coinsRewarded > 0 then
			table.insert(gmEarnedParts, `{coinsRewarded} coins`)
		end
		if crownsEarned > 0 then
			table.insert(gmEarnedParts, `{crownsEarned} crowns`)
		end
		local gmEarnedSuffix = #gmEarnedParts > 0 and (" You earned " .. table.concat(gmEarnedParts, " and ") .. ".") or ""
		if gmWon then
			EventHandler:fireClient(gm, "sendNotification", "You are the Garbage Man!" .. gmEarnedSuffix)
		end

		Data.mutateCurrency(gm, "coins", gmData.coins + coinsRewarded)
		Data.mutateCurrency(gm, "crowns", gmData.crowns + crownsEarned)
	end
end

ServerEvents.sendRoundEvent:Connect(function(eventName: types.EventStates)
	eventQueue(function(old): { "Avalanche" | "Fog" | "Ice" | "None" }
		local new = table.clone(old)
		table.insert(new, eventName)
		-- EventHandler:broadcast("sendNotification", `Your ${eventName} event will play in {#old} rounds.`)
		return new
	end)
	warn(`Added ${eventName}`)
end)

ServerEvents.sendRevive:Connect(function(player: Player)
	local isRoundActive = (roundState() == "InRound")
	local isAlreadyInRound = playerStates()[player]

	if isRoundActive and not isAlreadyInRound then
		ServerEvents.canRevive:Fire(player, true)

		player:LoadCharacterAsync()

		playerStates(function(new)
			new = table.clone(new)
			new[player] = {
				cash = 0,
				kills = 0,
				survivedTime = 0,
			}
			return new
		end)

		local r = math.random
		local function randomRel()
			return (r() * 2) - 1
		end

		local character = player.Character
		if character then
			local size = ArenaSpawn.Size
			local offset = Vector3.new((size.X / 2) * randomRel(), size.Y / 2, (size.Z / 2) * randomRel())
			local possibleSpawn = (ArenaSpawn.CFrame * CFrame.new(offset))
			character:PivotTo(possibleSpawn)
		end
	else
		warn(
			`[ReviveLogic] Denying revive for {player.Name}. Round Active: {isRoundActive}, In Tag: {isAlreadyInRound}`
		)
		ServerEvents.canRevive:Fire(player, false)
	end
end)

ServerEvents.forceChooseGarbageMan:Connect(function(player: Player)
	-- Prevent duplicates in the queue
	if table.find(nextGarbageManTable, player) then
		warn(`{player.Name} is already in the Garbage Man queue.`)
		return
	end

	table.insert(nextGarbageManTable, player)
	showGarbageManPurchase(false)

	-- If they aren't the only one in the queue, warn them they are waiting
	if #nextGarbageManTable > 1 then
		warn(`{player.Name} bought Garbage Man, but there is a queue. They are position {#nextGarbageManTable}.`)
		EventHandler:fireClient(player, "sendNotification", `You bought Garbage Man! But there is a queue. You're in position {#nextGarbageManTable}.`)
	end
end)

ServerEvents.onGarbageManKill:Connect(function(who: Player)
	playerStates(function(old)
		local new = table.clone(old)
		if new[who] then
			new[who].kills += 1
		end
		return new
	end)
end)

	return {
	getRoundTimeLeft = function()
		return timeCounter()
	end,
	getRoundState = function()
		return roundState()
	end,
	init = function()
		EventHandler:connect("requestRevive", function(player: Player)
			player:LoadCharacterAsync()
		end)

		-- Anti-AFK: mark that garbageman has thrown so we don't end the round
		EventHandler:connect("throwTrash", function(player: Player)
			if player == garbageMan() then
				hasThrownThisRound(true)
			end
		end)

		-- ? Setup fire pit
		FirePit.Touched:Connect(onTouch)

		-- ? Load events
		local eventList = RoundEvents:GetChildren() :: { ModuleScript }
		for _, module in ipairs(eventList) do
			local f = require(module) :: (timeLeft: number) -> ()
			eventFunctions[module.Name] = f
		end

		-- ? UI change for timer
		subscribe(timeCounter, function(count, _prev)
			EventHandler:broadcast("changeTimerUI", count)
		end)

		-- ? Dynamics for playerState change
		subscribe(playerStates, function(state, prev)
			-- ? Check for players that were removed
			-- Inside: subscribe(playerStates, function(state, prev) ...
			for plr, _ in prev do
				if not state[plr] then
					plr:RemoveTag("InRound")

					-- If the person who died/left was the Garbage Man, clear the atom
					if garbageMan() == plr then
						garbageMan(nil)
					end

					if diedConnections[plr] then
						diedConnections[plr]:Disconnect()
						diedConnections[plr] = nil
					end
				end
			end

			-- ? Check for players that were added
			for plr, _ in state do
				if not prev[plr] then
					-- This was the player who was added
					if plr and plr.Parent == Players then
						plr:AddTag("InRound")
					end
					addDeathConnection(plr)
				end
			end
		end)

		-- ? Change in count of normal players in round
		local nonGarbageManCount = computed(function()
			local states = playerStates()
			local count = 0
			for plr, _ in states do
				if not plr:HasTag("GarbageMan") then
					count += 1
				end
			end
			return count
		end)

		-- ? UI Response for ^
		subscribe(nonGarbageManCount, function(state, prev)
			EventHandler:broadcast("changePlayerCount", state)
		end)

		-- ? Processing events, whenever eventQueue has changed
		subscribe(eventQueue, function(state, prev)
			if not isProcessingEvents() then
				processQueue()
			end
		end)

		-- ? Showing buying garbage man button
		subscribe(showGarbageManPurchase, function(state, prev)
			for _, plr in ipairs(Players:GetChildren()) do
				EventHandler:fireClient(plr, "becomeGarbageManToggle", state)
			end
		end)

		-- ? Sound Logic
		local currentMusic = nil
		-- Runs whenever roundState changes.
		local currentMusicId = computed(function()
			local s = roundState() :: types.RoundStates
			if s == "Lobby" then
				local sounds = {
					"1848354536",
					"1841647093",
					"9047876673",
				}
				local randomId = sounds[math.random(1, #sounds)]
				return `rbxassetid://{randomId}`
			elseif s == "InRound" then
				return `rbxassetid://1846458016`
			elseif s == "Intermission" then
				return `rbxassetid://1844584698`
			end

			return nil
		end)

		-- runs whenever the readonly currentMusicId changes
		subscribe(currentMusicId, function(id, _prevId)
			if id == nil then
				return
			end

			if currentMusic then
				currentMusic:Stop()
				currentMusic:Destroy()
				currentMusic = nil
			end

			local sound = Instance.new("Sound")
			sound.Name = "RoundServiceSound"
			sound.SoundId = id
			sound.Parent = workspace
			sound.Volume = 0.3
			sound:Play()
			currentMusic = sound
		end)

		-- ? garbage man subscriber
		subscribe(garbageMan, function(newMan: Player?, oldMan: Player?)
			-- 1. Remove from the previous guy
			if oldMan then
				oldMan:RemoveTag("GarbageMan")
			end

			-- 2. Add to the new guy
			if newMan then
				-- Optional: Double check to remove from others just in case of state desync
				for _, plr in Players:GetPlayers() do
					if plr ~= newMan and plr:HasTag("GarbageMan") then
						plr:RemoveTag("GarbageMan")
					end
				end

				newMan:AddTag("GarbageMan")
			end
		end)

		-- ? round state logic
		subscribe(roundState, function(s: types.RoundStates, _prev: types.RoundStates)
			if s == "Lobby" then
				print()
			elseif s == "InRound" then
				showGarbageManPurchase(false)
				transferPlayersToRound()
				chooseGarbageMan()
				teleportPlayers("Round")

				processQueue()
			elseif s == "Intermission" then
				awardRewards()
				teleportPlayers("Spawn")
				playerStates({})
				garbageMan(nil)
				-- Clear garbage
				for _, v in IgnoreTrashFolder:GetChildren() do
					v:Destroy()
				end
				-- Prompt show become garbageman pass
				showGarbageManPurchase(true)
			end
		end)

		-- Shared state for rush mode (GarbageManHandler reads this; no cross-require)
		local serverFolder = ServerScriptService:WaitForChild("Server") :: Folder
		local existing = serverFolder:FindFirstChild("RushMode")
		local rushModeValue: BoolValue = if existing and existing:IsA("BoolValue") then existing else (function()
			local v = Instance.new("BoolValue")
			v.Name = "RushMode"
			v.Value = false
			v.Parent = serverFolder
			return v
		end)()

		while true do
			roundState("Lobby")

			while not checkForPlayers() do
				local total = #Players:GetPlayers()
				EventHandler:broadcast("sendNotification", `Not enough players to start the round. Need {playersNeeded - total} more.`)
				task.wait(15)
			end

			for i = lobbyTime, 0, -1 do
				timeCounter(i)
				task.wait(1)
			end

			EventHandler:broadcast("sendNotification", "Round starting!")
			roundState("InRound")
			hasThrownThisRound(false)
			forceEndRoundAfk(false)
			rushModeValue.Value = false
			local hasNotifiedRush = false

			-- Anti-AFK: warn at 10s, end round at 20s if garbageman hasn't thrown
			task.spawn(function()
				local gm = garbageMan()
				if not gm then
					return
				end
				task.wait(AFK_WARN_SECONDS)
				if roundState() ~= "InRound" or garbageMan() ~= gm then
					return
				end
				if not hasThrownThisRound() then
					EventHandler:fireClient(gm, "sendNotification", "Wake up! Throw some trash!")
				end
				task.wait(AFK_END_SECONDS - AFK_WARN_SECONDS)
				if roundState() ~= "InRound" or garbageMan() ~= gm then
					return
				end
				if not hasThrownThisRound() then
					EventHandler:fireClient(gm, "sendNotification", "Round ended — you were AFK!")
					forceEndRoundAfk(true)
				end
			end)

			for i = roundLength, 0, -1 do
				timeCounter(i)

				-- Notify GM once when rush mode starts (20 seconds left); set shared state for throw cooldown
				if i <= RUSH_THRESHOLD_SECONDS and not hasNotifiedRush then
					hasNotifiedRush = true
					rushModeValue.Value = true
					local gm = garbageMan()
					if gm then
						EventHandler:fireClient(gm, "sendNotification", "Rush mode! Throw cooldown reduced!")
					end
				end

				for plr, stat in pairs(playerStates()) do
					stat.survivedTime += 1
				end

				-- ! Break early if there are no more normal players, or no garbage man
				if nonGarbageManCount() == 0 or garbageMan() == nil then
					break
				end
				-- ! Break early if garbageman was AFK (no throw within 20s)
				if forceEndRoundAfk() then
					break
				end

				task.wait(1)
			end

			roundState("Intermission")
			rushModeValue.Value = false

			for i = intermissionTime, 0, -1 do
				timeCounter(i)
				task.wait(1)
			end
		end
	end,
	events = {
		"changeTimerUI",
		"changePlayerCount",
		"fogEventClient",
		"onDeathScreen",
		"requestRevive",
		"becomeGarbageManToggle",
	},
}
