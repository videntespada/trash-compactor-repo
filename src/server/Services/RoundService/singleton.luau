local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local subscribe = Charm.subscribe
local computed = Charm.computed

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local RagdollModule = require(ReplicatedStorage.Shared.RagdollModule)
local types = require(script.Parent.types)

local roundState: Charm.Atom<types.RoundStates> = atom("None")
local eventQueue: Charm.Atom<{ types.EventStates }> = atom({})
local timeCounter: Charm.Atom<number> = atom(0)
local playerCounter: Charm.Atom<number> = atom(0)
local playerStates: Charm.Atom<{
	[Player]: {
		kills: number,
		cash: number,
	},
}> = atom({})
local isProcessingEvents: Charm.Atom<boolean> = atom(false)
local diedConnections: { [Player]: RBXScriptConnection } = {}

local lobbyTime = 15
local intermissionTime = 5
local roundLength = 600
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

local function changePlayerCount(tag: string)
	if tag == "InRound" then
		local amount = #CollectionService:GetTagged(tag)
		playerCounter(amount)
	end
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
			if plr:HasTag("GarbageMan") then
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
	else
		-- print("Found Humanoid")
	end

	local conn = humanoid.Died:Connect(function()
		-- warn(`Fired onDeathScreen for ${character.Name}`)
		-- Remove their InRound tag immediately.
		if player:HasTag("InRound") then
			player:RemoveTag("InRound")
		end
		EventHandler:fireClient(player, "onDeathScreen", true)
		playerCounter(playerCounter() - 1)
		task.delay(10, function()
			-- ? Some sort of check if they still havent bought a revive or revenge.
			EventHandler:fireClient(player, "onDeathScreen", false)
		end)
	end)

	repeat
		task.wait()
	until conn.Connected
	-- warn(`Connected ${player.Name}`)

	diedConnections[player] = conn
end

function removeDeathConnection(player: Player)
	diedConnections[player]:Disconnect()
	diedConnections[player] = nil
end

function addToRound(player: Player)
	player:AddTag("InRound")
	playerStates(function(new)
		new = table.clone(new)
		new[player] = {
			cash = 0,
			kills = 0,
		}
		return new
	end)
	playerCounter(playerCounter() + 1)
	addDeathConnection(player)
end

function removeFromRound(player: Player)
	if player:HasTag("GarbageMan") then
		player:RemoveTag("GarbageMan")
	end
	player:RemoveTag("InRound")
	playerStates(function(new)
		new = table.clone(new)
		new[player] = nil
		return new
	end)
	changePlayerCount("InRound")
	removeDeathConnection(player)
end

local function transferPlayersToRound()
	for _, player in Players:GetPlayers() do
		if player:HasTag("AFK") then
			continue
		end
		addToRound(player)
	end
end

local function chooseGarbageMan()
	local total = 0
	local t = playerStates()

	for plr, _ in pairs(t) do
		local chance = plr:GetAttribute("garbageChance") or 0
		total += chance
	end

	if total <= 0 then
		local players = {}
		for plr, _ in pairs(t) do
			table.insert(players, plr)
		end
		print(players)
		local chosen = players[math.random(#players)]
		chosen:AddTag("GarbageMan")
		return chosen
	end

	local randomPoint = math.random() * total
	local currentCount = 0

	for plr, _ in pairs(t) do
		local chance = plr:GetAttribute("garbageChance") or 0
		currentCount += chance

		if currentCount >= randomPoint then
			plr:AddTag("GarbageMan")
			return plr
		end
	end

	return nil
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

	RagdollModule.Ragdoll(characterModel)

	-- ? Get total amount to remove, and kill
	humanoid:TakeDamage(humanoid.MaxHealth)

	-- ? remove from round
	removeFromRound(player)
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

ServerEvents.sendRoundEvent:Connect(function(eventName: types.EventStates)
	eventQueue(function(old): { "Avalanche" | "Fog" | "Ice" | "None" }
		local new = table.clone(old)
		table.insert(new, eventName)
		return new
	end)
	-- TODO: UI Notification of which round the event will play
	warn(`Added ${eventName}`)
end)

ServerEvents.sendRevive:Connect(function(player: Player)
	local isRoundActive = (roundState() == "InRound")
	local isAlreadyInRound = player:HasTag("InRound")

	if isRoundActive and not isAlreadyInRound then
		ServerEvents.canRevive:Fire(player, true)

		addToRound(player)

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

return {
	init = function()
		local _onRemoved = CollectionService.TagRemoved:Connect(changePlayerCount)
		local _onAdd = CollectionService.TagAdded:Connect(changePlayerCount)

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

		-- ? UI change for players
		subscribe(playerCounter, function(count, _prev)
			EventHandler:broadcast("changePlayerCount", count)
		end)

		subscribe(eventQueue, function(state, prev)
			if not isProcessingEvents() then
				processQueue()
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
				currentMusic = nil
			end

			local sound = Instance.new("Sound")
			sound.Name = "RoundServiceSound"
			sound.SoundId = id
			sound.Parent = workspace
			sound:Play()
			currentMusic = sound
		end)

		-- ? round state logic
		subscribe(roundState, function(s: types.RoundStates, _prev: types.RoundStates)
			if s == "Lobby" then
				print()
			elseif s == "InRound" then
				transferPlayersToRound()
				chooseGarbageMan()
				teleportPlayers("Round")

				processQueue()
			elseif s == "Intermission" then
				teleportPlayers("Spawn")
				-- Remove tags
				for _, player in Players:GetPlayers() do
					if player:HasTag("GarbageMan") then
						player:RemoveTag("GarbageMan")
					end
					player:RemoveTag("InRound")
				end
				-- Clear garbage
				for _, v in IgnoreTrashFolder:GetChildren() do
					v:Destroy()
				end
				-- TODO: Show stats
			end
		end)

		while true do
			roundState("Lobby")

			while not checkForPlayers() do
				task.wait(1)
			end

			for i = lobbyTime, 0, -1 do
				timeCounter(i)
				task.wait(1)
			end

			roundState("InRound")

			for i = roundLength, 0, -1 do
				timeCounter(i)

				-- ! Break early if all players that arent GarbageMan has died
				local alivePlayers = Players:QueryDescendants(".InRound:not(.GarbageMan)") :: { Player }
				if #alivePlayers <= 0 then
					break
				end

				task.wait(1)
			end

			roundState("Intermission")

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
	},
}
