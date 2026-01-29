local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LemonSignal = require(ReplicatedStorage.Shared.LemonSignal)
return {
	sendRoundEvent = LemonSignal.new()
}