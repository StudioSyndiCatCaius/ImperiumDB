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