local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)

local DISPLAY_INTERVAL_SECONDS = 5 * 60 -- 5 minutes
local TOP_COUNT = 20
local ThumbnailType = Enum.ThumbnailType
local ThumbnailSize = Enum.ThumbnailSize

local DEBUG_LEADERBOARD = false
local function debug(msg: string)
	if DEBUG_LEADERBOARD then
		print("[LeaderboardHandler]", msg)
	end
end

return {
	init = function()
		debug("init started")
		local LeaderboardModels = workspace:WaitForChild("Leaderboards") :: Folder

		local CoinsLeaderboard = LeaderboardModels:WaitForChild("Coins") :: Model
		local CrownsLeaderboard = LeaderboardModels:WaitForChild("Trophies") :: Model

		local CoinsDisplay = CoinsLeaderboard:WaitForChild("Display"):FindFirstChild("GUI") :: SurfaceGui
		local CrownsDisplay = CrownsLeaderboard:WaitForChild("Display"):FindFirstChild("GUI") :: SurfaceGui

		local CoinsHolder =
			CoinsDisplay:WaitForChild("GameBoardFrame"):FindFirstChild("ScrollingFrame") :: ScrollingFrame
		local CrownsHolder =
			CrownsDisplay:WaitForChild("GameBoardFrame"):FindFirstChild("ScrollingFrame") :: ScrollingFrame

		local Podium = workspace:WaitForChild("TopPlayers") :: Folder
		local podiumTop1 = Podium:WaitForChild("1") :: Model
		local podiumTop2 = Podium:WaitForChild("2") :: Model
		local podiumTop3 = Podium:WaitForChild("3") :: Model

		local PODIUM_ANIMS = {
			[1] = 138243322520289,
			[2] = 77387643699357,
			[3] = 113311421817534,
		}

		local lastPodiumUserIds: { [number]: number? } = {
			[1] = nil,
			[2] = nil,
			[3] = nil,
		}

		local function getHumanoid(model: Model): Humanoid?
			local hum = model:FindFirstChildWhichIsA("Humanoid", true)
			if hum and hum:IsA("Humanoid") then
				return hum
			end
			return nil
		end

		local function playLoopedAnimation(humanoid: Humanoid, animAssetId: number)
			local animator = humanoid:FindFirstChildWhichIsA("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end

			-- Stop any previous playing tracks to avoid stacking
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				track:Stop(0.1)
			end

			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. tostring(animAssetId)
			local ok, trackOrErr = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if not ok then
				anim:Destroy()
				return
			end
			local track = trackOrErr :: AnimationTrack
			track.Looped = true
			track:Play(0.15, 1, 1)
			anim:Destroy()
		end

		local function applyAvatarToPodium(rank: number, targetModel: Model, userId: number?)
			if not userId or userId <= 0 then
				return
			end
			if lastPodiumUserIds[rank] == userId then
				return
			end

			local humanoid = getHumanoid(targetModel)
			if not humanoid then
				warn(`[LeaderboardHandler] Podium model {targetModel.Name} missing Humanoid`)
				return
			end

			local okDesc, descOrErr = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(userId)
			end)
			if okDesc and descOrErr then
				pcall(function()
					humanoid:ApplyDescription(descOrErr :: HumanoidDescription)
				end)
			else
				warn(`[LeaderboardHandler] Failed to get description for userId={userId}: {tostring(descOrErr)}`)
			end

			local animId = PODIUM_ANIMS[rank]
			if animId then
				playLoopedAnimation(humanoid, animId)
			end

			lastPodiumUserIds[rank] = userId
		end

		local function updatePodiumFromTop3(results: { any })
			-- Uses the top 3 from the provided results (expected: coins leaderboard entries)
			applyAvatarToPodium(1, podiumTop1, results[1] and results[1].userId or nil)
			applyAvatarToPodium(2, podiumTop2, results[2] and results[2].userId or nil)
			applyAvatarToPodium(3, podiumTop3, results[3] and results[3].userId or nil)
		end

		local function ensureListLayout(holder: ScrollingFrame)
			if not holder:FindFirstChild("UIListLayout") then
				local layout = Instance.new("UIListLayout")
				layout.Name = "UIListLayout"
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = holder
			end
		end
		ensureListLayout(CoinsHolder)
		ensureListLayout(CrownsHolder)

		local Assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
		local FirstPlace = Assets:WaitForChild("LeaderboardFirst") :: Frame
		local SecondPlace = Assets:WaitForChild("LeaderboardSecond") :: Frame
		local ThirdPlace = Assets:WaitForChild("LeaderboardThird") :: Frame
		local NormalCell = Assets:WaitForChild("LeaderboardNormalCell") :: Frame

		local function formatCount(rawValue: string): string
			local n = tonumber(rawValue)
			if not n then
				return rawValue
			end
			if n >= 1e9 then
				return string.format("%.1fB", n / 1e9)
			elseif n >= 1e6 then
				return string.format("%.1fM", n / 1e6)
			elseif n >= 1e3 then
				return string.format("%.1fK", n / 1e3)
			else
				return tostring(n)
			end
		end

		local function getCellForRank(rank: number): Frame
			if rank == 1 then
				return FirstPlace:Clone()
			elseif rank == 2 then
				return SecondPlace:Clone()
			elseif rank == 3 then
				return ThirdPlace:Clone()
			else
				return NormalCell:Clone()
			end
		end

		local function getAvatarImageForPlayer(plr: Player): string?
			if not plr then
				return nil
			end
			local ok, content = pcall(function()
				local url, _ = Players:GetUserThumbnailAsync(plr.UserId, ThumbnailType.HeadShot, ThumbnailSize.Size100x100)
				return url
			end)
			if ok then
				return content
			end
			return nil
		end

		local function setCellLabels(cell: Frame, rank: number, name: string, value: string, plr: Player?)
			local playerName = cell:FindFirstChild("PlayerName") :: TextLabel?
			local position = cell:FindFirstChild("Position") :: TextLabel?
			local count = cell:FindFirstChild("Count") :: TextLabel?
			local playerImage = (cell:FindFirstChild("PlayerThumbnail") :: CanvasGroup):FindFirstChild(
					"image"
				) :: ImageLabel?
			if playerImage and plr then
				playerImage.Image = getAvatarImageForPlayer(plr)
			end
			if playerName then
				playerName.Text = name
			end
			if position then
				position.Text = tostring(rank)
			end
			if count then
				count.Text = formatCount(value)
			end
			debug(
				`  setCellLabels rank={rank} name={name} value={value} formatted={count and count.Text or ""} (PlayerName={playerName ~= nil} Position={position ~= nil} Count={count ~= nil})`
			)
		end

		local function clearHolder(holder: ScrollingFrame)
			for _, child in ipairs(holder:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
		end

		local function refreshCoins()
			debug("refreshCoins() calling Data.getTop20Coins(" .. TOP_COUNT .. ")")
			local results = Data.getTop20Coins(TOP_COUNT)
			debug(`refreshCoins() got #results={#results}`)
			clearHolder(CoinsHolder)
			for _, entry in ipairs(results) do
				debug(`  coins row: rank={entry.rank} username={entry.username} coins={entry.value}`)
				local cell = getCellForRank(entry.rank)
				local player = (type(entry.userId) == "number") and Players:GetPlayerByUserId(entry.userId) or nil
				setCellLabels(cell, entry.rank, entry.username, tostring(entry.value), player)
				cell.LayoutOrder = entry.rank
				cell.Parent = CoinsHolder
			end
			updatePodiumFromTop3(results)
			debug("refreshCoins() done")
		end

		local function refreshCrowns()
			debug("refreshCrowns() calling Data.getTop20Crowns(" .. TOP_COUNT .. ")")
			local results = Data.getTop20Crowns(TOP_COUNT)
			debug(`refreshCrowns() got #results={#results}`)
			clearHolder(CrownsHolder)
			for _, entry in ipairs(results) do
				debug(`  crowns row: rank={entry.rank} username={entry.username} crowns={entry.value}`)
				local cell = getCellForRank(entry.rank)
				local player = (type(entry.userId) == "number") and Players:GetPlayerByUserId(entry.userId) or nil
				setCellLabels(cell, entry.rank, entry.username, tostring(entry.value), player)
				cell.LayoutOrder = entry.rank
				cell.Parent = CrownsHolder
			end
			debug("refreshCrowns() done")
		end

		local function refreshAll()
			debug("refreshAll() start")
			task.spawn(function()
				refreshCoins()
				refreshCrowns()
				debug("refreshAll() finished")
			end)
		end

		refreshAll()
		debug("started 5-minute refresh loop")
		task.spawn(function()
			while true do
				task.wait(DISPLAY_INTERVAL_SECONDS)
				debug("5-minute tick, refreshing leaderboards")
				refreshAll()
			end
		end)
		debug("init finished")
	end,
	events = {},
}
