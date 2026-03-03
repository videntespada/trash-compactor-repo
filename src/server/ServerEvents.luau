local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LemonSignal = require(ReplicatedStorage.Shared.LemonSignal)
return {
	sendRoundEvent = LemonSignal.new(),
	sendRevive = LemonSignal.new(),
	canRevive = LemonSignal.new(),
	sendRevenge = LemonSignal.new(),
	forceChooseGarbageMan = LemonSignal.new(),
	sendBombLocation = LemonSignal.new(),
	bombBreakTrash = LemonSignal.new(),
	onGarbageManKill = LemonSignal.new(),
}