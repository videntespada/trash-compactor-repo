local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TrashClass = require(ServerScriptService.Server.Classes.TrashClass)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local NORMAL_THROW_COOLDOWN = 1
local RUSH_THROW_COOLDOWN = 0.5
local RUSH_TIME_LEFT_THRESHOLD = 20

local DEBUG_THROW = true
local function debug(msg: string)
	if DEBUG_THROW then
		print("[GarbageManHandler]", msg)
	end
end

return {
	init = function()
		debug("init started")
		local Map = workspace:WaitForChild("Map") :: Folder
		local Scriptable = Map:FindFirstChild("Scriptable") :: Folder
		local PlaceZone = Scriptable:FindFirstChild("PlaceZone") :: Part
		local Assets = ReplicatedStorage:WaitForChild("Assets")
		local TrashAssets = Assets:FindFirstChild("Trash") :: Folder
		local toThrow: Model

		local modelToClass: {
			{
				model: Model,
				class: TrashClass.TrashClass,
			}
		} = {}

		local function chooseNewTrash(): Model
			local t = TrashAssets:GetChildren() :: { Model }
			local chosen = t[math.random(1, #t)]:Clone()
			chosen.Parent = workspace["Ignore"]["Trash"]
			return chosen
		end

		-- When they click to place
		local connectResult = EventHandler:connect("throwTrash", function(player: Player, start: CFrame)
			debug(`throwTrash received from {player.Name}`)
			if not player:HasTag("GarbageMan") then
				debug(`throwTrash REJECT: {player.Name} does not have GarbageMan tag`)
				return
			end
			if player:HasTag("ThrowDB") then
				debug(`throwTrash REJECT: {player.Name} has ThrowDB (cooldown)`)
				return
			end

			if not toThrow or not toThrow.Parent then
				toThrow = chooseNewTrash()
				debug(`throwTrash: chose new trash, toThrow={toThrow and toThrow.Name or "nil"}`)
			end

			-- Debounce: much shorter when 20 seconds or less left (rush mode) via shared BoolValue from RoundService
			local cooldown = NORMAL_THROW_COOLDOWN
			do
				local server = ServerScriptService:FindFirstChild("Server")
				local rushVal = server and server:FindFirstChild("RushMode")
				if rushVal and rushVal:IsA("BoolValue") and rushVal.Value then
					cooldown = RUSH_THROW_COOLDOWN
				end
			end
			player:AddTag("ThrowDB")
			task.delay(cooldown, function()
				player:RemoveTag("ThrowDB")
			end)

			local character = player.Character
			if not character then
				debug(`throwTrash REJECT: {player.Name} has no Character`)
				return
			end

			debug(`throwTrash EXECUTE: {player.Name}, cooldown={cooldown}`)
			-- Throw Mechanic
			toThrow:PivotTo(start)

			local bv = Instance.new("BodyVelocity")
			bv.Parent = toThrow:FindFirstChild("Part") :: Part
			bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
			bv.Velocity = (PlaceZone.CFrame.RightVector * -30) + Vector3.yAxis * 20
			Debris:AddItem(bv, 0.1)

			-- Attach TrashClass for behavior
			local trashClass = TrashClass.new(player, toThrow, false)
			Debris:AddItem(toThrow, 10)

			trashClass:CreateBounding()
			trashClass:StartHitbox()

			local iter = #modelToClass + 1
			modelToClass[iter] = {
				model = toThrow,
				class = trashClass,
			}
			toThrow.AncestryChanged:Once(function(parent)
				if parent == nil then
					modelToClass[iter].class:Clean()
				end
			end)

			-- Throwing Sound
			local sound = Instance.new("Sound")
			sound.Parent = character.PrimaryPart
			sound.SoundId = "rbxassetid://9118617342"
			sound.Volume = 2
			sound.Ended:Once(function()
				sound:Destroy()
			end)
			sound:Play()

			-- Choose new to throw down.
			local chosen = chooseNewTrash()
			toThrow = chosen
			EventHandler:fireClient(player, "changeTrash", chosen.Name)
			debug(`throwTrash DONE: {player.Name}`)
		end)
		if typeof(connectResult) == "string" then
			warn("[GarbageManHandler] connect(throwTrash) failed:", connectResult)
		else
			debug("connect(throwTrash) OK")
		end

		-- ? Bomb breaking trash
		ServerEvents.bombBreakTrash:Connect(function(model: Model)
			for i = 1, #modelToClass do
				if modelToClass[i].model == model then
					local foundModel = modelToClass[i].model
					for _, v in ipairs(foundModel:GetDescendants()) do
						if v:IsA("WeldContraint") or v:IsA("Weld") then
							v:Destroy()
						end
						if v:IsA("Part") or v:IsA("MeshPart") then
							v.CanCollide = false
						end
					end
				end
			end
		end)

		-- ? Enabling/Disaibling mechanics.
		CollectionService:GetInstanceAddedSignal("GarbageMan"):Connect(function(a)
			if a:IsA("Player") then
				local newGM = a
				debug(`GarbageMan tag added to {newGM.Name} - enabling visualization`)
				-- Ensure all other players have throw UI hidden (e.g. mobile)
				for _, other in Players:GetPlayers() do
					if other ~= newGM then
						EventHandler:fireClient(other, "toggleGarbageVisualization", false)
					end
				end
				-- Enable for the new GM
				toThrow = chooseNewTrash()
				EventHandler:fireClient(newGM, "changeTrash", toThrow.Name)
				EventHandler:fireClient(newGM, "toggleGarbageVisualization", true)
			end
		end)

		CollectionService:GetInstanceRemovedSignal("GarbageMan"):Connect(function(a)
			if a:IsA("Player") then
				local player = a
				debug(`GarbageMan tag removed from {player.Name}`)
				EventHandler:fireClient(player, "toggleGarbageVisualization", false)
			end
		end)
		debug("init finished")
	end,
	events = {
		"throwTrash",
		"toggleGarbageVisualization",
		"changeTrash",
	},
}
