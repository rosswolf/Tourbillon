extends Node

class_name Entity
static func _get_type_string():
	return "Entity"

var __template_id: String  # Private variable
var template_id: String:  # Public read-only property
	get:
		return __template_id

var __instance_id: String  # Private variable
var instance_id: String:  # Public read-only property
	get:
		return __instance_id
		
var __display_name: String  # Private variable
var display_name: String:  # Public read-only property
	get:
		return __display_name
		

enum EntityType {
	UNKNOWN,
	CARD,
	HERO,
	ENGINE_BUTTON,
	BATTLEGROUND, 
	MAINPLATE,
	RELIC,
	GOAL,
	NONE
}

# Assume we need template id, unless subclasses override this
func __requires_template_id() -> bool:
	return true

func __generate_instance_id() -> String:
	assert(false, "children must override __generate_instance_id")
	return ""

func _get_type() -> Entity.EntityType:
	assert(false, "children must override _get_type")
	return Entity.EntityType.UNKNOWN

class EntityBuilder extends RefCounted:
	var __custom_instance_id: String
	var __template_id: String
	var __display_name: String
	var __scene_uid: String
	
	func with_instance_id(instance_id: String) -> EntityBuilder:
		__custom_instance_id = instance_id
		return self
	
	func with_template_id(template_id: String) -> EntityBuilder:
		__template_id = template_id
		return self
	
	func with_display_name(display_name: String) -> EntityBuilder:
		__display_name = display_name
		return self
		
	func build_entity(entity: Entity) -> Entity:
		if __template_id == "" and entity.__requires_template_id():
			assert(false, "Entity must have a template_id")
			return null
		
		entity.__template_id = __template_id
		
		entity.__display_name = __display_name
		
		if __custom_instance_id != "":
			entity.__instance_id = __custom_instance_id
		else:
			entity.__instance_id = entity.__generate_instance_id()
		
		# Register entity in the instance catalog if it exists
		if GlobalGameManager.instance_catalog != null:
			GlobalGameManager.instance_catalog.set_instance(entity as Node)
		else:
			push_warning("Entity created but instance_catalog is null - instance_id: " + entity.__instance_id)
		
		return entity
