local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local types = require(script.Parent.types)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local abilityList: { [string]: types.AbilityMod } = {}
local playerStates: Charm.Atom<{ [Player]: {
	lastTimeUsed: number,
} }> = atom({})

local function safeGrabData(player: Player)
	local s, result = pcall(Data.grabData, player)
	if not s then
		warn("Unable to grab player data!")
		return nil
	end
	return result
end

return {
	init = function()
		local AbilityFolder = script.Parent:FindFirstChild("Abilities") :: Folder

		for _, mod in ipairs(AbilityFolder:GetChildren() :: { ModuleScript }) do
			local req = require(mod) :: types.AbilityMod
			abilityList[mod.Name] = req
		end

		EventHandler:connect("sendAbilityUse", function(player: Player)
			local dta = safeGrabData(player)
			if dta == nil then
				return
			end
			local ability = dta.ability
			local handler = abilityList[ability]

			if not handler then
				warn("Cannot find ability name.")
				return
			end

			local currentState = playerStates()
			local state = currentState[player]

			local lastUsed = state and state.lastTimeUsed or 0
			local now = os.clock()

			local timeSinceLastUsed = now - lastUsed
			local cd = handler.Cooldown

			if timeSinceLastUsed < cd then
				local waitTime = math.ceil(cd - timeSinceLastUsed)
				warn(`Ability on cooldown! Wait ${waitTime}s`)
				return
			end

			handler.init(player)

			playerStates(function(old): { [Player]: { lastTimeUsed: number } }
				local new = table.clone(old)
				new[player] = {
					lastTimeUsed = now,
				}
				return new
			end)
		end)
	end,
	events = {
		"sendAbilityUse",
	},
}
