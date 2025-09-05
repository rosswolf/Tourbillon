extends BeatListenerEntity
class_name Gremlin

## Base class for gremlins - enemies that disrupt the clockwork mechanism
## Gremlins impose various constraints and must be defeated to win
## Uses composition pattern with Damageable for unified damage handling

@export var gremlin_name: String = "Gremlin"
@export var max_hp: int = 10
@export var slot_index: int = 0  # Position in gremlin column (0-4)
@export var moves_string: String = ""  # Downsides/moves from data

# Damageable properties
var current_hp: int
var shields: int = 0
var armor: int = 0
var barrier_count: int = 0
var burn_duration: int = 0

# Advanced defenses
@export var damage_cap: int = 0
@export var damage_resistance: float = 0.0
@export var reflect_percent: float = 0.0
@export var execute_immunity_threshold: int = 0
@export var invulnerable: bool = false

# Internal damage handler using composition
var _damage_handler: Damageable

# Beat consumers for various effects
var beat_consumers: Array[BeatConsumer] = []

# Move cycle data
var move_queue: Array[MoveData] = []
var background_effects: Array[MoveData] = []  # Always-active effects (0 ticks)
var current_move_index: int = 0
var current_move: MoveData = null
var beats_until_move_complete: int = 0  # Track beats for smooth progress

# Disruption properties (deprecated - using move queue now)
var disruption_interval_beats: int = 50  # Every 5 ticks by default
var beats_until_disruption: int = 0

signal hp_changed(new_hp: int, max_hp: int)
signal defeated()
signal disruption_triggered(gremlin: Gremlin)

func _init() -> void:
	current_hp = max_hp
	beats_until_disruption = disruption_interval_beats

	# Create internal damage handler
	_damage_handler = Damageable.new()
	_damage_handler.damage_received.connect(_on_damage_received)
	_damage_handler.hp_changed.connect(_on_hp_changed)
	_damage_handler.defeated.connect(_on_defeated_internal)

	# Note: Core objects don't use scene tree - damage handler works without add_child
	# Defer initial sync and moves processing since exported properties aren't set yet
	call_deferred("_initialize_gremlin")

func _initialize_gremlin() -> void:
	# Sync properties with damage handler
	if _damage_handler:
		_sync_to_handler()

	# Process moves/downsides when gremlin spawns (only if not using move queue)
	if not moves_string.is_empty() and move_queue.is_empty():
		GremlinDownsideProcessor.process_gremlin_moves(moves_string, self)

## Process beat for gremlin behaviors
func process_beat(context: BeatContext) -> void:
	# Process all beat consumers (poison, etc.)
	for i in range(beat_consumers.size() - 1, -1, -1):
		var consumer = beat_consumers[i]
		if consumer.is_active:
			consumer.process_beat(context)

			# Remove exhausted consumers
			if consumer.should_remove():
				beat_consumers.remove_at(i)

	# Track beat number for burn effect
	var beat_number = get_meta("total_beats", 0) + 1
	set_meta("total_beats", beat_number)

	# Count down beats for smooth progress
	if beats_until_move_complete > 0:
		beats_until_move_complete -= 1
		
		# Check if we complete the move (hit 0)
		if beats_until_move_complete == 0:
			_process_tick()

	# Process burn effect
	if burn_duration > 0:
		if beat_number % 10 == 0:  # Each tick
			burn_duration -= 1

## Process move completion
func _process_tick() -> void:
	if not current_move or move_queue.is_empty():
		return
	
	# Move has completed (beats countdown reached 0)
	print("[DEBUG] ", gremlin_name, " completing move: ", current_move.effect_type)
	_complete_current_move()
	_advance_to_next_move()

## Main damage interface using unified system
func receive_damage(packet: DamagePacket) -> int:
	if not _damage_handler:
		return 0

	_sync_to_handler()
	var damage = _damage_handler.receive_damage(packet)
	_sync_from_handler()
	return damage

## Legacy damage interface - converts to damage packet
func take_damage(amount: int, pierce: bool = false, pop: bool = false) -> void:
	var keywords: Array[String] = []
	if pierce: keywords.append("pierce")
	if pop: keywords.append("pop")

	var packet = DamageFactory.create(amount, keywords, "")
	receive_damage(packet)

## Apply poison
func apply_poison(stacks: int) -> void:
	# Find existing poison consumer or create new one
	var poison_consumer: PoisonConsumer = null

	for consumer in beat_consumers:
		if consumer is PoisonConsumer:
			poison_consumer = consumer as PoisonConsumer
			break

	if poison_consumer:
		poison_consumer.add_poison(stacks)
	else:
		poison_consumer = PoisonConsumer.new(stacks)
		poison_consumer.owner = self
		beat_consumers.append(poison_consumer)

## Apply burn (prevents healing)
func apply_burn(ticks: int) -> void:
	if _damage_handler:
		_damage_handler.apply_burn(ticks)
		burn_duration = _damage_handler.burn_duration

## Get current poison stacks
func get_poison_stacks() -> int:
	for consumer in beat_consumers:
		if consumer is PoisonConsumer:
			return (consumer as PoisonConsumer).get_poison_value()
	return 0

## Heal the gremlin
func heal(amount: int) -> int:
	if not _damage_handler:
		return 0
	_sync_to_handler()
	var healed = _damage_handler.heal(amount)
	_sync_from_handler()
	return healed

## Add shields
func add_shields(amount: int) -> void:
	if _damage_handler:
		_damage_handler.add_shields(amount)
		shields = _damage_handler.shields

## Check if can be executed
func can_be_executed(threshold: int) -> bool:
	if _damage_handler:
		return _damage_handler.can_be_executed(threshold)
	return current_hp <= threshold

## Execute the gremlin (instant kill if below threshold)
func execute() -> void:
	if _damage_handler:
		_damage_handler.execute()
	else:
		current_hp = 0
		_on_defeated()

## Trigger this gremlin's disruption
func _trigger_disruption() -> void:
	disruption_triggered.emit(self)
	_apply_disruption()

## Override in subclasses for specific disruptions
func _apply_disruption() -> void:
	# Process disruption effects through the processor
	GremlinDownsideProcessor.trigger_disruption(self)

## Get disruption description for UI
func get_disruption_text() -> String:
	if current_move:
		return current_move.get_display_text()
	if not move_queue.is_empty():
		return move_queue[0].get_display_text()
	return "No special effects"

## Set up move queue from parsed data
func set_move_queue(moves: Array[MoveData], background: Array[MoveData]) -> void:
	move_queue = moves
	background_effects = background
	
	print("[DEBUG] Setting move queue for ", gremlin_name)
	print("[DEBUG] Cycled moves: ", move_queue.size())
	for i in range(move_queue.size()):
		var move = move_queue[i]
		print("[DEBUG]   Move ", i+1, ": ", move.effect_type, "=", move.effect_value, " @ ", move.tick_duration, " ticks")
	print("[DEBUG] Background effects: ", background_effects.size())
	
	# Apply all background effects immediately
	for effect in background_effects:
		_apply_move_effect(effect, true)
	
	# Start with first cycled move if available
	if not move_queue.is_empty():
		current_move_index = 0
		_load_move_at_index(0)

## Load a move from the queue
func _load_move_at_index(index: int) -> void:
	if index >= move_queue.size():
		return
		
	current_move = move_queue[index]
	# Convert ticks to beats for smooth countdown (1 tick = 10 beats)
	beats_until_move_complete = current_move.tick_duration * 10
	
	# Apply persistent effects immediately
	if current_move.is_persistent_effect():
		_apply_move_effect(current_move, true)

## Complete the current move
func _complete_current_move() -> void:
	if not current_move:
		return
	
	# Execute triggered actions
	if current_move.is_triggered_action():
		_apply_move_effect(current_move, false)
	
	# Remove persistent effects
	if current_move.is_persistent_effect():
		_remove_move_effect(current_move)

## Advance to next move in cycle
func _advance_to_next_move() -> void:
	current_move_index = (current_move_index + 1) % move_queue.size()
	_load_move_at_index(current_move_index)

## Apply a move's effect
func _apply_move_effect(move: MoveData, is_starting: bool) -> void:
	# Parse effect type and apply through processor
	var effect_string = move.effect_type + "=" + str(move.effect_value)
	GremlinDownsideProcessor._process_single_downside(effect_string, self)
	
	# For triggered actions that fire at the end
	if not is_starting and move.is_triggered_action():
		match move.effect_type:
			"attack":
				GremlinDownsideProcessor._execute_attack(move.effect_value)
			"force_discard":
				GremlinDownsideProcessor._force_discard_cards(move.effect_value)
			"summon":
				GremlinDownsideProcessor._summon_gremlin(move.effect_type.split("=")[1] if "=" in move.effect_type else "basic_gnat")
			_:
				# Handle drains
				if "drain" in move.effect_type:
					var drain_type = move.effect_type.replace("drain_", "")
					GremlinDownsideProcessor._execute_drain(drain_type, move.effect_value)

## Remove a move's effect (for persistent effects)
func _remove_move_effect(move: MoveData) -> void:
	# This would need to track and remove specific effects
	# For now, recalculate all downsides
	GremlinDownsideProcessor.recalculate_all_downsides()

## Sync properties to damage handler
func _sync_to_handler() -> void:
	if not _damage_handler:
		return
	_damage_handler.max_hp = max_hp
	_damage_handler.current_hp = current_hp
	_damage_handler.armor = armor
	_damage_handler.shields = shields
	_damage_handler.barrier_count = barrier_count
	_damage_handler.damage_cap = damage_cap
	_damage_handler.damage_resistance = damage_resistance
	_damage_handler.reflect_percent = reflect_percent
	_damage_handler.execute_immunity_threshold = execute_immunity_threshold
	_damage_handler.invulnerable = invulnerable
	_damage_handler.burn_duration = burn_duration

## Sync properties from damage handler
func _sync_from_handler() -> void:
	if not _damage_handler:
		return
	current_hp = _damage_handler.current_hp
	shields = _damage_handler.shields
	barrier_count = _damage_handler.barrier_count
	burn_duration = _damage_handler.burn_duration

## Signal handlers from damage handler
func _on_damage_received(packet: DamagePacket, actual_damage: int) -> void:
	# Could add gremlin-specific logic here
	pass

func _on_hp_changed(new_hp: int, max: int) -> void:
	current_hp = new_hp
	hp_changed.emit(new_hp, max_hp)

func _on_defeated_internal() -> void:
	_on_defeated()

## Called when defeated
func _on_defeated() -> void:
	defeated.emit()
	# Remove disruptions
	_remove_disruptions()

## Override to remove this gremlin's specific disruptions
func _remove_disruptions() -> void:
	# Remove this gremlin's downsides
	GremlinDownsideProcessor.remove_gremlin_downsides(self)

## Add a beat consumer to this gremlin
func add_beat_consumer(consumer: BeatConsumer) -> void:
	consumer.owner = self
	beat_consumers.append(consumer)

## Remove a beat consumer
func remove_beat_consumer(consumer: BeatConsumer) -> void:
	beat_consumers.erase(consumer)

## Reset for new combat
func reset() -> void:
	current_hp = max_hp
	shields = 0
	burn_duration = 0
	barrier_count = 0
	armor = 0
	beats_until_disruption = disruption_interval_beats
	beat_consumers.clear()

	if _damage_handler:
		_sync_to_handler()

## Override Entity methods
func _get_type() -> Entity.EntityType:
	return Entity.EntityType.GREMLIN

func __generate_instance_id() -> String:
	return "gremlin_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func __requires_template_id() -> bool:
	return false  # Gremlins don't use template IDs

## Builder pattern for proper Entity initialization
class GremlinBuilder extends Entity.EntityBuilder:
	var __gremlin_name: String = "Gremlin"
	var __max_hp: int = 10
	var __shields: int = 0
	var __armor: int = 0
	var __barriers: int = 0
	var __moves_string: String = ""
	var __slot_index: int = 0

	func with_name(name: String) -> GremlinBuilder:
		__gremlin_name = name
		return self

	func with_hp(hp: int) -> GremlinBuilder:
		__max_hp = hp
		return self

	func with_shields(amount: int) -> GremlinBuilder:
		__shields = amount
		return self

	func with_armor(amount: int) -> GremlinBuilder:
		__armor = amount
		return self

	func with_barriers(count: int) -> GremlinBuilder:
		__barriers = count
		return self

	func with_moves(moves: String) -> GremlinBuilder:
		__moves_string = moves
		return self

	func with_slot(slot: int) -> GremlinBuilder:
		__slot_index = slot
		return self

	func build() -> Gremlin:
		var gremlin: Gremlin = Gremlin.new()
		gremlin.gremlin_name = __gremlin_name
		gremlin.max_hp = __max_hp
		gremlin.current_hp = __max_hp
		gremlin.shields = __shields
		gremlin.armor = __armor
		gremlin.barrier_count = __barriers
		gremlin.moves_string = __moves_string
		gremlin.slot_index = __slot_index
		# Proper Entity initialization
		return build_entity(gremlin) as Gremlin
