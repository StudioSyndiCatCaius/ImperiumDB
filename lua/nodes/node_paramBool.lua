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