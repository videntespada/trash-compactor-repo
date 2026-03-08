local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

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
