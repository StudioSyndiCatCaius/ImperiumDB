ImpDB_Nodes['node_luaScript']={
	name="🔵Lua Script",
	color={0,0,1,1},
	size={x=200,y=120},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		script={ type='code', },
	},

	GetDescription=function(data)
		return data['params']['script']
	end,

}

ImpDB_Nodes['node_luaIf']={
	name="🔵Lua If",
	color={1,0,0,1},
	size={x=175,y=100},

	inputs={ {} },
	outputs={ {},{}, },
	
	params={
		condition={ type='code', },
	},

	GetDescription=function(data)
		return data['params']['condition']
	end,

}