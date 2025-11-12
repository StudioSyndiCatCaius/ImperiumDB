ImpDB_Nodes['node_cinematic']={
	name="🎞️Cinematic",
	color={1,0,0,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		cinematic={ type='string', },
	},

	GetDescription=function (d)
		return d['params']['cinematic']
	end

}