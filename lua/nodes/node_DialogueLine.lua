ImpDB_Nodes['node_DialogueLine']={
	name="💬Line",
	
	color={0.2,0.8,1,1},
	size={x=200,y=180},

	EmptyDelete=true,
	UseLinkKey=true,

	quick_next="node_DialogueLine",
	

	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		speaker={ type='table', table="characters", order=-2 },
		line={ type='text' , order=-1 },
		
		camera={ type='string', },
		emote={ type='string', },
		face={ type='table', table="faces" },
		position={ type='table', table="positions", options={"C","L1","L2","L3","R1","R2","R3"} },
		
		script={ type='code', order=2 },
		condition={ type='code', order=3 },

		tags={ type='string', order=10},
	},
	
	
	GetDescription=function(data)
		local spkr=""
		local txt=""
		if (data['params']['speaker']) then spkr=data['params']['speaker'] end
		if (data['params']['line']) then txt=data['params']['line'] end
		
		return spkr.." :\n"..[[     "]]..txt..[["]]
	end,

	GetIcon=function (d)
		return [[{project}/image/ico_characters_]]..d['params']['speaker']..[[.png]]
	end,


}