ImpDB_Nodes['node_delay']={
	name="⌛Delay",
	color={0,1,0,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		delay={ type='number', step=0.01 },
	},

	GetDescription=function (d)
		return [["Wait : "]]..d['params']['delay']
	end

}