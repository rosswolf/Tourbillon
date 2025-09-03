class_name GridMapper
extends Resource

## Maps logical grid positions to physical grid positions
## Handles centering and expansion of the active play area

var logical_size: Vector2i = Vector2i(4, 4)  # Current logical grid size
var physical_size: Vector2i = Vector2i(8, 8)  # Total physical grid size
var offset: Vector2i = Vector2i.ZERO  # Offset for centering

func _init(logical: Vector2i = Vector2i(4, 4), physical: Vector2i = Vector2i(8, 8)) -> void:
	logical_size = logical
	physical_size = physical
	__calculate_offset()

## Calculate the offset to center the logical grid in the physical grid
func __calculate_offset() -> void:
	offset = (physical_size - logical_size) / 2

## Convert logical position to physical position
func to_physical(logical_pos: Vector2i) -> Vector2i:
	if not is_valid_logical(logical_pos):
		push_error("Invalid logical position: " + str(logical_pos))
		return Vector2i(-1, -1)
	return logical_pos + offset

## Convert physical position to logical position (returns null if outside logical area)
func to_logical(physical_pos: Vector2i) -> Variant:
	var logical_pos: Vector2i = physical_pos - offset
	if is_valid_logical(logical_pos):
		return logical_pos
	return null

## Check if a logical position is valid
func is_valid_logical(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < logical_size.x and \
		   pos.y >= 0 and pos.y < logical_size.y

## Check if a physical position maps to a valid logical position
func is_active_physical(pos: Vector2i) -> bool:
	var logical = to_logical(pos)
	return logical != null

## Get all physical positions that are active
func get_active_physical_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(logical_size.y):
		for x in range(logical_size.x):
			var logical_pos: Vector2i = Vector2i(x, y)
			positions.append(to_physical(logical_pos))
	return positions

## Expand the logical grid
func expand(expansion_type: String = "row") -> bool:
	var new_size: Vector2i = logical_size
	
	match expansion_type:
		"row":
			new_size.y += 1
		"column":
			new_size.x += 1
		"both":
			new_size.x += 1
			new_size.y += 1
		_:
			return false
	
	# Check if expansion would exceed physical bounds
	if new_size.x > physical_size.x or new_size.y > physical_size.y:
		return false
	
	logical_size = new_size
	__calculate_offset()
	return true

## Reset to initial size
func reset(initial_size: Vector2i = Vector2i(4, 4)) -> void:
	logical_size = initial_size
	__calculate_offset()

## Get logical size
func get_logical_size() -> Vector2i:
	return logical_size

## Get physical size
func get_physical_size() -> Vector2i:
	return physical_size