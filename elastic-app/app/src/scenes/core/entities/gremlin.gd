extends BeatListenerEntity
class_name Gremlin

## Base class for gremlins - enemies that disrupt the clockwork mechanism
## Gremlins impose various constraints and must be defeated to win

@export var gremlin_name: String = "Gremlin"
@export var max_hp: int = 10
@export var slot_index: int = 0  # Position in gremlin column (0-4)

var current_hp: int
var shields: int = 0
var burn_duration: int = 0  # Ticks where healing is disabled

# Beat consumers for various effects
var beat_consumers: Array[BeatConsumer] = []

# Disruption properties
var disruption_interval_beats: int = 50  # Every 5 ticks by default
var beats_until_disruption: int = 0

signal hp_changed(new_hp: int, max_hp: int)
signal defeated()
signal disruption_triggered(gremlin: Gremlin)

func _init() -> void:
	current_hp = max_hp
	beats_until_disruption = disruption_interval_beats

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

## Take damage
func take_damage(amount: int, pierce: bool = false, pop: bool = false) -> void:
	var damage = amount
	
	# Handle shields
	if shields > 0 and not pierce:
		if pop:
			damage *= 2  # Double damage vs shields
		
		var shield_damage = min(shields, damage)
		shields -= shield_damage
		damage -= shield_damage
		
		if pop and damage > 0:
			damage *= 2  # Excess damage also doubled
	
	# Apply remaining damage to HP
	if damage > 0:
		current_hp -= damage
		hp_changed.emit(current_hp, max_hp)
		
		if current_hp <= 0:
			_on_defeated()

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
	burn_duration = max(burn_duration, ticks * 10)  # Convert to beats

## Get current poison stacks
func get_poison_stacks() -> int:
	for consumer in beat_consumers:
		if consumer is PoisonConsumer:
			return (consumer as PoisonConsumer).get_poison_value()
	return 0

## Heal the gremlin
func heal(amount: int) -> void:
	if burn_duration > 0:
		return  # Can't heal while burned
	
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

## Add shields
func add_shields(amount: int) -> void:
	shields += amount

## Check if can be executed
func can_be_executed(threshold: int) -> bool:
	return current_hp <= threshold

## Execute the gremlin (instant kill if below threshold)
func execute() -> void:
	current_hp = 0
	_on_defeated()

## Trigger this gremlin's disruption
func _trigger_disruption() -> void:
	disruption_triggered.emit(self)
	_apply_disruption()

## Override in subclasses for specific disruptions
func _apply_disruption() -> void:
	pass

## Get disruption description for UI
func get_disruption_text() -> String:
	return "Unknown disruption"

## Called when defeated
func _on_defeated() -> void:
	defeated.emit()
	# Remove disruptions
	_remove_disruptions()

## Override to remove this gremlin's specific disruptions
func _remove_disruptions() -> void:
	pass

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
	beats_until_disruption = disruption_interval_beats
	beat_consumers.clear()