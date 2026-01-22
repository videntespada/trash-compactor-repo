local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RagdollModule = require(ReplicatedStorage.Shared.RagdollModule)

local TrashClass = {}
TrashClass.__index = TrashClass

export type TrashClass = {
	model: Model?,
	debug: boolean,
	_cleaned: boolean,
	_connection: RBXScriptConnection?,
	_ancestryConnection: RBXScriptConnection?,
	_debugPart: Part?,
	_bounding: Part?,

	StartHitbox: (self: TrashClass) -> (),
	CreateBounding: (self: TrashClass) -> (),
	Clean: (self: TrashClass) -> (),
	new: (model: Model, debug: boolean) -> TrashClass,
}

-- ? Constructor
function TrashClass.new(model: Model, debug: boolean): TrashClass
	local self = setmetatable({}, TrashClass) :: any

	self.model = model
	self.debug = debug
	self._cleaned = false
	self._connection = nil
	self._ancestryConnection = nil
	self._debugPart = nil
	self._bounding = nil

	if self.debug then
		print(`[TrashClass] Created new Trash Object for: {model.Name}`)
	end

	-- ? Self-cleanup watcher
	self._ancestryConnection = self.model.Destroying:Connect(function()
		if self.debug then
			warn(`[TrashClass] Model destroyed by game. Auto-cleaning {self.model and self.model.Name}`)
		end
		self:Clean()
	end)

	return self :: TrashClass
end

function TrashClass:CreateBounding()
	if self._cleaned or not self.model then
		return
	end

	local model = self.model :: Model
	local center = model.PrimaryPart

	if not center then
		warn("[TrashClass] Model has no PrimaryPart!")
		return
	end

	local pivot, modelSize = model:GetBoundingBox()

	local box = Instance.new("Part")
	box.Name = "Bounding"
	box.CanCollide = false
	box.CanTouch = true
	box.CanQuery = true
	box.Size = modelSize
	box.CFrame = pivot

	if self.debug then
		box.Transparency = 0.5
		box.Color = Color3.fromRGB(255, 0, 0)
		box.Material = Enum.Material.Neon
	else
		box.Transparency = 1
	end

	box.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = center
	weld.Part1 = box
	weld.Parent = model

	self._bounding = box
end

-- Start hitbox
function TrashClass:StartHitbox()
	if self._cleaned or not self._bounding then
		return
	end

	if self.debug then
		print(`[TrashClass] Hitbox started for: {self.model.Name}`)
	end

	local AliveFolder = workspace:WaitForChild("Alive", 5)
	if not AliveFolder then
		return
	end

	local touched = {}

	self._connection = self._bounding.Touched:Connect(function(otherPart)
		if self._cleaned then
			return
		end

		local characterModel = otherPart.Parent

		-- ? Validate Hit
		if not characterModel:IsA("Model") then
			return
		end
		if characterModel.Parent ~= AliveFolder then
			return
		end

		local player = Players:GetPlayerFromCharacter(characterModel)
		if not player or not player:HasTag("InRound") then
			return
		end

		local humanoid = characterModel:FindFirstChild("Humanoid") :: Humanoid
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		-- ? Debounce check
		if not touched[characterModel] then
			touched[characterModel] = true

			-- ? death sounds
			if (humanoid.Health - 25) <= 0 then
				local deathSounds = {
					"7772283448",
					"18900008907",
					"8551016315",
					"6349641063",
					"17712048342",
					"114739399228816",
					"6701126635",
				}
				local sound = Instance.new("Sound")
				sound.Parent = characterModel.PrimaryPart
				sound.Volume = 3
				sound.SoundId = `rbxassetid://{deathSounds[math.random(1, #deathSounds)]}`
				sound:Play()
				Debris:AddItem(sound, 5)
			end

			-- ? impact sounds
			local impactSounds = {
				"7772283448",
				"18900008907",
				"8551016315",
				"6349641063",
				"17712048342",
				"114739399228816",
				"6701126635",
			}
			local impactSound = Instance.new("Sound")
			impactSound.Parent = characterModel.PrimaryPart
			impactSound.Volume = 3
			impactSound.SoundId = `rbxassetid://{impactSounds[math.random(1, #impactSounds)]}`
			impactSound:Play()
			Debris:AddItem(impactSound, 5)

			-- ? damage & physics
			humanoid:TakeDamage(25)
			RagdollModule.TimedRagdoll(characterModel, 1)

			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
			bv.Velocity = (Vector3.yAxis * 20) + (characterModel:GetPivot().LookVector * -42)
			bv.Parent = characterModel.PrimaryPart -- Parent last
			Debris:AddItem(bv, 0.1)
		end
	end)
end

function TrashClass:Clean()
	if self._cleaned then
		return
	end
	self._cleaned = true

	if self.debug then
		print(`[TrashClass] Cleaning up memory for: {self.model and self.model.Name or "Unknown"}`)
	end

	-- ? Disconnect Events
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	if self._ancestryConnection then
		self._ancestryConnection:Disconnect()
		self._ancestryConnection = nil
	end

	-- ? Destroy created parts
	if self._debugPart then
		self._debugPart:Destroy()
		self._debugPart = nil
	end

	-- ? If self.model is destroyed, bounding goes with it.
	-- ! If self.model is NOT destroyed but we are cleaning, we might want to destroy bounding.
	if self._bounding and self._bounding.Parent then
		self._bounding:Destroy()
	end
	self._bounding = nil

	-- ? Nullify References
	self.model = nil
end

return TrashClass
