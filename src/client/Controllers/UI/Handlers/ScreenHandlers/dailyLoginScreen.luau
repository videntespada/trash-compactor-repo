local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Shared.Fusion)
EventHandler = require(ReplicatedStorage.Shared.EventHandler)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local DailyLogin = baseUI:FindFirstChild("DailyRewardsFrame") :: Frame

	-- Days
	local NormalDays = DailyLogin:FindFirstChild("NormalDays") :: Frame
	local LastDay = DailyLogin:FindFirstChild("LastDay") :: Frame

	local function setDayState(dayIndex: number, dayFrame: Frame, claimed: boolean)
		local dayMain = dayFrame:FindFirstChild("Main") :: Frame?
		if not dayMain then return end
		local dayButtons = dayMain:FindFirstChild("Buttons") :: Frame?
		if not dayButtons then return end
		local enabledButton = dayButtons:FindFirstChild("Enabled") :: Frame?
		local disabledButton = dayButtons:FindFirstChild("Disabled") :: Frame?
		local claimedButton = dayButtons:FindFirstChild("Claimed") :: Frame?
		if not enabledButton or not disabledButton or not claimedButton then return end
		disabledButton.Interactable = false
		claimedButton.Interactable = false
		if claimed then
			claimedButton.Visible = true
			enabledButton.Visible = false
			disabledButton.Visible = false
		else
			claimedButton.Visible = false
			enabledButton.Visible = true
			disabledButton.Visible = false
		end
	end

	EventHandler:connectClient("updateDailyReward", function(count: number, todayClaimed: boolean, claimedDaysUnlocked: { number }?)
		if claimedDaysUnlocked then
			-- Unlocked mode: each day 1-7 is either Claimed or Enabled (claim in order via one button)
			local daysOnly: { Frame } = {}
			for _, day in ipairs(NormalDays:GetChildren()) do
				if day:IsA("Frame") then
					table.insert(daysOnly, day)
				end
			end
			for i, dayFrame in ipairs(daysOnly) do
				setDayState(i, dayFrame, table.find(claimedDaysUnlocked, i) ~= nil)
			end
			local lastDayMain = LastDay:FindFirstChild("Main") :: Frame
			local lastDayButtons = lastDayMain and lastDayMain:FindFirstChild("Buttons") :: Frame?
			if lastDayButtons then
				local lastEnabled = lastDayButtons:FindFirstChild("Enabled") :: Frame?
				local lastDisabled = lastDayButtons:FindFirstChild("Disabled") :: Frame?
				local lastClaimed = lastDayButtons:FindFirstChild("Claimed") :: Frame?
				if lastEnabled and lastDisabled and lastClaimed then
					local day7Claimed = table.find(claimedDaysUnlocked, 7) ~= nil
					lastClaimed.Visible = day7Claimed
					lastEnabled.Visible = not day7Claimed
					lastDisabled.Visible = false
				end
			end
			return
		end

		if count < 7 then
			-- Days 1–6: past = Claimed, today = Claim (enabled), future = Disabled
			local daysOnly: { Frame } = {}

			for i, day in ipairs(NormalDays:GetChildren()) do
				if day:IsA("Frame") then
					table.insert(daysOnly, day)
				end
			end

			for i, day in ipairs(daysOnly) do
				local dayFrame = day :: Frame
				local dayMain = dayFrame:FindFirstChild("Main") :: Frame
				local dayButtons = dayMain:FindFirstChild("Buttons") :: Frame

				local enabledButton = dayButtons:FindFirstChild("Enabled") :: Frame
				local disabledButton = dayButtons:FindFirstChild("Disabled") :: Frame
				local claimedButton = dayButtons:FindFirstChild("Claimed") :: Frame

				disabledButton.Interactable = false
				claimedButton.Interactable = false

				-- print(i, count)

				if i < count then
					claimedButton.Visible = true
					enabledButton.Visible = false
					disabledButton.Visible = false
				elseif i == count then
					if todayClaimed then
						enabledButton.Visible = false
						claimedButton.Visible = true
					else
						enabledButton.Visible = true
						claimedButton.Visible = false
					end
					disabledButton.Visible = false
				else
					disabledButton.Visible = true
					claimedButton.Visible = false
					enabledButton.Visible = false
				end
			end
			-- LastDay stays disabled when count < 7
			local lastDayMain = LastDay:FindFirstChild("Main") :: Frame
			local lastDayButtons = lastDayMain:FindFirstChild("Buttons") :: Frame
			if lastDayButtons then
				local lastEnabled = lastDayButtons:FindFirstChild("Enabled") :: Frame
				local lastDisabled = lastDayButtons:FindFirstChild("Disabled") :: Frame
				if lastEnabled then
					lastEnabled.Visible = false
				end
				if lastDisabled then
					lastDisabled.Visible = true
					lastDisabled.Interactable = false
				end
			end
		else
			-- count >= 7: all NormalDays = Claimed, LastDay = Claim (enabled)
			for i, day in ipairs(NormalDays:GetChildren()) do
				if day:IsA("Frame") then
					local dayFrame = day:FindFirstChild(tostring(i)) :: Frame
					local dayMain = dayFrame:FindFirstChild("Main") :: Frame
					local dayButtons = dayMain:FindFirstChild("Buttons") :: Frame
					local enabledButton = dayButtons:FindFirstChild("Enabled") :: Frame
					local disabledButton = dayButtons:FindFirstChild("Disabled") :: Frame
					local claimedButton = dayButtons:FindFirstChild("Claimed") :: Frame
					claimedButton.Visible = true
					claimedButton.Interactable = false

					enabledButton.Visible = false
					disabledButton.Visible = false
				end
			end
			local lastDayMain = LastDay:FindFirstChild("Main") :: Frame
			local lastDayButtons = lastDayMain:FindFirstChild("Buttons") :: Frame
			local lastEnabled = lastDayButtons:FindFirstChild("Enabled") :: Frame
			local lastDisabled = lastDayButtons:FindFirstChild("Disabled") :: Frame
			lastEnabled.Visible = true
			lastDisabled.Visible = false
		end
	end)
end
