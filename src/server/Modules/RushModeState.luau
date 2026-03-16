-- Shared rush-mode state so RoundService and GarbageManHandler can use it without cross-require or BoolValue.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom

return {
	rushMode = atom(false),
}
