local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ThrowBomb = require(StarterPlayer.StarterPlayerScripts.Client.VFX.ThrowBomb)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local player = Players.LocalPlayer
		local gui = player.PlayerGui
		local inputActionFolder = gui:WaitForChild("InputActions") :: Folder
		local UseAbility = inputActionFolder:WaitForChild("UseAbility") :: InputAction
		local ThrowTrashAction = inputActionFolder:FindFirstChild("ThrowTrash") :: any

		local isInRound = false
		local isGarbageMan = false

		local function updateBindings()
			if not UseAbility then
				return
			end

			-- Lobby / Intermission: both actions are enabled for everyone.
			if not isInRound then
				UseAbility.Enabled = true
				if ThrowTrashAction and ThrowTrashAction:IsA("InputAction") then
					ThrowTrashAction.Enabled = true
				end
				return
			end

			-- In-round: survivors use abilities, Garbageman throws trash.
			if isGarbageMan then
				UseAbility.Enabled = false
				if ThrowTrashAction and ThrowTrashAction:IsA("InputAction") then
					ThrowTrashAction.Enabled = true
				end
			else
				UseAbility.Enabled = true
				if ThrowTrashAction and ThrowTrashAction:IsA("InputAction") then
					ThrowTrashAction.Enabled = false
				end
			end
		end

		UseAbility.Released:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
				return
			end
			EventHandler:fire("sendAbilityUse")
		end)

		EventHandler:connectClient("abilityInRound", function(inRound: boolean)
			isInRound = inRound
			updateBindings()
		end)

		EventHandler:connectClient("toggleGarbageVisualization", function(toggle: boolean)
			isGarbageMan = toggle
			updateBindings()
		end)

		EventHandler:connectClient("bombVFX", function(BombModel: Model, character: Model, Map: Folder, endPos)
			ThrowBomb(BombModel, character, Map, endPos)
		end)

		-- Initialize bindings for the starting lobby state.
		updateBindings()
	end,
	events = {},
}
