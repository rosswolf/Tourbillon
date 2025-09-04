extends Node

class_name InstanceCatalog

var __instance_catalog: Dictionary[String, Node] = {}

func has_instance(instance_id: String) -> bool:
	return __instance_catalog.has(instance_id)
	
func get_instance(instance_id: String) -> Node:
	return __instance_catalog.get(instance_id)
	
func set_instance(instance: Node) -> void:
	if not instance:
		assert(false, "Entity must not be null")
	if not instance.get("instance_id"):
		assert(false, "Set instance must have a node that contains an instance_id")
	__instance_catalog[instance.instance_id] = instance
	
func clear_instance(instance_id: String, delete: bool) -> void:
	var entity: Node = __instance_catalog.get(instance_id)
	if entity and delete and entity.has_method("delete"):
		entity.call("delete")
	__instance_catalog.erase(instance_id)
	
