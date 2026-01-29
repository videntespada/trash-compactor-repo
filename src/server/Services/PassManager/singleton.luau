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

			if not player then
				warn("[PassManager] Could not grab player object.")
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			if not handlers[productId] then
				warn("[PassManager] product Id doesnt exist.")
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local handler = handlers[productId]

			local s, handlerResult = pcall(handler)

			if not s then
				warn(`[PassManager] Handler could not run product reward for ${player}.`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local didHandlerGrantReward = handlerResult == true
			if not didHandlerGrantReward then
				warn(`[PassManager] Handler did not return true.`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		MarketplaceService.ProcessReceipt = process
	end,
	events = {
		"promptProductPurchase",
		"promptPassPurchase",
	},
}
