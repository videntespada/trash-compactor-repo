local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local types = require(script.Parent.types)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local SharedState = require(ReplicatedStorage.Shared.SharedState)

local abilityList: { [string]: types.AbilityMod } = {}
local playerStates = atom({})

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
		local AbilityFolder = script.Parent:WaitForChild("Abilities") :: Folder
		-- print(AbilityFolder:GetChildren())
		local AssetFolder = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild("AbilityAssets") :: Folder

		for _, mod in ipairs(AbilityFolder:GetChildren() :: { ModuleScript }) do
			local req = require(mod) :: types.AbilityMod
			abilityList[mod.Name] = req
		end

		-- General ability events
		EventHandler:connect("sendAbilityUse", function(player: Player)
			local dta = safeGrabData(player)
			if dta == nil then
				warn(`[AbilityHandler] sendAbilityUse: no data for {player.Name}`)
				return
			end
			if not player:HasTag("InRound") then
				-- Error: trying to use ability outside round
				EventHandler:fireClient(player, "sendNotification", "🚫 Wait for the round to start!", 128635936514965, "Negative")
				warn(`${player} isn't in round`)
				return
			end
			local char = player.Character
			if char and char:GetAttribute("Ragdolled") then
				EventHandler:fireClient(player, "sendNotification", "🚫 Can't use abilities while ragdolled!", 128635936514965, "Negative")
				return
			end
			if player:HasTag("GarbageMan") then
				-- Error: GM cannot use abilities
				EventHandler:fireClient(player, "sendNotification", "🚫 Garbageman can't use abilities!", 128635936514965, "Negative")
				return
			end
			local ability = dta.ability
			local handler = abilityList[ability]
			if not ability or ability == "" then
				warn(`[AbilityHandler] sendAbilityUse: no equipped ability for {player.Name}`)
			end

			if not handler then
				warn(`[AbilityHandler] sendAbilityUse: cannot find ability handler for "{ability}"`)
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
				-- Error: ability on cooldown
				EventHandler:fireClient(player, "sendNotification", `⏳ Cooldown! {waitTime}s`, 128635936514965, "Negative")
				return
			end

			handler.init(player, AssetFolder)

			playerStates(function(old): { [Player]: { lastTimeUsed: number } }
				local new = table.clone(old)
				new[player] = {
					lastTimeUsed = now,
				}
				return new
			end)

			-- Inform the client to show the cooldown state for this ability.
			EventHandler:fireClient(player, "abilityCooldown", cd)
		end)

		EventHandler:connect("equipAbility", function(player: Player, ability: string)
			local dta = safeGrabData(player)
			if not dta then return end

			if player:HasTag("InRound") then
				EventHandler:fireClient(player, "sendNotification", "🚫 Can't switch abilities during a round!", 128635936514965, "Negative")
				return
			end

			local equippedAbility = dta.ability
			local newAbility = ability

			if newAbility == equippedAbility then return end

			local idx = table.find(dta.abilityInventory, newAbility)
			if not idx then
				warn(`${player.Name} does not own ability ${newAbility}`)
				return
			end

			if equippedAbility ~= "" then
				table.insert(dta.abilityInventory, equippedAbility)
			end
			local removeIdx = table.find(dta.abilityInventory, newAbility)
			if removeIdx then
				table.remove(dta.abilityInventory, removeIdx)
			end
			dta.ability = newAbility

			EventHandler:fireClient(player, "loadAbilitiyInventoryData", dta.abilityInventory, dta.ability, dta.crowns)
		end)

		EventHandler:connect("buyAbility", function(player: Player, ability: string)
			local dta = safeGrabData(player)
			if not dta then return end

			local alreadyOwned = (table.find(dta.abilityInventory, ability) ~= nil) or (dta.ability == ability)
			if alreadyOwned then
				-- Informational: they already own this ability (treat as negative/neutral)
				EventHandler:fireClient(player, "sendNotification", "✅ You already have this!", 128635936514965, "Negative")
				warn(`${player.Name} already has ${ability}`)
				return
			end

			local cost = SharedState.abilityCost[ability]
			if not cost then
				-- Error: ability not available for purchase
				EventHandler:fireClient(player, "sendNotification", "🔒 Not available yet!", 128635936514965, "Negative")
				return
			end
			if dta.coins < cost then
				-- Currency-specific error: not enough coins
				EventHandler:fireClient(player, "sendNotification", `💰 You need {cost} coins for this!`, 128635936514965, "Currency")
				warn(`${player.Name} does not have enough coins to buy ${ability}`)
				return
			end

			Data.mutateCurrency(player, "coins", dta.coins - cost)
			table.insert(dta.abilityInventory, ability)
			EventHandler:fireClient(player, "loadAbilitiyInventoryData", dta.abilityInventory, dta.ability, dta.crowns)
		end)

		-- Client -> Server: Abilities UI requesting latest inventory/equipped data
		EventHandler:connect("requestAbilityInventory", function(player: Player)
			local dta = safeGrabData(player)
			if not dta then
				return
			end

			EventHandler:fireClient(player, "loadAbilitiyInventoryData", dta.abilityInventory, dta.ability, dta.crowns)
		end)

		-- ? Bespoke events
		local bombFinishLocation
		ServerEvents.sendBombLocation:Connect(function(location)
			bombFinishLocation = location
		end)
		EventHandler:connect("onBombFinish", function(_player: Player)
			local pos = bombFinishLocation
			if not pos then
				return
			end

			local BLAST_RADIUS = 20 -- stud radius; bomb affects trash only (no player hit)
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude

			local finalPos: Vector3
			if typeof(pos) == "CFrame" then
				finalPos = pos.Position
			else
				finalPos = pos
			end
			local partsInRadius = workspace:GetPartBoundsInRadius(finalPos, BLAST_RADIUS, params)
			local processedModels = {}

			for _, part in partsInRadius do
				local model = part:FindFirstAncestorOfClass("Model")
				if not model or processedModels[model] then
					continue
				end
				processedModels[model] = true

				if model:IsDescendantOf(workspace:WaitForChild("Ignore"):FindFirstChild("Trash")) then
					for _, v in ipairs(model:GetDescendants()) do
						if v:IsA("Part") or v:IsA("MeshPart") then
							v.AssemblyAngularVelocity = Vector3.zero
							v.AssemblyLinearVelocity = Vector3.zero
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
							bv.Velocity = Vector3.yAxis * 20
							bv.Parent = v
							Debris:AddItem(bv, 0.1)
						end
					end
					ServerEvents.bombBreakTrash:Fire(model)
				end
			end
		end)
	end,
	events = {
		"sendAbilityUse",
		"equipAbility",
		"buyAbility",
		"bombVFX",
		"onBombFinish",
		"requestAbilityInventory",
		"abilityCooldown",
	},
}
