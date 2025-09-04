extends CanvasLayer

@onready var pause_modal := $PauseModal
@onready var card_selection_modal := $CardSelectionModal
@onready var game_over_modal := $GameOverModal

func _ready() -> void:
	pass


							



#func __check_node_tree_for_mouse(node: Node, mouse_pos: Vector2) -> bool:
	## Check if this node is a Control node and if mouse is over it
	#if node is Control:
		#var control = node as Control
		## Skip invisible or non-interactive controls
		#if control.visible and not control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			#var global_rect = Rect2(control.global_position, control.size)
			#if global_rect.has_point(mouse_pos):
				#return true
	#
	## Recursively check all children
	#for child in node.get_children():
		#if __check_node_tree_for_mouse(child, mouse_pos):
			#return true
	#
	#return false
