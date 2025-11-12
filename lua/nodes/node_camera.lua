
ImpDB_Nodes['node_Cam']={
	name="🎥Camera",
	color={0.2,0.2,0.2,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		camera={ type='string', step=0.01 },
        blend_time={ type='number', step=0.01 },
		fade_start={ type='number', step=0.01 },
        fade_end={ type='number', step=0.01 },
	},

	GetDescription=function (d)
		return [["To Camera : "]]..d['params']['camera']..[[ over ]]..d['params']['camera']..[[ seconds.]]
	end

}



ImpDB_Nodes['node_Camfade']={
	name="🎥Fade",
	color={0.2,0.2,0.2,1},
	size={x=100,y=60},
	quick_next="node_delay",
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		fade_start={ type='number', step=0.01 },
        fade_end={ type='number', step=0.01 },
	},

	GetDescription=function (d)
		return [["Fade : "]]..d['params']['fade_end']
	end

}
