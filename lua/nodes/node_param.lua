ImpDB_Nodes['node_paramSet']={
	name="🏴󠁧󠁢󠁥󠁮󠁧󠁿Param - Set",
	color={0.1,1,1,1},
	size={x=150,y=75},

	inputs={ {} },
	outputs={ {}, },
	
	params={
		param={ type='table', table='params' },
		value={ type='number', step=1 },
	},

	GetDescription=function(data)
		return data['params']['param']..[[ = ]]..data['params']['value']
	end,

}

ImpDB_Nodes['node_paramBool']={
	name="🏴󠁧󠁢󠁥󠁮󠁧󠁿Param - If",
	color={1,0,0,1},
	size={x=100,y=100},

	inputs={ {} },
	outputs={ {},{}, },
	
	params={
		param={ type='table', table='params' },
	},

	GetDescription=function(data)
		return data['params']['param']..[[ >= 1 ]]
	end,

}