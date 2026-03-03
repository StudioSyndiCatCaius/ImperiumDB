

-- =======================================================================================================================
-- START/END
-- =======================================================================================================================

ImpDB_Nodes['node_Start']={
	name="➡️START",
	color={0.7,0.4,0.4,1},
	
	quick_next="node_DialogueLine",

	inputs={ },
	outputs={ {}, },
	
	params={
		
	}

}

ImpDB_Nodes['node_End']={
	name="🛑Exit",
	color={0.7,0.4,0.4,1},
	
	inputs={ {} },
	outputs={ },
	
	params={
		
	}

}

-- =======================================================================================================================
-- HUB
-- =======================================================================================================================

ImpDB_Nodes['node_HUB']={
	name="🔗HUB",
	color={0.1,0.1,0.1,1},
	size={x=75,y=75},

	inputs={ },
	outputs={ {} },
	
	params={
		hub={ type='string'}
	},

    GetDescription=function (d)
        return d['params']['hub']
    end

}

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

-- =======================================================================================================================
-- MISV
-- =======================================================================================================================



ImpDB_Nodes['node_AND']={
	name="AND",
	color={0.1,0.1,0.1,1},
	EmptyDelete=true,
	quick_next="node_DialogueLine",
	
	size={x=50,y=120},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={},
	
	icon_size=70,

}

ImpDB_Nodes['node_random']={
	name="🎲Random",
	color={1,1,1,1},
	size={x=100,y=30},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
	
	},

	GetDescription=function (d)
		return [["Wait : "]]..d['params']['delay']
	end

}

ImpDB_Nodes['node_delay']={
	name="⌛Delay",
	color={0,1,0,1},
	size={x=100,y=60},
	
	inputs={ {} },
	outputs={ {}, },
	
	params={
		delay={ type='number', step=0.01 },
	},

	GetDescription=function (d)
		return [["Wait : "]]..d['params']['delay']
	end

}

ImpDB_Nodes['node_OncePerSave']={
	name="💾Once Per Save",
	color={1,0.2,0.2,1},
	size={x=175,y=100},

	inputs={ {} },
	outputs={ {},{}, },
	
	params={
		condition={type='code'}
	},

	sections={
		{
			GetDescription=function (self)
				return "FIRST TIME"
			end
		},
		{
			GetDescription=function (self)
				return "THEN"
			end
		},
	},

	GetDescription=function (self)
		return self['params']['condition']
	end

}

if _D==nil then _D={} end
_D.eventTypes={
	System={},
	Movie={},
	Menu={},
	Info={},
}

ImpDB_Nodes['node_event']={
	name="EVENT",
	color={0.3,0.3,0.3,1},
	size={x=175,y=100},

	inputs={ {} },
	outputs={ {}, },
	
	params={
		type={type='table', table='eventTypes', order=0 },
		flag={type='string', order=1},
		description={type='text', order=2},
		script={type='code', order=3 },
	},



}