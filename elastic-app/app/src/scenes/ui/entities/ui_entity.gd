extends Control
class_name UiEntity

var __is_hovered = false

var __entity: Entity
	
func _ready():
	pass	
	
func set_entity_data(entity:Entity): 
	if not is_node_ready():
		await self.ready
		
	__entity = entity
	
	mouse_entered.connect(__on_mouse_entered)
	mouse_exited.connect(__on_mouse_exited)
	
func __on_mouse_entered() -> void:
	__is_hovered = true
	GlobalSelectionManager.set_hovered(__entity.instance_id)

func __on_mouse_exited() -> void:
	__is_hovered = false
	GlobalSelectionManager.clear_hovered_known(__entity.instance_id)
	
func _exit_tree():
	if __is_hovered:
		__on_mouse_exited()
