local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LemonSignal = require(ReplicatedStorage.Shared.LemonSignal)

return {
	toggleUI = LemonSignal.new(),
	onDeathScreenToggle = LemonSignal.new(),
}
