extends Damageable
class_name Gremlin

## Base class for gremlins - enemies that disrupt the clockwork mechanism
## Gremlins impose various constraints and must be defeated to win
## Now extends Damageable for unified damage handling

@export var gremlin_name: String = "Gremlin"
@export var slot_index: int = 0  # Position in gremlin column (0-4)
@export var moves_string: String = ""  # Downsides/moves from data

# Properties moved to Damageable base class:
# - max_hp, current_hp, shields, burn_duration, armor, barriers, etc.

# Beat consumers for various effects
var beat_consumers: Array[BeatConsumer] = []

# Disruption properties
var disruption_interval_beats: int = 50  # Every 5 ticks by default
var beats_until_disruption: int = 0

# Signals hp_changed, defeated are now in Damageable base class
signal disruption_triggered(gremlin: Gremlin)

func _init() -> void:
	# Initialize HP from Damageable
	current_hp = max_hp
	beats_until_disruption = disruption_interval_beats
	
func _ready() -> void:
	# Process moves/downsides when gremlin spawns
	if not moves_string.is_empty():
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
	
	# Count down to disruption
	if beats_until_disruption > 0:
		beats_until_disruption -= 1
		
		if beats_until_disruption == 0:
			_trigger_disruption()
			beats_until_disruption = disruption_interval_beats
	
	# Process burn effect
	if burn_duration > 0:
		if beat_number % 10 == 0:  # Each tick
			burn_duration -= 1

## Legacy damage interface - converts to damage packet
## @deprecated Use receive_damage(packet) instead
func take_damage(amount: int, pierce: bool = false, pop: bool = false) -> void:
	var keywords: Array[String] = []
	if pierce: keywords.append("pierce")
	if pop: keywords.append("pop")
	
	var packet = DamageFactory.create(amount, keywords, null)
	receive_damage(packet)

## Override to handle gremlin-specific damage modifiers
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
	# Gremlin-specific damage modifications can go here
	# e.g., resistance to certain damage types
	return packet

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

# apply_burn is now inherited from Damageable

## Get current poison stacks
func get_poison_stacks() -> int:
	for consumer in beat_consumers:
		if consumer is PoisonConsumer:
			return (consumer as PoisonConsumer).get_poison_value()
	return 0

# heal, add_shields, can_be_executed, and execute are now inherited from Damageable

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
	if moves_string.is_empty():
		return "No special effects"
	return GremlinDownsideProcessor.get_downside_description(moves_string)

## Override defeated handler to remove disruptions
func _on_defeated() -> void:
	super._on_defeated()  # Call parent to emit signal
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
	# Reset Damageable properties
	current_hp = max_hp
	shields = 0
	burn_duration = 0
	barrier_count = 0
	# Reset gremlin-specific properties
	beats_until_disruption = disruption_interval_beats
	beat_consumers.clear()

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
