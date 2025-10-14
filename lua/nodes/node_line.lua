return {
	name="Line",
	color={0,0,1,1},
	
	inputs=[ {} ],
	outputs=[ {} ],
	
	params={
		speaker={ type='table', },
		text={ type='text' },
		
		camera={ type='string', },
		emote={ type='string', },
		face={ type='string', },
		
		script={ type='lua', },
		condition={ type='lua', },

	}
	
	
	GetDescription=function(n)
		return n['speaker']..[[ : "]]..n['text]..[["]]
	end

}