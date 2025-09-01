extends BeatListenerEntity
class_name Gremlin

## Base class for gremlins - enemies that disrupt the clockwork mechanism
## Gremlins impose various constraints and must be defeated to win

@export var display_name: String = "Gremlin"
@export var max_hp: int = 10
@export var slot_index: int = 0  # Position in gremlin column (0-4)

var current_hp: int
var shields: int = 0
var poison_stacks: int = 0
var burn_duration: int = 0  # Ticks where healing is disabled
var poison_interval: int = 10  # Beats between poison damage

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
	# Track beat number internally if needed
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
	
	# Process poison on this gremlin's schedule
	if poison_stacks > 0 and beat_number % poison_interval == 0:
		process_poison()

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
	poison_stacks += stacks

## Apply burn (prevents healing)
func apply_burn(ticks: int) -> void:
	burn_duration = max(burn_duration, ticks * 10)  # Convert to beats

## Process poison damage (called by BeatProcessor)
func process_poison() -> void:
	if poison_stacks > 0:
		take_damage(poison_stacks, true)  # Poison pierces shields

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

## Reset for new combat
func reset() -> void:
	current_hp = max_hp
	shields = 0
	poison_stacks = 0
	burn_duration = 0
	beats_until_disruption = disruption_interval_beats