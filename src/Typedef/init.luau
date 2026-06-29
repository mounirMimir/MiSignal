--!strict
const Util = require("@self/Util")
type Flatten<t> = Util.FlattenTable<t>

--- Connection ---
type ConnectionPublicAttributes = {
	read Connected: boolean,
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

export type ConnectionObject = Flatten<ConnectionPublicMethods<any> & ConnectionPublicAttributes>
export type ConnectionInternal = Util.ReadWrite<ConnectionObject> & ConnectionPrivateAttributes

export type ConnectionClass = {
	new: (callback: (...any) -> (), parent: SignalInternal) -> ConnectionInternal,
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

export type SignalObject<args...> = SignalPublicMethods<any, args...>
export type SignalInternal = SignalPublicMethods<any, ...any> & SignalPrivateAttributes

export type SignalClass = {
	new: () -> SignalObject<...any>,
}

return {}
