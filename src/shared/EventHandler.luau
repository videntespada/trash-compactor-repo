local m = {}

local DEBUG_EVENTS = false -- set to true temporarily when debugging remotes
local function debug(msg: string)
	if DEBUG_EVENTS then
		print("[EventHandler]", msg)
	end
end

-- ! Don't use
function m:clean(name: string)
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if result:HasTag("Busy") then
			result:RemoveTag("Busy")
			print(`Cleaned ${name}`)
		end
		return
	end
end

function m:getEvent(name: string): RemoteEvent | string
	local ev = script:FindFirstChild(name)
	if not ev then
		debug(`getEvent("{name}"): Remote does not exist (script = {script:GetFullName()})`)
		return `Remote ${name} does not exist.`
	end
	if not ev:IsA("RemoteEvent") then
		debug(`getEvent("{name}"): found but not RemoteEvent (type {ev.ClassName})`)
		return `Remote ${name} is not a RemoteEvent.`
	end
	return ev :: RemoteEvent
end

function m:createEvent(name: string)
	if script:FindFirstChild(name) then
		debug(`createEvent("{name}"): already exists`)
		return
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = script
	debug(`createEvent("{name}"): created, parent = {script:GetFullName()}`)
end

function m:fireClient(to: Player, name: string, ...: any): string | nil
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		-- if result:HasTag("Busy") then
		-- 	return `Dropped event named ${name}`
		-- end
		-- result:AddTag("Busy")
		result:FireClient(to, ...)
		return
	end
end

function m:fire(name: string, ...: any)
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		debug(`fire("{name}"): FAILED - {result}`)
		return result
	else
		debug(`fire("{name}"): FireServer (args: {select("#", ...)})`)
		result:FireServer(...)
		return
	end
end

function m:broadcast(name: string, ...: any)
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		-- if result:HasTag("Busy") then
		-- 	warn(`{result} is busy.`)
		-- 	return
		-- end
		-- result:AddTag("Busy")
		result:FireAllClients(...)
		return
	end
end

function m:connectClient(name: string, f: (...any) -> ()): string | nil
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		result.OnClientEvent:Connect(f)
		return
	end
end

function m:connect(name: string, f: (...any) -> ())
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		debug(`connect("{name}"): FAILED - {result}`)
		return result
	else
		-- Allow multiple server listeners (e.g. RoundService + GarbageManHandler both listen to throwTrash)
		result.OnServerEvent:Connect(f)
		debug(`connect("{name}"): OnServerEvent connected`)
		return
	end
end

return m
