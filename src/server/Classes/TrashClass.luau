--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RagdollModule = require(ReplicatedStorage.Shared.RagdollModule)

-- Move static data outside to avoid re-creating tables on every hit
local DEATH_SOUNDS =
	{ "7772283448", "18900008907", "8551016315", "6349641063", "17712048342", "114739399228816", "6701126635" }
local IMPACT_SOUNDS =
	{ "7772283448", "18900008907", "8551016315", "6349641063", "17712048342", "114739399228816", "6701126635" }

local TrashClass = {}
TrashClass.__index = TrashClass

export type TrashClass = {
	model: Model?,
	debug: boolean,
	_cleaned: boolean,
	_connection: RBXScriptConnection?,
	_ancestryConnection: RBXScriptConnection?,
	_bounding: Part?,
	_owner: Player?,

	new: (model: Model, debug: boolean) -> TrashClass,
	CreateBounding: (self: TrashClass) -> string?,
	StartHitbox: (self: TrashClass) -> (),
	ProcessHit: (self: TrashClass, character: Model) -> (), -- New Method
	Clean: (self: TrashClass) -> (),
}

function TrashClass.new(owner: Player, model: Model, debug: boolean): TrashClass
	local self = setmetatable({}, TrashClass) :: any
	self.model = model
	self.debug = debug
	self._cleaned = false

	self._ancestryConnection = self.model.Destroying:Connect(function()
		self:Clean()
	end)

	return self :: TrashClass
end

function TrashClass:CreateBounding()
	local model = self.model :: Model
	if not model then
		return "[TrashClass] No model to bound"
	end

	local center = model.PrimaryPart
	if not center then
		return "[TrashClass] No PrimaryPart"
	end

	local pivot, modelSize = model:GetBoundingBox()

	local box = Instance.new("Part")
	box.Name = "Bounding"
	box.CanCollide, box.CanTouch, box.CanQuery = false, true, true
	box.Size = modelSize * 1.3
	box.CFrame = pivot
	box.Transparency = self.debug and 0.7 or 1
	if self.debug then
		box.Color = Color3.fromRGB(255, 0, 0)
	end
	box.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = center
	weld.Part1 = box
	weld.Parent = model
	self._bounding = box
	return "Finished"
end

function TrashClass:ProcessHit(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character.PrimaryPart
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)

	if player and player:HasTag("hasShield") then
		warn(`${player} has hit`)
		local sound = Instance.new("Sound")
		sound.Parent = root
		sound.SoundId = "rbxassetid://130409300190276"
		sound.Volume = 1
		sound:Play()
		Debris:AddItem(sound, 2)

		local trashModel = self.model :: Model
		local trashPart = trashModel.PrimaryPart

		if trashPart then
			trashPart.AssemblyLinearVelocity = Vector3.zero
			trashPart.AssemblyAngularVelocity = Vector3.zero

			local bounceDirection = (character:GetPivot().LookVector * 60) + (Vector3.yAxis * 25)

			local trashBv = Instance.new("BodyVelocity")
			trashBv.MaxForce = Vector3.one * math.huge
			trashBv.Velocity = bounceDirection
			trashBv.Parent = trashPart -- Parent last
			Debris:AddItem(trashBv, 0.15)
		end

		-- root.AssemblyLinearVelocity = Vector3.zero
		-- local playerRecoil = Instance.new("BodyVelocity")
		-- playerRecoil.MaxForce = Vector3.one * math.huge
		-- playerRecoil.Velocity = (character:GetPivot().LookVector * -15) + (Vector3.yAxis * 5)
		-- playerRecoil.Parent = root
		-- Debris:AddItem(playerRecoil, 0.1)

		return
	end

	local isFinalBlow = (humanoid.Health - 25) <= 0
	local soundId = isFinalBlow and DEATH_SOUNDS[math.random(1, #DEATH_SOUNDS)]
		or IMPACT_SOUNDS[math.random(1, #IMPACT_SOUNDS)]
	
	if isFinalBlow and self.owner then
		ServerEvents.onGarbageManKill:Fire(self.owner)
	end

	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{soundId}`
	sound.Volume = 3
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, 5)

	humanoid:TakeDamage(25)
	RagdollModule.TimedRagdoll(character, 1)

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bv.Velocity = (Vector3.yAxis * 20) + (character:GetPivot().LookVector * -42)
	bv.Parent = root
	Debris:AddItem(bv, 0.1)
end

-- Detection Logic
function TrashClass:StartHitbox()
	if self._cleaned or not self._bounding then
		return
	end

	local AliveFolder = workspace:WaitForChild("Alive", 5)
	local touched = {}

	self._connection = self._bounding.Touched:Connect(function(otherPart)
		if self._cleaned then
			return
		end

		local touchedModel = otherPart:FindFirstAncestorWhichIsA("Model")

		if touchedModel.Parent == Workspace:FindFirstChild("Ignore") then
			-- ? All mechanics are seperated by tags of what it touched.
			
			-- ? Wall Mechanic
			if touchedModel:HasTag("WallObstacle") then
				local wall = touchedModel
				local wallSize = wall:GetExtentsSize()
				local wallCF = wall:GetPivot() :: CFrame
				local trashModel = self._bounding.Parent

				trashModel.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
				trashModel.PrimaryPart.AssemblyLinearVelocity = Vector3.zero

				-- Position ontop of wall
				local ontopOf = wallCF * CFrame.new(0, wallSize.Y, 0)
				trashModel:PivotTo(ontopOf)

				-- Throw backwards
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
				bv.Velocity = (-wallCF.LookVector * 50) + (Vector3.yAxis * 50)
				bv.Parent = (trashModel.PrimaryPart :: BasePart)
				Debris:AddItem(bv, 0.1)
			end
		end

		if touchedModel.Parent ~= AliveFolder then
			return
		end
		if touched[touchedModel] then
			return
		end

		local player = Players:GetPlayerFromCharacter(touchedModel)
		if not player or player:HasTag("GarbageMan") or not player:HasTag("InRound") then
			return
		end

		-- Call the separated logic
		touched[touchedModel] = true
		self:ProcessHit(touchedModel)
		table.clear(touched)
	end)
end

function TrashClass:Clean()
	if self._cleaned then
		return
	end
	self._cleaned = true

	if self._connection then
		self._connection:Disconnect()
	end
	if self._ancestryConnection then
		self._ancestryConnection:Disconnect()
	end
	if self._bounding then
		self._bounding:Destroy()
	end

	self.model = nil
	self.owner = nil
end

return TrashClass
