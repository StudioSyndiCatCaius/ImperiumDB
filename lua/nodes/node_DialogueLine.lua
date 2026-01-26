IMPDB_VOICE_PATH=[[{content}/voices/]]
IMPDB_VOICE_FORMAT=[[ogg]]

ImpDB_Nodes['node_DialogueLine']={
	name="💬Line",
	
	color={0.2,0.8,1,1},
	size={x=210,y=200},

	EmptyDelete=true,
	UseLinkKey=true,

	quick_next="node_DialogueLine",
	
	
	section_count=2,

	

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
	


	sections={
		{
			GetDescription=function (data,index)
				local spkr=""
				local txt=""
				if (data['params']['speaker']) then spkr=data['params']['speaker'] end
				if (data['params']['line']) then txt=data['params']['line'] end
				
				return spkr.." :\n"..[[     "]]..txt..[["]]
			end,

			GetIcon=function (d,index)
				return [[{project}/image/ico_characters_]]..d['params']['speaker']..[[.png]]
			end,
			
		},
		{
			GetDescription=function (data,index)
				return data['direction']
			end,

			text_italic=true,
			text_ratio=0.5,
			text_color={r=1,g=0.9,b=0.7,a=0.5}			
		},
	},


	GetSoundPath=function (p)
		return IMPDB_VOICE_PATH..p['key']..'.'..IMPDB_VOICE_FORMAT
	end,


	ycmd={
		PlayVoice=function (p)
			local pth=IMPDB_VOICE_PATH..p['key']..'.'..IMPDB_VOICE_FORMAT
			print(pth)
			return {
				action="PlaySound",
				path=pth
			}
		end,
	}
}
