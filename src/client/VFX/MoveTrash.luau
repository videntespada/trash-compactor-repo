local RunService = game:GetService("RunService")
local Map = workspace:WaitForChild("Map")
local Scriptable = Map:FindFirstChild("Scriptable")
local SnapParts = Scriptable:FindFirstChild("SnapParts") :: Folder

local prev
local mouseRef = Scriptable:WaitForChild("PlaceZone") :: Part
local refPart = Instance.new("Part")
refPart.Parent = workspace
refPart.Color = Color3.fromRGB(0, 255, 55)
refPart.Material = Enum.Material.Neon
refPart.Anchored = true
refPart.CanCollide = false
refPart.Size = Vector3.new(2, 2, 2)

local snapConnection

local function snapTo(targetPart, toMove)
	if snapConnection then
		snapConnection:Disconnect()
		snapConnection = nil
	end

	local _, objectSize = toMove:GetBoundingBox()
	local yOffset = (targetPart.Size.Y / 2) + (objectSize.Y / 2)

	snapConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local currentCF = toMove:GetPivot()

		local targetCF = targetPart.CFrame + Vector3.new(0, yOffset, 0)

		local dist = (currentCF.Position - targetCF.Position).Magnitude

		if dist < 0.05 then
			toMove:PivotTo(targetCF)
			snapConnection:Disconnect()
			snapConnection = nil
		else
			toMove:PivotTo(currentCF:Lerp(targetCF, 0.2))
		end
	end)
end

return function(type: "Snapped" | "Mouse", character: Model, toMove: Model, mousePosition: Vector3?)
	if type == "Snapped" then
		-- Loop through all snap parts, and detect which one is closest.
		local t: {
			{
				instance: Part,
				distance: number,
			}
		} = {}
		for i, v in ipairs(SnapParts:GetChildren() :: { Part }) do
			local distance = (v.Position - character:GetPivot().Position).Magnitude
			t[1 + #t] = {
				instance = v,
				distance = distance,
			}
		end
		table.sort(
			t,
			function(a0: { distance: number, instance: Part }, a1: { distance: number, instance: Part }): boolean
				return a0.distance < a1.distance
			end
		)

		local closestItem = t[1]
		if closestItem.instance == prev then
			table.clear(t)
			return
		end

		prev = closestItem.instance
		warn(`Positioning at ${closestItem.instance}`)

		--! Debug
		-- for i, v in ipairs(t) do
		-- 	if i == 1 then
		-- 		-- closest
		-- 		v.instance.Transparency = 0
		-- 		v.instance.Color = Color3.fromRGB(255, 0, 0)
		-- 		v.instance.Material = Enum.Material.Neon
		-- 	else
		-- 		-- others
		-- 		v.instance.Transparency = 0.5
		-- 		v.instance.Color = Color3.fromRGB(112, 112, 112)
		-- 		v.instance.Material = Enum.Material.SmoothPlastic
		-- 	end
		-- end
		table.clear(t)
		snapTo(closestItem.instance, toMove)
		return closestItem.instance.Position
	else
		if not mousePosition then
			warn("Debug: mousePosition is nil")
			return
		end

		if not refPart then
			warn("Debug: refPart is MISSING (nil)!")
			return
		end

		if not mouseRef then
			warn("Debug: mouseRef is MISSING (nil)!")
			return
		end

		-- ! Debug
		-- local maxOffset = (mouseRef.Size.Z / 2) - (refPart.Size.Z / 2)

		-- if maxOffset < 0 then
		-- 	maxOffset = 0
		-- end

		-- local centerZ = mouseRef.Position.Z
		-- local minZ = centerZ - maxOffset
		-- local maxZ = centerZ + maxOffset

		-- local clampedZ = math.clamp(mousePosition.Z, minZ, maxZ)

		-- refPart.Position = Vector3.new(mouseRef.Position.X, mouseRef.Position.Y, clampedZ)

		local _, size = toMove:GetBoundingBox()
		local maxOffset = (mouseRef.size.Z / 2) - (size.Z / 2)

		if maxOffset < 0 then
			maxOffset = 0
		end

		local centerZ = mouseRef.Position.Z
		local minZ = centerZ - maxOffset
		local maxZ = centerZ + maxOffset
		local clampedZ = math.clamp(mousePosition.Z, minZ, maxZ)
		local targetY = mouseRef.Position.Y + (mouseRef.Size.Y / 2) + (size.Y / 2)

		toMove:PivotTo(CFrame.new(Vector3.new(mouseRef.Position.X, targetY, clampedZ)))
		return toMove:GetPivot().Position
	end
end
