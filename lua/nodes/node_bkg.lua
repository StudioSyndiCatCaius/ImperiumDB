
local icoB=function (key)
	return [[{project}/image/bkg/]]..key..[[_0.png]]
end


local ico=function (d)
	return icoB(d["params"]['bkg'])
end



ImpDB_Nodes['node_bkg']={
	name="🖼️Change BKG",
	color={1,1,1,1},
	EmptyDelete=true,
	quick_next="node_DialogueLine",
	
	size={x=100,y=75},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		bkg={ type='table', fileType="tmj", filePath=[[{project}/bkg/]], 
		GetIcon=icoB,
		order=-2 },
	},
	
	icon_size=70,
	GetIcon=ico,

}