local m = {}

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
	local ev = script:WaitForChild(name)
	if ev then
		return ev
	else
		return `Remote ${name} does not exist.`
	end
end

function m:createEvent(name: string)
	if script:FindFirstChild(name) then
		return
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = script
	print(`${ev.name} created!`)
end

function m:fireClient(to: Player, name: string, ...: any): string | nil
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if result:HasTag("Busy") then
			return `Dropped event named ${name}`
		end
		result:AddTag("Busy")
		result:FireClient(to, ...)
		return
	end
end

function m:fire(name: string, ...: any)
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if result:HasTag("Busy") then
			return `Dropped event named ${name}`
		end
		result:AddTag("Busy")
		result:FireServer(...)
		return
	end
end

function m:broadcast(name: string, ...: any)
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if result:HasTag("Busy") then
			return `Dropped event named ${name}`
		end
		result:AddTag("Busy")
		result:FireAllClients(...)
		return
	end
end

function m:connectClient(name: string, f: (...any) -> ()): string | nil
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if not result:HasTag("Busy") and not result:HasTag("ClientConnected") then
			result.OnClientEvent:Connect(f)
			result:AddTag("ClientConnected")
		end
		return
	end
end

function m:connect(name: string, f: (...any) -> ())
	local result = self:getEvent(name)

	if typeof(result) == "string" then
		return result
	else
		if not result:HasTag("Busy") and not result:HasTag("ServerConnected") then
			result.OnClientEvent:Connect(f)
			result:AddTag("ServerConnected")
		end
		return
	end
end

return m
