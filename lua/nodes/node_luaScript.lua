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