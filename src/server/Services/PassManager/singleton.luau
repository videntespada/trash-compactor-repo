local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local PurchaseHandlers = script.Parent:WaitForChild("PurchaseHandlers") :: Folder

return {
	init = function()
		local handlers: { [string]: () -> () } = {}

		for _, module in ipairs(PurchaseHandlers:GetChildren()) do
			local f = require(module) :: {
				id: string,
				init: () -> (),
			}
			handlers[f.id] = f.init
		end

		EventHandler:connect("promptProductPurchase", function(player: Player, id: string)
			MarketplaceService:PromptProductPurchase(player, id)
		end)
		EventHandler:connect("promptPassPurchase", function(player: Player, id: string)
			MarketplaceService:PromptGamePassPurchase(player, id)
		end)

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

			return if result
				then Enum.ProductPurchaseDecision.PurchaseGranted
				else Enum.ProductPurchaseDecision.NotProcessedYet
		end

		MarketplaceService.ProcessReceipt = process
	end,
	events = {
		"promptProductPurchase",
		"promptPassPurchase",
	},
}
