local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LemonSignal = require(ReplicatedStorage.Shared.LemonSignal)
return {
	sendRoundEvent = LemonSignal.new(),
	sendRevive = LemonSignal.new(),
	canRevive = LemonSignal.new(),
	sendRevenge = LemonSignal.new(),
}
