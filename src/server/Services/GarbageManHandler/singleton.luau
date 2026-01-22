local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TrashClass = require(ServerScriptService.Server.Classes.TrashClass)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local Assets = ReplicatedStorage:WaitForChild("Assets")
		local TrashAssets = Assets:FindFirstChild("Trash") :: Folder
		local toThrow: Model

		local function chooseNewTrash(): Model
			local t = TrashAssets:GetChildren() :: { Model }
			local chosen = t[math.random(1, #t)]:Clone()
			chosen.Parent = workspace["Ignore"]["Trash"]
			return chosen
		end

		-- When they click to place
		EventHandler:connect("throwTrash", function(player: Player, start: CFrame)
			if not player:HasTag("GarbageMan") then
				return
			end
			if player:HasTag("ThrowDB") then
				return
			end

			-- Debounce
			player:AddTag("ThrowDB")
			task.delay(1, function()
				player:RemoveTag("ThrowDB")
			end)

			local character = player.Character

			-- Throw Mechanic
			toThrow:PivotTo(start)

			local bv = Instance.new("BodyVelocity")
			bv.Parent = toThrow:FindFirstChild("Part") :: Part
			bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
			bv.Velocity = (character:GetPivot().LookVector * 50) + Vector3.yAxis * 20
			Debris:AddItem(bv, 0.1)

			-- Attach TrashClass for behavior
			local trashClass = TrashClass.new(toThrow, false)
			trashClass:CreateBounding()
			trashClass:StartHitbox()
			Debris:AddItem(toThrow, 5)

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
		end)

		-- Enabling/Disaibling mechanics.
		CollectionService.TagAdded:Connect(function(tag)
			if tag == "GarbageMan" then
				local tagged = CollectionService:GetTagged(tag)
				local player = tagged[1] :: Player

				-- ! Enable
				task.wait(6)
				-- Choose first trash
				toThrow = chooseNewTrash()
				EventHandler:fireClient(player, "changeTrash", toThrow.Name)
				EventHandler:fireClient(player, "toggleGarbageVisualization", true)
				print("Enabling garbage visualization stuff")
			end
		end)

		CollectionService.TagRemoved:Connect(function(tag)
			if tag == "GarbageMan" then
				local player = CollectionService:GetTagged(tag) :: Player

				-- ! Disaible
				print("disaibling")
				EventHandler:fireClient(player, "toggleGarbageVisualization", false)
			end
		end)
	end,
	events = {
		"throwTrash",
		"toggleGarbageVisualization",
		"changeTrash",
	},
}
