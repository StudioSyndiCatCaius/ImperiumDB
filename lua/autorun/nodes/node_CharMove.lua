ImpDB_Nodes['node_CharMoveTo']={
	name="🧍Move to (Point)",
	color={0.2,0.2,0.2,1},
	size={x=100,y=60},

	inputs={ {} },
	outputs={ {}, },
	
	params={
		character={ type='table', table='characters', order=0  },
        target={ type='string', order=1},
        teleport={ type='bool', order=2},
	},

	GetDescription=function (d)
		return d['params']['character']..[[ moves to ]]..d['params']['target']
	end,

}

ImpDB_Nodes['node_CharMoveToC']={
	name="🧍Move to (Character)",
	color={0.2,0.2,0.2,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		character={ type='table', table='characters', order=0},
        target={ type='table', table='characters', order=1},
        teleport={ type='bool', order=2},
	},

	GetDescription=function (d)
		return d['params']['character']..[[ moves to ]]..d['params']['target']
	end,

}


ImpDB_Nodes['node_CharMoveToP']={
	name="🧍Move to (Position)",
	color={0.2,0.2,0.2,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		character={ type='table', table='characters', order=0},
        target={ type='table', table='positions', order=1},
        teleport={ type='bool', order=2},
	},

	GetDescription=function (d)
		return d['params']['character']..[[ moves to ]]..d['params']['target']
	end,

}