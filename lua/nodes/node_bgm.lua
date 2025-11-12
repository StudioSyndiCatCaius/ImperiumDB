ImpDB_Nodes['node_d_bgm']={
	name="🎵BGM - Play",


	color={0.4,0,1,1},
	size={x=125,y=90},

	inputs={ {} },
	outputs={ {},},
	
	params={

		bgm={ type='table', table="BGM",  },
		NoFade={ type='bool', },
	},

	GetDescription=function(data)
		return [[BGM: ]]..data['params']['bgm']
	end,

	OnBegin=function (data)
		
	end

}