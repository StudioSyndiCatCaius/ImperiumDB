return {
	name="Choice Hub",
	color={0,1,0,1},
	
	inputs=[ {} ],
	outputs=[ {}, ],
	
	params={
		text={ type='text', },
		condition={ type='lua', },
		script={ type='lua', },
		type={ type='table', table="ChoiceType" },
	}
	
	GetDescription=function(n)
		return n['text']
	end

}