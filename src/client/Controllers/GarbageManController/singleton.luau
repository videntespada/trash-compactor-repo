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
		local gui = player.PlayerGui
		local character = player.Character
		local currentModel: Model?

		-- IAS Stuff
		local InputActions = gui:WaitForChild("InputActions") :: Folder
		local ThrowTrashAction = InputActions:FindFirstChild("ThrowTrash") :: InputAction

		if not InputActions then
			warn("Unable to find InputActions")
		end

		-- Throw Button stuff
		local UIButton = (ThrowTrashAction["InputBinding"] :: InputBinding).UIButton
		local parentFrame = UIButton.Parent :: Frame

		ThrowTrashAction.Enabled = false
		parentFrame.Visible = false

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

		local connection
		EventHandler:connectClient("toggleGarbageVisualization", function(toggle: boolean)
			-- Check platform.
			if toggle then
				local platform = getDeviceType()

				if platform == "Mobile" or platform == "Console" then
					parentFrame.Visible = true
				end

				-- print(`Player is on ${platform}`)

				-- ? Turn on their action
				ThrowTrashAction.Enabled = true

				-- ? Detect platform and initialize
				if platform == "Mobile" or platform == "Console" then
					connection = RunService.Heartbeat:Connect(function()
						if currentModel == nil then
							-- print("Not doing anything, no model to place.")
							return
						end
						attachVisulization()
						local pos = MoveTrash("Snapped", character, currentModel)
					end)
				else
					local mouse = player:GetMouse()

					connection = RunService.Heartbeat:Connect(function()
						if currentModel == nil then
							-- print("Not doing anything, no model to place.")
							return
						end
						attachVisulization()
						local pos = MoveTrash("Mouse", character, currentModel, mouse.Hit.Position)
					end)
				end
			else
				if currentModel then
					currentModel:Destroy()
					currentModel = nil
				end
				ThrowTrashAction.Enabled = false
				connection:Disconnect()
			end
		end)

		EventHandler:connectClient("changeTrash", function(to: string)
			local found = TrashAssets:FindFirstChild(to, true):Clone()
			if found then
				for _, v in found:GetChildren() do
					if v:IsA("Part") or v:IsA("MeshPart") then
						v.Anchored = true
					end
				end
				found.Parent = workspace["Ignore"]
				if currentModel ~= nil then
					currentModel:Destroy()
				end
				currentModel = found
			end
		end)

		if not ThrowTrashAction then
			warn("TrashAction not found")
			return
		end
		ThrowTrashAction.Released:Connect(function()
			-- print("Acticated Trash Action")
			if not currentModel then
				return
			end
			EventHandler:fire("throwTrash", currentModel:GetPivot())
		end)
	end,
	events = {},
}
