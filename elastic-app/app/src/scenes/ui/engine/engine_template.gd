extends Control
class_name EngineTemplate

@onready var slot_grid_container: GridContainer = $MarginContainer/SlotGridContainer
var engine_slot_scene: PackedScene = preload("res://src/scenes/ui/entities/engine/ui_engine_slot.tscn")

# Grid configuration
@export var rows: int = 3
@export var columns: int = 5

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

# Dictionary to store connections: {from_slot_name: {to_slot_name: ConnectionType}}
var connections: Dictionary = {}

func _ready() -> void:
	GlobalSignals.ui_slot_activated.connect(__on_slot_activated)
	create_engine_slots()
	
func create_engine_slots():
	# Clear any existing children (in case this function is called multiple times)
	for child in slot_grid_container.get_children():
		child.queue_free()
	
	# Wait a frame to ensure children are actually removed
	await get_tree().process_frame
	slot_grid_container.columns = columns
	
	var activation_types = GlobalUtilities.get_engine_trigger_types()
	var training_requirements: Array[int] = GlobalUtilities.generate_random_numbers(9, 18)
	
	# Create slots dynamically
	for row in range(rows):
		for col in range(columns):			
			var slot_instance: EngineSlot = engine_slot_scene.instantiate()
			slot_instance.name = get_slot_name(row, col)
			#slot_instance.slot_activated.connect(_on_slot_activated)
			slot_grid_container.add_child(slot_instance)
			await get_tree().process_frame
			slot_instance.set_training_value(training_requirements.pop_front())
			
			# Bottom row needs activation button visible
			if row == 2:
				slot_instance.set_activation_type(activation_types[col])
	
	TemplateGenerator.generate_template(self)

func recreate_slots(new_rows: int, new_columns: int):
	rows = new_rows
	columns = new_columns
	# Clear existing connections when recreating slots
	connections.clear()
	create_engine_slots()

func get_slot(row: int, col: int) -> EngineSlot:
	return slot_grid_container.get_node(get_slot_name(row, col))	

func get_slot_name(row: int, col: int) -> String:
	return "EngineSlot%d-%d" % [row, col]


##################################################################	
# Connection Management Functions
##################################################################	

func __add_connection(from_row: int, from_col: int, to_row: int, to_col: int, connection_type: EngineSlot.ConnectionType) -> bool:
	var from_slot_name = get_slot_name(from_row, from_col)
	var to_slot_name = get_slot_name(to_row, to_col)
	
	# Validate slot positions
	if not __is_valid_position(from_row, from_col) or not __is_valid_position(to_row, to_col):
		print("Invalid slot positions for connection")
		return false
	
	# Check if slots are adjacent
	if not __are_adjacent(from_row, from_col, to_row, to_col):
		print("Slots must be adjacent to create a connection")
		return false
	
	# Initialize connection dictionary for from_slot if it doesn't exist
	if not connections.has(from_slot_name):
		connections[from_slot_name] = {}
	
	# Add the connection
	connections[from_slot_name][to_slot_name] = connection_type
	
	# Update visual representation
	__update_connection_visuals(from_row, from_col, to_row, to_col, connection_type)
	
	return true

func remove_connection(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	var from_slot_name = get_slot_name(from_row, from_col)
	var to_slot_name = get_slot_name(to_row, to_col)
	
	if connections.has(from_slot_name) and connections[from_slot_name].has(to_slot_name):
		# Remove the connection
		connections[from_slot_name].erase(to_slot_name)
		
		# Clean up empty dictionary
		if connections[from_slot_name].is_empty():
			connections.erase(from_slot_name)
		
		# Update visual representation
		__hide_connection_visuals(from_row, from_col, to_row, to_col)
		
		return true
	
	return false

func get_connections_from_slot(slot_name: String) -> Dictionary:
	if connections.has(slot_name):
		return connections[slot_name]
	return {}

func has_connection(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	var from_slot_name = get_slot_name(from_row, from_col)
	var to_slot_name = get_slot_name(to_row, to_col)
	
	return connections.has(from_slot_name) and connections[from_slot_name].has(to_slot_name)

func clear_all_connections():
	connections.clear()
	# Hide all connection visuals
	for row in range(rows):
		for col in range(columns):
			var slot = get_slot(row, col)
			if slot:
				slot.hide_all_connections()


func __is_valid_position(row: int, col: int) -> bool:
	return row >= 0 and row < rows and col >= 0 and col < columns

func __are_adjacent(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	var row_diff = abs(from_row - to_row)
	var col_diff = abs(from_col - to_col)
	
	# Adjacent means exactly one unit away in either row or column (not diagonal)
	return (row_diff == 1 and col_diff == 0) or (row_diff == 0 and col_diff == 1)

func __get_direction(from_row: int, from_col: int, to_row: int, to_col: int) -> Direction:
	if to_row < from_row:
		return Direction.UP
	elif to_row > from_row:
		return Direction.DOWN
	elif to_col > from_col:
		return Direction.RIGHT
	else:
		return Direction.LEFT

func __update_connection_visuals(from_row: int, from_col: int, to_row: int, to_col: int, connection_type: EngineSlot.ConnectionType):
	var from_slot = get_slot(from_row, from_col)
	var to_slot = get_slot(to_row, to_col)
	
	if not from_slot or not to_slot:
		return
	
	var direction = __get_direction(from_row, from_col, to_row, to_col)
	
	# Show connection visual on the from_slot
	from_slot.show_connection(direction, connection_type)
	
	# For two-way connections, also show on the to_slot
	if connection_type == EngineSlot.ConnectionType.TWO_WAY:
		var reverse_direction = __get_reverse_direction(direction)
		to_slot.show_connection(reverse_direction, connection_type)

func __hide_connection_visuals(from_row: int, from_col: int, to_row: int, to_col: int):
	var from_slot = get_slot(from_row, from_col)
	var to_slot = get_slot(to_row, to_col)
	
	if not from_slot or not to_slot:
		return
	
	var direction = __get_direction(from_row, from_col, to_row, to_col)
	
	# Hide connection visual on the from_slot
	from_slot.hide_connection(direction)
	
	# Also hide on the to_slot (in case it was a two-way connection)
	var reverse_direction = __get_reverse_direction(direction)
	to_slot.hide_connection(reverse_direction)

func __get_reverse_direction(direction: Direction) -> Direction:
	match direction:
		Direction.UP:
			return Direction.DOWN
		Direction.DOWN:
			return Direction.UP
		Direction.LEFT:
			return Direction.RIGHT
		Direction.RIGHT:
			return Direction.LEFT
		_:
			return Direction.UP


func __on_slot_activated(slot_name: String, trigger_card_id: String):	
	var trigger_card: Card = GlobalGameManager.instance_catalog.get(trigger_card_id)
	var slot_connections: Dictionary = get_connections_from_slot(slot_name)
	
	for connected_slot_name in slot_connections.keys():			
		var connected_slot: EngineSlot = slot_grid_container.get_node(connected_slot_name)
		if connected_slot.is_activatable:
			connected_slot.activate(trigger_card)
		

func __get_slot_position_from_name(slot_name: String) -> Vector2i:
	# Parse slot name like "EngineSlot1-1" to get row and column
	var parts = slot_name.split("-")
	if parts.size() != 2:
		assert(false, "Engine Slot name was not formatted correctly: " + slot_name)
	
	var row_part = parts[0].replace("EngineSlot", "")
	var col_part = parts[1]
	
	return Vector2i(row_part.to_int(), col_part.to_int())

# Utility functions for external use

func add_one_way_connection(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	return __add_connection(from_row, from_col, to_row, to_col, EngineSlot.ConnectionType.ONE_WAY)

func add_two_way_connection(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	var success = __add_connection(from_row, from_col, to_row, to_col, EngineSlot.ConnectionType.TWO_WAY)
	if success:
		# For two-way connections, also add the reverse connection
		__add_connection(to_row, to_col, from_row, from_col, EngineSlot.ConnectionType.TWO_WAY)
	return success
