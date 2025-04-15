extends Node


func Save(res: Resource, path: String):
	ResourceSaver.save(res,path)

func Load(path: String) -> Resource:
	return ResourceLoader.load(path)
