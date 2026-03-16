local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)

-- Walk up from a part to find a Model that has a Humanoid (the character).
local function getCharacterFromTouched(touched: BasePart): Model?
	local current: Instance? = touched
	while current and current ~= workspace do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local THROTTLE_SECONDS = 2

return {
	init = function()
		local Scriptable = workspace:WaitForChild("Map"):WaitForChild("Scriptable") :: Folder
		local ObbyRewardPart = Scriptable:WaitForChild("ObbyReward") :: Part
		local ObbyTP = Scriptable:WaitForChild("ObbyTP") :: Part
		local ObbyDeath = Scriptable:WaitForChild("ObbyDeath") :: Part
		local lastTouchedAt: { [Player]: number } = {}
		Players.PlayerRemoving:Connect(function(player: Player)
			lastTouchedAt[player] = nil
		end)

		local function tpToStart(character: Model)
			(character:FindFirstChild("HumanoidRootPart") :: BasePart).Anchored = true;

			character:PivotTo(ObbyTP.CFrame);
			task.wait(0.5);
			(character:FindFirstChild("HumanoidRootPart") :: BasePart).Anchored = false;
		end

		ObbyDeath.Touched:Connect(function(hit)
			local character = getCharacterFromTouched(hit)
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player or not player:IsA("Player") or player.Parent ~= Players then
				return
			end
			tpToStart(character)
		end)

		ObbyRewardPart.Touched:Connect(function(hit)
			local character = getCharacterFromTouched(hit)
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player or not player:IsA("Player") or player.Parent ~= Players then
				return
			end
			local now = tick()
			if lastTouchedAt[player] and (now - lastTouchedAt[player]) < THROTTLE_SECONDS then
				return
			end
			lastTouchedAt[player] = now

			local data = Data.grabData(player)
			if not data then
				return
			end
			tpToStart(character)
			if player:HasTag("ObbyReward") then
				EventHandler:fireClient(
					player,
					"sendNotification",
					"Obby Reward on cooldown. Come back after a round!",
					128635936514965,
					"Negative"
				)
				return
			end
			player:AddTag("ObbyReward")
			Data.mutateCurrency(player, "coins", data.coins + 25)
			EventHandler:fireClient(player, "sendNotification", "🎁 Obby Reward! +25 coins!", 4612378364, "Currency")
			task.delay(60, function()
				player:RemoveTag("ObbyReward")
				EventHandler:fireClient(player, "sendNotification", "Obby Reward cooldown is done. Come back to claim your reward!", 128635936514965, "Normal")
			end)
		end)
	end,
	events = {},
}
