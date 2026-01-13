local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local nameOf = require(ReplicatedStorage.Shared.Fusion.Utility.nameOf)
return {
	init = function()
		local Assets = ReplicatedStorage:WaitForChild("Assets")
		local TrashAssets = Assets:FindFirstChild("Trash") :: Folder
		local toThrow

		local function chooseNewTrash(): Model
			local t = TrashAssets:GetChildren() :: { Model }
			local chosen = t[math.random(1, #t)]:Clone()
			chosen.Parent = workspace
			return chosen
		end

		-- When they click to place
		EventHandler:connect("onClick", function(player: Player, at: Vector3?)
			if not player:HasTag("GarbageMan") or player:HasTag("ClickDB") then
				return
			end
			player:AddTag("ClickDB")
			task.delay(1, function()
				player:RemoveTag("ClickDB")
			end)
			local character = player.Character

			-- Throw Mechanic
			toThrow.Position = at
			local bv = Instance.new("BodyVelocity")
			bv.Parent = toThrow
			bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
			bv.Velocity = (character:GetPivot().LookVector * 50) + Vector3.yAxis * 20
			Debris:AddItem(bv, 0.1)

			-- Choose new to throw down.
			local chosen = chooseNewTrash()
			toThrow = chosen
			EventHandler:fireClient(player, "changeTrash", chosen.Name)
		end)

		-- Enabling/Disaibling placement mechanics.
		CollectionService.TagAdded:Connect(function(tag)
			if tag == "GarbageMan" then
				local tagged = CollectionService:GetTagged(tag)
				local player = tagged[1] :: Player

				-- ! Enable
				task.wait(6)
				-- Choose first trash
				toThrow = chooseNewTrash()
				EventHandler:fireClient(player, "changeTrash", toThrow.Name)
				print("Enabling garbage visualization stuff")
				EventHandler:fireClient(player, "toggleGarbageVisualization", true)
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
		"onClick",
		"toggleGarbageVisualization",
		"changeTrash",
	},
}
