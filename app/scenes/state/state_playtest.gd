extends Control
class_name STATE_playtest



var linked_graph: ui_GraphEdit

@export var lbl_spkr: Label
@export var lbl_line: Label



func LINE_Start(node: ui_GraphNode):

	var typeDATA: Dictionary=node.TypeData.to_dictionary()
	var playtestData:={}
	if typeDATA.has('GetPlaytestData'):
		playtestData=typeDATA['GetPlaytestData'].invoke(node.DATA)
	playtestData=G_Lua.CONV(playtestData)
	
	lbl_spkr.text=playtestData.get('speaker',"")
	lbl_line.text=playtestData.get('line',"")
	
