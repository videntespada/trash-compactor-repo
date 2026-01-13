local ClusterPacketCache = game:GetService("ClusterPacketCache")
local FeatureRestrictionManager = game:GetService("FeatureRestrictionManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MoveTrash = require(StarterPlayer.StarterPlayerScripts.Client.VFX.MoveTrash)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local packType = require(ReplicatedStorage.Shared.Fusion.Animation.packType)
local Assets = ReplicatedStorage:WaitForChild("Assets")
local TrashAssets = Assets:FindFirstChild("Trash") :: Folder

return {
	init = function()
		local player = Players.LocalPlayer
		local character = player.Character
		local currentModel: Model
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
				print(`Player is on ${platform}`)
				if platform == "Mobile" or platform == "Console" then
					connection = RunService.Heartbeat:Connect(function()
						if currentModel == nil then
							print("Not doing anything, no model to place.")
							return
						end
						attachVisulization()
						MoveTrash("Snapped", character, currentModel)
					end)
				else
					local mouse = player:GetMouse()

					connection = RunService.Heartbeat:Connect(function()
						if currentModel == nil then
							print("Not doing anything, no model to place.")
							return
						end
						attachVisulization()
						MoveTrash("Mouse", character, currentModel, mouse.Hit.Position)
					end)
				end
			else
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
				currentModel = found
			end
		end)
	end,
	events = {},
}
