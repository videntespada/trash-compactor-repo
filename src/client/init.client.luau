local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

-- Disable character reset: CoreScripts may register ResetButtonCallback after we run, so retry.
local function disableReset()
	local ok = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	return ok
end
task.spawn(function()
	for _ = 1, 30 do
		if disableReset() then
			break
		end
		task.wait(0.2)
	end
end)

local player = Players.LocalPlayer
local PlayerScripts = player.PlayerScripts

local Client = PlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")

local clientLoadEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("clientLoaded") :: RemoteEvent

type ReturnType = {
	init: () -> (),
	events: { string }?,
}

local toInit: { () -> () } = {}

-- Only server creates RemoteEvents; client just runs inits
for _, v in ipairs(Controllers:GetChildren() :: { Folder }) do
	local mod: ModuleScript = v:WaitForChild("singleton")
	local req: ReturnType = require(mod)
	toInit[1 + #toInit] = req.init
end

-- invoke all init functions
for _, v in ipairs(toInit) do
	v()
end

-- let the server know that all controllers are done loading
clientLoadEvent:FireServer()
