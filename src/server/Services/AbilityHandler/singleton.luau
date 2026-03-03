local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RagdollModule = require(ReplicatedStorage.Shared.RagdollModule)
local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local types = require(script.Parent.types)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

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
		print(AbilityFolder:GetChildren())
		local AssetFolder = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild("AbilityAssets") :: Folder

		for _, mod in ipairs(AbilityFolder:GetChildren() :: { ModuleScript }) do
			local req = require(mod) :: types.AbilityMod
			abilityList[mod.Name] = req
		end

		EventHandler:connect("sendAbilityUse", function(player: Player)
			local dta = safeGrabData(player)
			if dta == nil then
				return
			end
			if not player:HasTag("InRound") then
				-- TODO: Notification saying that they arent in round
				warn(`${player} isn't in round`)
				return
			end
			local ability = dta.ability
			local handler = abilityList[ability]
			print(abilityList)

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
				-- TODO: Send notification of remaining time left on cd
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
		end)

		-- ? Bespoke events
		local bombFinishLocation
		ServerEvents.sendBombLocation:Connect(function(location)
			bombFinishLocation = location
		end)
		EventHandler:connect("onBombFinish", function(player: Player)
			local pos = bombFinishLocation -- Assuming this is a Vector3 defined in your scope
			if not pos then
				return
			end

			-- 1. Configuration
			local BLAST_RADIUS = 30
			local BLAST_DAMAGE = 5
			local RAGDOLL_TIME = 2
			local PUSH_FORCE = 60

			-- 2. Define the OverlapParams for the spatial query
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			-- Exclude the bomb itself if it hasn't been destroyed yet
			-- params.FilterDescendantsInstances = {bombInstance}

			-- 3. Find everything in the blast radius
			print(typeof(pos))
			local finalPos: Vector3
			if typeof(pos) == "CFrame" then
				finalPos = pos.Position
			else
				finalPos = pos
			end
			local partsInRadius = workspace:GetPartBoundsInRadius(finalPos, BLAST_RADIUS, params)

			local processedModels = {} -- Debounce for models (trash/characters)

			for _, part in partsInRadius do
				local model = part:FindFirstAncestorOfClass("Model")
				if not model or processedModels[model] then
					continue
				end
				processedModels[model] = true

				-- CASE A: Trash Models (workspace.Ignore.Trash)
				if model:IsDescendantOf(workspace:WaitForChild("Ignore"):FindFirstChild("Trash")) then
					-- Tell the framework to destroy/cleanup this trash
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
					continue
				end

				-- CASE B: Players/Humanoids (AliveFolder)
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				local root = model.PrimaryPart

				-- Only hit players/NPCs in the "Alive" folder
				if humanoid and root and model.Parent == workspace:WaitForChild("Alive") then
					-- Damage
					humanoid:TakeDamage(BLAST_DAMAGE)

					-- Ragdoll
					RagdollModule.TimedRagdoll(model, RAGDOLL_TIME)

					-- Push Back Logic
					local direction = (root.Position - pos).Unit
					-- If the bomb is exactly on the root, default to Up
					if direction ~= direction then
						direction = Vector3.yAxis
					end

					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.one * math.huge
					bv.Velocity = (direction * PUSH_FORCE) + (Vector3.yAxis * 25)
					bv.Parent = root
					game:GetService("Debris"):AddItem(bv, 0.2)
				end
			end
		end)
	end,
	events = {
		"sendAbilityUse",
		"bombVFX",
		"onBombFinish",
	},
}
