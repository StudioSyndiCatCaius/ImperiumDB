ImpDB_Nodes['node_affinityEdit']={
	name="❤️Affinity Edit",
	color={0,1,0.7,1},
	size={x=175,y=100},

	inputs={ {} },
	outputs={ {}, },
	
	params={
		character={ type='table', table='characters' },
        amount={ type='number',  step=1 },
	},

	GetDescription=function(data)
        local p=data['params']
		return p['character']..[[ + ]]..p['amount']
	end,

    icon_size=40,
    GetIcon=function (d)
		return [[{project}/image/ico_characters_]]..d['params']['character']..[[.png]]
	end,

    --called when this node is run in game
    Run=function (d)
        local p=d['params']
        Affinity_Add(p['character'],p['amount'])
    end

}