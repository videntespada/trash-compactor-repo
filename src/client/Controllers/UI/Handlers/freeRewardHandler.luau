local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local FreeRewardFrame = baseUI:FindFirstChild("FreeRewardFrame") :: Frame
	local RequirementsFrame = FreeRewardFrame:FindFirstChild("Main"):FindFirstChild("Req") :: Frame
	local ButtonFrame = FreeRewardFrame:FindFirstChild("Main"):FindFirstChild("btn") :: Frame

	local JoinGroupImage = RequirementsFrame:FindFirstChild("JoinGroup")
		:FindFirstChild("Main")
		:FindFirstChild("content")
		:FindFirstChild("ImageLabel") :: ImageLabel
	local LikeGameCheck = RequirementsFrame:FindFirstChild("LikeGame")
		:FindFirstChild("Main")
		:FindFirstChild("content")
		:FindFirstChild("ImageLabel") :: ImageLabel
	local FavoriteGameCheck = RequirementsFrame:FindFirstChild("Favorite")
		:FindFirstChild("Main")
		:FindFirstChild("content")
		:FindFirstChild("ImageLabel") :: ImageLabel
	local claimButton = ButtonFrame:FindFirstChild("Main") :: ImageButton

	local states = {
		gameLiked = scope:Value(false),
		groupJoined = scope:Value(false),
		gameFavorited = scope:Value(false),
	}

	scope:Hydrate(JoinGroupImage)({
		Image = scope:Computed(function(use)
			local isInGroup = use(states.groupJoined)

			if isInGroup then
				return "rbxassetid://135466278905507"
			else
				-- Normal
				return "rbxassetid://116575401174458"
			end
		end),
	})
	scope:Hydrate(FavoriteGameCheck)({
		Image = scope:Computed(function(use)
			local isFavorited = use(states.gameFavorited)

			if isFavorited then
				return "rbxassetid://135466278905507"
			else
				-- Normal
				return "rbxassetid://129799473322248"
			end
		end),
	})
	scope:Hydrate(LikeGameCheck)({
		Image = scope:Computed(function(use)
			local likedGame = use(states.gameLiked)

			if likedGame then
				return "rbxassetid://135466278905507"
			else
				-- Normal
				return "rbxassetid://99182787763729"
			end
		end),
	})

	local allClaimed = scope:Computed(function(use)
		-- Ignore the naming here, i got lazy
		local a = use(states.gameFavorited)
		local b = use(states.gameLiked)
		local c = use(states.groupJoined)

		local final = false
		if a and b and c then
			final = true
		else
			final = false
		end

		return final
	end)

	-- Button hydrate
	scope:Hydrate(claimButton)({
		Active = scope:Computed(function(use)
			local hasClaimedAll = use(allClaimed)

			if hasClaimedAll then
				(claimButton:WaitForChild("UIGradient") :: UIGradient).Enabled = false
				claimButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

				local textLabel = claimButton:WaitForChild("ButtonText") :: TextLabel
				textLabel.Text = "CLAIMED"
				(textLabel:WaitForChild("UIGradient") :: UIGradient).Enabled = false

				ButtonFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

				return false
			else
				(claimButton:WaitForChild("UIGradient") :: UIGradient).Enabled = true

				local textLabel = claimButton:WaitForChild("ButtonText") :: TextLabel
				textLabel.Text = "CLAIM"
				(textLabel:WaitForChild("UIGradient") :: UIGradient).Enabled = true

				ButtonFrame.BackgroundColor3 = Color3.fromRGB(8, 169, 0)

				return true
			end
		end),
	})

	EventHandler:connectClient("freeRewardStatus", function(status: {
		gameLiked: boolean,
		gameFavorited: boolean,
		groupJoined: boolean,
	})
		states.gameLiked:set(status.gameLiked)
		states.gameFavorited:set(status.gameFavorited)
		states.groupJoined:set(status.groupJoined)

		-- print(status)
	end)
end
