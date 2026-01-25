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

return {
	init = function()
		local player = Players.LocalPlayer
		-- Do not store static references to GUI here, they die on respawn.

		local currentModel: Model?
		local connection: RBXScriptConnection? = nil
		local throwConnection: RBXScriptConnection? = nil

		-- HELPER: Always get the LIVE InputActions
		local function getThrowAction()
			local gui = player:WaitForChild("PlayerGui")
			-- Increased timeout to 10 just to be safe on slow loads
			local actions = gui:WaitForChild("InputActions", 10)
			if not actions then
				warn("[Controller] Critical: InputActions folder not found!")
				return nil
			end
			return actions:FindFirstChild("ThrowTrash")
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
			if not currentModel then
				return
			end
			if not currentModel:HasTag("visualized") then
				local highlight = Instance.new("Highlight")
				highlight.Parent = currentModel
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
				highlight.OutlineTransparency = 0
				highlight.FillColor = Color3.fromRGB(255, 0, 0)
				highlight.FillTransparency = 0.4
				currentModel:AddTag("visualized")
			end
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

		-- Initial cleanup on load
		cleanup(true)

		-- Handle Respawn: When player dies, ensure UI is reset
		player.CharacterAdded:Connect(function()
			cleanup(true)
		end)

		EventHandler:connectClient("toggleGarbageVisualization", function(toggle: boolean)
			print(`[Controller] Toggle Visualization: {toggle}`)

			if toggle then
				-- FIX: Pass 'false' so we DON'T destroy the model the server just sent us
				cleanup(false)

				local platform = getDeviceType()
				local character = player.Character or player.CharacterAdded:Wait()

				-- Get Fresh Action
				local ThrowTrashAction = getThrowAction()
				if not ThrowTrashAction then
					return
				end

				-- Enable Action
				ThrowTrashAction.Enabled = true
				if platform == "Mobile" or platform == "Console" then
					local binding = ThrowTrashAction:FindFirstChild("InputBinding")
					if binding and binding:FindFirstChild("UIButton") then
						binding.UIButton.Parent.Visible = true
					end
				end

				-- Connect Input
				throwConnection = ThrowTrashAction.Released:Connect(function()
					if not currentModel then
						warn("[Controller] Clicked, but currentModel is nil!")
						return
					end
					EventHandler:fire("throwTrash", currentModel:GetPivot())
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
			print(`[Controller] Changing trash to: {to}`)

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
				warn(`[Controller] Could not find trash asset: {to}`)
			end
		end)
	end,
	events = {},
}
