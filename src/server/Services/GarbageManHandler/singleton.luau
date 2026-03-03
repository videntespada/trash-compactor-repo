local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TrashClass = require(ServerScriptService.Server.Classes.TrashClass)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
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
		EventHandler:connect("throwTrash", function(player: Player, start: CFrame)
			if not player:HasTag("GarbageMan") then
				return
			end
			if player:HasTag("ThrowDB") then
				return
			end

			if not toThrow or not toThrow.Parent then
				toThrow = chooseNewTrash()
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
		end)

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
				local player = a

				-- ! Enable
				-- Choose first trash
				toThrow = chooseNewTrash()
				EventHandler:fireClient(player, "changeTrash", toThrow.Name)
				EventHandler:fireClient(player, "toggleGarbageVisualization", true)
				print("Enabling garbage visualization stuff")
			end
		end)

		CollectionService:GetInstanceRemovedSignal("GarbageMan"):Connect(function(a)
			if a:IsA("Player") then
				local player = a
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
