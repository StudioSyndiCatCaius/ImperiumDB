extends Control


func _on_btn_write_all_dir_pressed():
	
	var line_dir_map: Dictionary=G.SCRIPT_GetDirectionTextByLineKey()
	
	print("  --------------------------------------------------------------- ")
	print("			WRITING DIRECTIONS TO FILES")
	print(" --- ")
	var ar= G_File.LIST_AllInDir(G.PATH_GetRoot()+"/flow/",true,true)
	for f in ar:
		if f.get_extension()=="ImpFlow":
			#print("		Opening File: "+str(f))
			var j =G_File.LOAD_Json(f)
			if j:
				for n in j.get('nodes',[]):
					var ind: int=j['nodes'].find(n)
					var line_key=n.get('key','')
					if line_dir_map.has(line_key):
						j['nodes'][ind]['direction']=line_dir_map[line_key]
			
				#write back to file
				var json_string = JSON.stringify(j, "  ")  # Pretty print with 2-space indentation
				
				var file = FileAccess.open(f, FileAccess.WRITE)
				if file == null:
					print("Error opening file for writing: " + f)
					print("Error code: " + str(FileAccess.get_open_error()))
					return false
				
				# Write the JSON string to the file
				file.store_string(json_string)
