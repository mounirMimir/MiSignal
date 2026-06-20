--!strict
--- Connection ---
type ConnectionPublicAttributes = {
	Connected: boolean,
}

type ConnectionPrivateAttributes = {
	_Callback: (...any) -> (),
	_next: ConnectionInternal?,
	_prev: ConnectionInternal?,
	_parent: SignalInternal,
}

export type ConnectionPublicMethods<self> = {
	Disconnect: (self: self) -> (),
}

export type ConnectionObject = ConnectionPublicMethods<ConnectionObject> & ConnectionPublicAttributes
export type ConnectionInternal =
	ConnectionPublicMethods<ConnectionInternal>
	& ConnectionPrivateAttributes
	& ConnectionPublicAttributes

export type ConnectionClass = {
	new: (callback: (...any) -> (), parent: SignalInternal) -> ConnectionInternal,
}

--- Signal ---
type SignalPrivateAttributes = {
	_head: ConnectionInternal?,
	_tail: ConnectionInternal?,
}

export type SignalPublicMethods<self, args...> = {
	Connect: (self: self, Callback: (args...) -> ()) -> ConnectionObject,
	Once: (self: self, Callback: (args...) -> ()) -> ConnectionObject,
	Wait: (self: self) -> args...,
	Fire: (self: self, args...) -> (),
	DisconnectAll: (self: self) -> (),
	Destroy: (self: self) -> (),
}

export type SignalObject<args...> = SignalPublicMethods<any, args...>
export type SignalInternal = SignalPublicMethods<any, ...any> & SignalPrivateAttributes

export type SignalClass = {
	new: () -> SignalObject<...any>,
}

return {}
