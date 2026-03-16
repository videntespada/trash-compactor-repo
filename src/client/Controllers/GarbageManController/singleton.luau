-- # GarbageManController (Client)
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MoveTrash = require(StarterPlayer.StarterPlayerScripts.Client.VFX.MoveTrash)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Assets = ReplicatedStorage:WaitForChild("Assets")
local TrashAssets = Assets:FindFirstChild("Trash") :: Folder

local DEBUG_THROW = true
local function debug(msg: string)
	if DEBUG_THROW then
		print("[GarbageManController]", msg)
	end
end

return {
	init = function()
		debug("init started")
		local player = Players.LocalPlayer
		-- Do not store static references to GUI here, they die on respawn.

		local currentModel: Model?
		local connection: RBXScriptConnection? = nil
		local throwConnection: RBXScriptConnection? = nil

		local function getThrowAction()
			local gui = player:WaitForChild("PlayerGui")
			-- Increased timeout to 10 just to be safe on slow loads
			local actions = gui:WaitForChild("InputActions", 10)
			if not actions then
				warn("[GarbageManController] Critical: InputActions folder not found!")
				return nil
			end
			local action = actions:FindFirstChild("ThrowTrash")
			debug(`getThrowAction: actions={actions:GetFullName()}, ThrowTrash={action ~= nil}`)
			return action
		end

		local function getDeviceType(): string
			if GuiService:IsTenFootInterface() then
				return "Console"
			elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
				return "Mobile"
			else
				return "PC"
			end
		end

		local function attachVisulization()
			-- Red trash highlight for the Garbageman has been intentionally disabled.
			-- Keeping this function as a no-op so the rest of the controller logic
			-- does not need to change.
		end

		-- Cleans up connections/UI but OPTIONALLY keeps the model
		local function cleanup(destroyModel: boolean)
			if destroyModel and currentModel then
				currentModel:Destroy()
				currentModel = nil
			end

			if connection then
				connection:Disconnect()
				connection = nil
			end
			if throwConnection then
				throwConnection:Disconnect()
				throwConnection = nil
			end

			-- Disable UI
			local action = getThrowAction()
			if action then
				action.Enabled = false
				local binding = action:FindFirstChild("InputBinding")
				if binding and binding:FindFirstChild("UIButton") then
					binding.UIButton.Parent.Visible = false
				end
			end
		end

		-- Initial cleanup on load (hide throw button for non-GM, e.g. mobile)
		cleanup(true)
		-- Defer so InputActions/ThrowTrash may exist after UI loads; ensure button stays hidden
		task.defer(function()
			cleanup(true)
		end)

		-- Handle Respawn: When player dies, ensure UI is reset
		player.CharacterAdded:Connect(function()
			cleanup(true)
		end)

		EventHandler:connectClient("toggleGarbageVisualization", function(toggle: boolean)
			debug(`toggleGarbageVisualization: {toggle}`)

			if toggle then
				-- FIX: Pass 'false' so we DON'T destroy the model the server just sent us
				cleanup(false)

				local platform = getDeviceType()
				local character = player.Character or player.CharacterAdded:Wait()

				-- Get Fresh Action
				local ThrowTrashAction = getThrowAction()
				if not ThrowTrashAction then
					warn("[GarbageManController] toggle=true but ThrowTrashAction nil - cannot enable throw")
					return
				end

				-- Enable Action
				ThrowTrashAction.Enabled = true
				debug("ThrowTrashAction.Enabled = true")
				if platform == "Mobile" or platform == "Console" then
					local binding = ThrowTrashAction:FindFirstChild("InputBinding")
					if binding and binding:FindFirstChild("UIButton") then
						binding.UIButton.Parent.Visible = true
					end
				end

				-- Connect Input
				throwConnection = ThrowTrashAction.Released:Connect(function()
					debug("ThrowTrashAction.Released fired")
					if not currentModel then
						warn("[GarbageManController] Clicked, but currentModel is nil!")
						return
					end
					debug("firing throwTrash with currentModel pivot")
					local err = EventHandler:fire("throwTrash", currentModel:GetPivot())
					if err then
						warn("[GarbageManController] EventHandler:fire throwTrash failed:", err)
					else
						debug("throwTrash fire completed (no error return)")
					end
				end)

				-- Connect Visual Loop
				connection = RunService.Heartbeat:Connect(function()
					if not currentModel then
						return
					end

					-- Handle respawn mid-round edge case
					if not character or not character.Parent then
						character = player.Character
						return
					end

					attachVisulization()

					if platform == "Mobile" or platform == "Console" then
						MoveTrash("Snapped", character, currentModel)
					else
						local mouse = player:GetMouse()
						MoveTrash("Mouse", character, currentModel, mouse.Hit.Position)
					end
				end)
			else
				-- Disable: Pass 'true' to destroy the model
				cleanup(true)
			end
		end)

		EventHandler:connectClient("changeTrash", function(to: string)
			debug(`changeTrash: {to}`)

			local original = TrashAssets:FindFirstChild(to, true)
			if original then
				if currentModel then
					currentModel:Destroy()
				end

				local found = original:Clone()
				for _, v in found:GetChildren() do
					if v:IsA("Part") or v:IsA("MeshPart") then
						v.Anchored = true
						v.CanCollide = false
					end
				end
				found.Parent = workspace:FindFirstChild("Ignore") or workspace
				currentModel = found
			else
				warn("[GarbageManController] Could not find trash asset:", to)
			end
		end)
		debug("init finished")
	end,
	events = {},
}
