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