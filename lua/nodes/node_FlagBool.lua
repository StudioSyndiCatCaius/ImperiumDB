return {
	name="Param - If",
	color={1,0,0,1},
	size={x=175,y=100},

	inputs={ {} },
	outputs={ {},{}, },
	
	params={
		param={ type='table', table='params' },
	},

	GetDescription=function(data)
		return data['params']['param']
	end,

}