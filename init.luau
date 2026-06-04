--!strict
--!native
--!optimize 2
----- Typedef -----
local Typedef = require("@self/Typedef")

type ConnectionInternal = Typedef.ConnectionInternal
export type ConnectionObject = Typedef.ConnectionObject
type ConnectionClass = Typedef.ConnectionClass

type SignalInternal = Typedef.SignalInternal
export type MiSignal<args...> = Typedef.SignalObject<args...>
type SignalClass = Typedef.SignalClass

----- Free Runner Thread -----

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

----- Connection Class -----
local ConnectionClass: ConnectionClass

local ConnectionPublicMethos: Typedef.ConnectionPublicMethods<ConnectionInternal> = {
	Disconnect = function(self)
		if not self.Connected then
			return
		end
		(self :: any).Connected = false

		local prev, next = self._prev, self._next
		local parent = self._parent

		if parent._head == self then
			parent._head = next
		end
		if parent._tail == self then
			parent._tail = prev
		end
		if prev then
			prev._next = next
		end
		self._prev, self._next = nil, nil
	end,
}

ConnectionClass = {
	new = function(callback: (...any) -> (), parent: SignalInternal)
		local self: ConnectionInternal = {
			_Callback = callback,
			_next = nil,
			_prev = nil,
			_parent = parent,
			Connected = true,
			Disconnect = ConnectionPublicMethos.Disconnect,
		}

		return self
	end,
}

----- Signal Class -----
local SignalClass: SignalClass

local SignalPublicMethods: Typedef.SignalPublicMethods<SignalInternal> = {
	Connect = function(self, callback: (...any) -> ())
		local cn = ConnectionClass.new(callback, self)
		local tail = self._tail

		if tail then
			tail._next = cn
			cn._prev = tail
		else
			self._head = cn
		end

		self._tail = cn

		return cn
	end,

	Once = function(self, callback: (...any) -> ())
		local cn: ConnectionObject
		cn = self:Connect(function(...)
			callback(...)
			cn:Disconnect()
		end)
		return cn
	end,

	Wait = function(self)
		local thread = coroutine.running()
		local cn: ConnectionObject
		cn = self:Connect(function(...)
			cn:Disconnect()
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, ...)
			end
		end)
		return coroutine.yield()
	end,

	Fire = function(self, ...)
		local node = self._head
		while node do
			if node.Connected then
				if not freeRunnerThread then
					freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
					coroutine.resume(freeRunnerThread :: thread)
				end
				task.spawn(freeRunnerThread :: thread, node._Callback, ...)
			end
			node = node._next
		end
	end,

	DisconnectAll = function(self)
		local node = self._head
		self._head = nil
		self._tail = nil
		while node do
			node.Connected = false
			node = node._next
		end
	end,

	Destroy = function(self)
		self:DisconnectAll()
	end,
}

SignalClass = {
	new = function()
		local self: SignalInternal = {
			_head = nil,
			_tail = nil,
			Once = SignalPublicMethods.Once,
			Connect = SignalPublicMethods.Connect,
			Wait = SignalPublicMethods.Wait,
			Fire = SignalPublicMethods.Fire,
			DisconnectAll = SignalPublicMethods.DisconnectAll,
			Destroy = SignalPublicMethods.Destroy,
		}

		return self :: MiSignal<...any>
	end,
}

return SignalClass
