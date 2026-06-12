extends Control

@export var btn_write_all_dir: Button

func _ready():
	if !G.active_project.UserMeta_GetBool("enable_direction_import"):
		btn_write_all_dir.queue_free()

func _on_btn_write_all_dir_pressed():
	var _script_path=G.active_project.DATA.get('linked_script',"")
	var _str=Z_File.LoadFileAsString(_script_path)
	var raw_dic: Array=Z_Parse.from_CSV(_str,true)
	var line_dir_map={}

	var last_key:=""
	var last_dir:=""
	
	for i in raw_dic:
	
		var check_key:String=i.get('key',"")
		print("getting keys from line: "+check_key)
		
		#if reached a new valid key
		if check_key!=last_key && !check_key.is_empty():
			#if last bulked direction is NOT empty, then apply it to current key
			if !last_dir.is_empty() && !last_key.is_empty():
				line_dir_map[last_key]=last_dir
			#clear direction & update to new key
			last_dir=""
			last_key=check_key
		
		#if this direction line has text, apply it on next line break to bulk dir
		var apnd: String=i.get('direction',"")
		if !apnd.is_empty():
			last_dir+=apnd+"\n"
	
	#dump direction table into json
	Z_File.SaveStringAsFile(G.PATH_GetRoot()+"/_dump/DirectionDump.json", Z_Parse.to_JSON(line_dir_map),true,true)
	
	print("  --------------------------------------------------------------- ")
	print("			WRITING DIRECTIONS TO FILES")
	print(" --- ")

	var ar= Z_File.ListFilesInDir(G.PATH_GetRoot()+"/flow/",true,true)
	for f: String in ar:
		if f.get_extension()=="ImpFlow":
			
			#LOAD flow from JSON format
			var j =Z_Parse.from_JSON(Z_File.LoadFileAsString(f))
			if j:
				var _nodes=j.get('nodes',[])
				for n in _nodes:
					var ind: int=j['nodes'].find(n)
					var line_key=n.get('key','')
					if line_dir_map.has(line_key):
						var dir_line=line_dir_map.get(line_key,"")
						j['nodes'][ind]['direction']=dir_line
				
				Z_File.SaveStringAsFile(f,Z_Parse.to_JSON(j),true,true)
			
			
