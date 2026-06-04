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
	read new: (callback: (...any) -> (), parent: SignalInternal) -> ConnectionInternal,
}

--- Signal ---
type SignalPrivateAttributes = {
	_head: ConnectionInternal?,
	_tail: ConnectionInternal?,
}

export type SignalPublicMethods<self, args...> = {
	read Connect: (self: self, Callback: (args...) -> ()) -> ConnectionObject,
	read Once: (self: self, Callback: (args...) -> ()) -> ConnectionObject,
	read Wait: (self: self) -> args...,
	read Fire: (self: self, args...) -> (),
	read DisconnectAll: (self: self) -> (),
	read Destroy: (self: self) -> (),
}

export type SignalObject<args...> = SignalPublicMethods<SignalObject<args...>, args...>
export type SignalInternal = SignalPublicMethods<SignalInternal, ...any> & SignalPrivateAttributes

export type SignalClass = {
	new: () -> SignalObject<...any>,
}

return {}
