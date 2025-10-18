ImpDB_Nodes['node_Comment']={
	name="Comment",
	color={0.5,0.5,0.5,0.5},
	size={x=300,y=300},
    exapndable=true,

	inputs={ },
	outputs={ },
	
	params={
		comment={ type='text'}
	},

    GetDescription=function (d)
        return d['params']['comment']
    end,
    description_size=16,
}