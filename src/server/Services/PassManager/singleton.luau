local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local RobuxPurchase = require(StarterPlayer.StarterPlayerScripts.Client.VFX.RobuxPurchase)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local innerScope = require(ReplicatedStorage.Shared.Fusion.Memory.innerScope)
local PurchaseHandlers = script.Parent:WaitForChild("PurchaseHandlers") :: Folder

return {
	init = function()
		local handlers: { [string]: () -> () } = {}

		for _, module in ipairs(PurchaseHandlers:GetDescendants()) do
			if module:IsA("ModuleScript") then
				local f = require(module) :: {
					id: string,
					init: () -> (),
				}
				handlers[f.id] = f.init
			end
		end

		EventHandler:connect("promptProductPurchase", function(player: Player, id: string)
			MarketplaceService:PromptProductPurchase(player, id)
		end)
		EventHandler:connect("promptPassPurchase", function(player: Player, id: string)
			MarketplaceService:PromptGamePassPurchase(player, id)
		end)

		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
			if wasPurchased then
				RobuxPurchase(player.Character, player.Character.HumanoidRootPart)
			end
		end)

		MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
			local player = Players:GetPlayerByUserId(userId)
			if isPurchased then
				RobuxPurchase(player.Character, player.Character.HumanoidRootPart)
			end
		end)

		-- ? Dev Products
		local function process(receipt)
			local productId = tostring(receipt.ProductId)
			local playerId = receipt.PlayerId :: number
			local player = Players:GetPlayerByUserId(playerId)
			local result = false

			local function try(): boolean
				if not player then
					warn("[PassManager] Could not grab player object.")
					return false
				end

				if not handlers[productId] then
					warn("[PassManager] product Id doesnt exist.")
					return false
				end

				local handler = handlers[productId]

				local s, handlerResult = pcall(handler, player)

				if not s then
					warn(`[PassManager] CRASHED: {handlerResult}`)
					return false
				end

				if handlerResult == nil then
					warn(
						`[PassManager] Vague Handler: {productId} returned nil. Did you forget to 'return true' in the module?`
					)
					return false
				end

				local didHandlerGrantReward = handlerResult == true
				if not didHandlerGrantReward then
					warn(`[PassManager] Handler did not return true.`)
					return false
				end

				return true
			end

			result = try()

			-- Effect
			-- if result == Enum.ProductPurchaseDecision.PurchaseGranted then
			-- 	local character = player.Character
			-- 	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart

			-- 	if not hrp then
			-- 		return
			-- 	end

			-- end

			return if result
				then Enum.ProductPurchaseDecision.PurchaseGranted
				else Enum.ProductPurchaseDecision.NotProcessedYet
		end

		MarketplaceService.ProcessReceipt = process

		-- ? Gamepasses
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
			if wasPurchased then
				local productId = tostring(passId)
				if handlers[productId] then
					local handler = handlers[productId]
					local s, err = pcall(handler, player)
					if not s then
						warn(`[PassManager] Gamepass Handler Error: {err}`)
					end
				end
			end
		end)
	end,
	events = {
		"promptProductPurchase",
		"promptPassPurchase",
	},
}
