return {
	name="Choice",
	color={0,1,0,1},
	quick_next="node_DialogueLine",

	size={x=200,y=75},

	inputs={ {} },
	outputs={ {}, },
	
	params={
		text={ type='text', },
		condition={ type='code', },
		script={ type='code', },
		type={ type='table', table="TypeChoice" },
		face={ type='table', table="faces" },
	},
	
	GetDescription=function(n)
		return n['params']['text']
	end

}