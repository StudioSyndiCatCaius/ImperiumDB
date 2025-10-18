ImpDB_Nodes['node_ToHub']={
	name="🔗to HUB",
	color={0.1,0.1,0.1,1},
	size={x=75,y=75},

	inputs={ {} },
	outputs={ },
	
	params={
		hub={ type='string'}
	},

    GetDescription=function (d)
        return d['params']['hub']
    end
}