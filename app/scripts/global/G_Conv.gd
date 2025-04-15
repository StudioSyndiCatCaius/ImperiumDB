extends Node


# ======================================================================
# Vector 2
# ======================================================================
func Vec2_to_Dic(vec: Vector2) -> Dictionary:
	return {"x": vec.x, "y": vec.y}
	
func Dic_to_Vec2(dic: Dictionary) -> Vector2:
	return Vector2(dic.get("x", 0), dic.get("y", 0))
