extends Node
class_name GremlinManager

## Manages all gremlins in combat
## Maintains order and provides interface for gremlin operations

var gremlin_slots: Array[Gremlin] = [null, null, null, null, null]  # Max 5 gremlins
var active_gremlin_count: int = 0

signal gremlin_added(gremlin: Gremlin, slot: int)
signal gremlin_defeated(gremlin: Gremlin, slot: int)
signal all_gremlins_defeated()

## Add a gremlin to the combat
func add_gremlin(gremlin: Gremlin, slot: int = -1) -> bool:
	# Find slot if not specified
	if slot == -1:
		slot = _find_empty_slot()
		if slot == -1:
			push_error("No empty gremlin slots available")
			return false
	
	# Validate slot
	if slot < 0 or slot >= gremlin_slots.size():
		push_error("Invalid gremlin slot: " + str(slot))
		return false
	
	if gremlin_slots[slot] != null:
		push_error("Gremlin slot already occupied: " + str(slot))
		return false
	
	# Add gremlin
	gremlin_slots[slot] = gremlin
	gremlin.slot_index = slot
	gremlin.defeated.connect(_on_gremlin_defeated.bind(gremlin))
	active_gremlin_count += 1
	
	gremlin_added.emit(gremlin, slot)
	return true

## Get all active gremlins in order
func get_gremlins_in_order() -> Array[Gremlin]:
	var active_gremlins: Array[Gremlin] = []
	
	for gremlin in gremlin_slots:
		if gremlin != null and is_instance_valid(gremlin):
			active_gremlins.append(gremlin)
	
	return active_gremlins

## Get gremlin at specific slot
func get_gremlin_at_slot(slot: int) -> Gremlin:
	if slot < 0 or slot >= gremlin_slots.size():
		return null
	return gremlin_slots[slot]

## Get topmost gremlin
func get_topmost_gremlin() -> Gremlin:
	for gremlin in gremlin_slots:
		if gremlin != null and is_instance_valid(gremlin):
			return gremlin
	return null

## Get bottommost gremlin
func get_bottommost_gremlin() -> Gremlin:
	for i in range(gremlin_slots.size() - 1, -1, -1):
		if gremlin_slots[i] != null and is_instance_valid(gremlin_slots[i]):
			return gremlin_slots[i]
	return null

## Get weakest gremlin (lowest HP)
func get_weakest_gremlin() -> Gremlin:
	var weakest: Gremlin = null
	var lowest_hp: int = 999999
	
	for gremlin in gremlin_slots:
		if gremlin != null and is_instance_valid(gremlin):
			if gremlin.current_hp < lowest_hp:
				lowest_hp = gremlin.current_hp
				weakest = gremlin
	
	return weakest

## Get strongest gremlin (highest HP)
func get_strongest_gremlin() -> Gremlin:
	var strongest: Gremlin = null
	var highest_hp: int = 0
	
	for gremlin in gremlin_slots:
		if gremlin != null and is_instance_valid(gremlin):
			if gremlin.current_hp > highest_hp:
				highest_hp = gremlin.current_hp
				strongest = gremlin
	
	return strongest

## Deal damage using unified damage system
func deal_damage_to_target(packet: DamagePacket, target_type: String = "topmost") -> void:
	match target_type:
		"all":
			for gremlin in get_gremlins_in_order():
				gremlin.receive_damage(packet)
		_:
			var target = _get_target_by_type(target_type)
			if target:
				target.receive_damage(packet)

## Legacy damage interface - converts to damage packet
## @deprecated Use deal_damage_to_target(packet, target_type) instead
func deal_damage_to_target_legacy(amount: int, target_type: String = "topmost", 
						   pierce: bool = false, pop: bool = false, 
						   overkill: bool = false) -> void:
	# Legacy support - convert to damage packet
	var keywords: Array[String] = []
	if pierce: keywords.append("pierce")
	if pop: keywords.append("pop")
	if overkill: keywords.append("overkill")
	
	var packet = DamageFactory.create(amount, keywords, null)
	deal_damage_to_target(packet, target_type)

## Handle overkill damage carrying to next target
func apply_overkill_damage(original_packet: DamagePacket, excess_damage: int) -> void:
	var next_target = get_topmost_gremlin()
	if next_target:
		# Create new packet for overkill damage
		var overkill_packet = original_packet.duplicate(true) as DamagePacket
		overkill_packet.amount = excess_damage
		overkill_packet.overkill = false  # Prevent infinite chain
		
		next_target.receive_damage(overkill_packet)

## Apply poison to target
func apply_poison_to_target(stacks: int, target_type: String = "topmost") -> void:
	var target = _get_target_by_type(target_type)
	if target:
		target.apply_poison(stacks)

## Execute gremlins below threshold
func execute_below_threshold(threshold: int) -> void:
	for gremlin in get_gremlins_in_order():
		if gremlin.can_be_executed(threshold):
			gremlin.execute()

## Check if all gremlins are defeated
func are_all_defeated() -> bool:
	return active_gremlin_count == 0

## Reset for new combat
func reset() -> void:
	for i in range(gremlin_slots.size()):
		if gremlin_slots[i]:
			gremlin_slots[i].queue_free()
			gremlin_slots[i] = null
	active_gremlin_count = 0

## Internal: Find first empty slot
func _find_empty_slot() -> int:
	for i in range(gremlin_slots.size()):
		if gremlin_slots[i] == null:
			return i
	return -1

## Internal: Get target by type string
func _get_target_by_type(target_type: String) -> Gremlin:
	match target_type:
		"topmost":
			return get_topmost_gremlin()
		"bottommost":
			return get_bottommost_gremlin()
		"weakest":
			return get_weakest_gremlin()
		"strongest":
			return get_strongest_gremlin()
		_:
			return null

## Internal: Handle gremlin defeat
func _on_gremlin_defeated(gremlin: Gremlin) -> void:
	var slot = gremlin.slot_index
	gremlin_slots[slot] = null
	active_gremlin_count -= 1
	
	gremlin_defeated.emit(gremlin, slot)
	
	if active_gremlin_count == 0:
		all_gremlins_defeated.emit()