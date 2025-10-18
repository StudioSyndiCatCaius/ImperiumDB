
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
