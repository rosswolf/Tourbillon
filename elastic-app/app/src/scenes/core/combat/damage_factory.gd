extends Node
class_name DamageFactory

## Factory for creating properly configured damage packets
## Damage values already include force multipliers from card data

## Create damage packet with keywords
static func create(amount: int, keywords: Array[String] = [], source_instance_id: String = "") -> DamagePacket:
	var packet = DamagePacket.new()
	packet.amount = amount  # This value already has force multipliers baked in
	packet.source_instance_id = source_instance_id
	packet.timestamp_beats = GlobalGameManager.current_beat if GlobalGameManager else 0

	# Apply keywords
	for keyword in keywords:
		match keyword.to_lower():
			"pierce":
				packet.pierce = true
			"pop":
				packet.pop = true
			"overkill":
				packet.overkill = true
			"poison":
				packet.poison = true
				packet.damage_type = DamagePacket.DamageType.POISON
			"true", "true_damage":
				packet.true_damage = true

	return packet

## Create basic damage packet
static func create_basic(amount: int, source_instance_id: String = "") -> DamagePacket:
	return create(amount, [], source_instance_id)

## Create damage packet from effect string
static func from_effect(effect_string: String, source_instance_id: String = "") -> DamagePacket:
	var packet = DamagePacket.new()
	packet.source_instance_id = source_instance_id
	packet.timestamp_beats = GlobalGameManager.current_beat if GlobalGameManager else 0

	# Parse effect string for damage amount and keywords
	# e.g., "damage=5,pierce,pop" or just "5,pierce"
	var parts = effect_string.split(",")

	for part in parts:
		var trimmed = part.strip_edges()

		if trimmed.contains("="):
			var kv = trimmed.split("=")
			var key = kv[0].strip_edges()
			var value = kv[1].strip_edges()

			match key.to_lower():
				"damage", "amount":
					packet.amount = int(value)
				"type":
					packet.damage_type = _parse_damage_type(value)
		elif trimmed.is_valid_int():
			# If it's just a number, treat it as damage amount
			packet.amount = int(trimmed)
		else:
			# Keywords without values
			match trimmed.to_lower():
				"pierce":
					packet.pierce = true
				"pop":
					packet.pop = true
				"overkill":
					packet.overkill = true
				"poison":
					packet.poison = true
					packet.damage_type = DamagePacket.DamageType.POISON
				"true", "true_damage":
					packet.true_damage = true

	return packet

## Create an execute packet
static func create_execute(threshold: int, source_instance_id: String = "") -> DamagePacket:
	var packet = DamagePacket.new()
	packet.damage_type = DamagePacket.DamageType.EXECUTE
	packet.amount = threshold  # Store threshold in amount
	packet.source_instance_id = source_instance_id
	packet.true_damage = true
	packet.timestamp_beats = GlobalGameManager.current_beat if GlobalGameManager else 0
	return packet

## Create a poison damage packet
static func create_poison(amount: int, source_instance_id: String = "") -> DamagePacket:
	var packet = DamagePacket.new()
	packet.amount = amount
	packet.damage_type = DamagePacket.DamageType.POISON
	packet.poison = true
	packet.pierce = true  # Poison typically bypasses defenses
	packet.source_instance_id = source_instance_id
	packet.timestamp_beats = GlobalGameManager.current_beat if GlobalGameManager else 0
	return packet

## Create a reflect damage packet
static func create_reflect(amount: int, source_instance_id: String = "") -> DamagePacket:
	var packet = DamagePacket.new()
	packet.amount = amount
	packet.damage_type = DamagePacket.DamageType.REFLECT
	packet.true_damage = true  # Reflected damage can't be reduced
	packet.source_instance_id = source_instance_id
	packet.timestamp_beats = GlobalGameManager.current_beat if GlobalGameManager else 0
	return packet

## Helper: Parse damage type from string
static func _parse_damage_type(type_str: String) -> DamagePacket.DamageType:
	match type_str.to_lower():
		"normal":
			return DamagePacket.DamageType.NORMAL
		"poison":
			return DamagePacket.DamageType.POISON
		"reflect", "reflected":
			return DamagePacket.DamageType.REFLECT
		"execute", "execution":
			return DamagePacket.DamageType.EXECUTE
		_:
			return DamagePacket.DamageType.NORMAL
