local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("Services")

local clientLoaded = false
local clientLoadEvent = ReplicatedStorage:WaitForChild("Shared"):FindFirstChild("clientLoaded") :: RemoteEvent

type ReturnType = {
	init: () -> (),
	events: { string },
}

local toInit: { () -> () } = {}

for _, v in ipairs(Services:GetChildren() :: { Folder }) do
	local mod: ModuleScript = v:WaitForChild("singleton")
	local req: ReturnType = require(mod)

	-- * Read all events, and initialize remotes
	for _, ev in req.events do
		EventHandler:createEvent(ev)
	end

	toInit[1 + #toInit] = req.init
end

-- Wait for at least one client to be loaded
-- clientLoadEvent.OnServerEvent:Once(function(player)
-- 	clientLoaded = true
-- end)

-- repeat
-- 	task.wait(1)
-- until clientLoaded

-- invoke all init functions
for _, v in ipairs(toInit) do
	task.spawn(v)
end
