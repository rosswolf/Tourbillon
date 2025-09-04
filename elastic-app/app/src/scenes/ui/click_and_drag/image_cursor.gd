extends Cursor
class_name ImageCursor

func _ready() -> void:
	z_index = 4096

func set_cursor_position(pos: Vector2):
	if not is_node_ready():
		await self.ready
	global_position = pos
	
func _physics_process(delta: float) -> void:
	global_position = get_global_mouse_position()

func update_image(texture_uid: String) -> void:
	%CursorImage.texture = GlobalUtilities.load_image_uid(texture_uid)
