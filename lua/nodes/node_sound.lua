

return {
	name="🔊 Sound",
	color={1,0.5,0.5,1},
	EmptyDelete=true,
	quick_next="node_DialogueLine",
	
	size={x=180,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		sound={ type='table', fileType="WAV", filePath=[[{project}/sounds/]], 
		order=-2 },
	},
	
	icon_size=70,

	GetDescription=function (d)
		return d['params']['sound']
	end

}