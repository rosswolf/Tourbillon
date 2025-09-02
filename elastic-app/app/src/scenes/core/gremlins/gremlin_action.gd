extends BeatConsumer
class_name GremlinAction

# Action timing
enum Timing {
	EVERY_N_BEATS,      # Every N beats
	EVERY_N_TICKS,      # Every N ticks
	ON_DAMAGE_TAKEN,    # When damaged
	ON_ALLY_DEATH,      # When another gremlin dies
	ON_SPAWN,           # When first created
	ON_DEATH,           # When destroyed
	WHEN_BELOW_HALF,    # When health < 50%
	RANDOM_CHANCE,      # X% chance each beat
	ALWAYS,             # Every opportunity
	CONDITIONAL         # Based on custom condition
}

# Base action properties
var action_name: String = "Unknown Action"
var timing: Timing = Timing.EVERY_N_BEATS
var timing_value: int = 1  # For EVERY_N timing types
var chance: float = 1.0  # For RANDOM_CHANCE timing
var priority: int = 0  # Higher priority actions go first
var energy_cost: int = 0  # Energy required to perform

# Visual/audio properties
var animation_name: String = ""
var sound_effect: String = ""
var telegraph_duration: float = 0.5  # Time to show intent

# Execution tracking
var last_execution_beat: int = -1
var last_execution_tick: int = -1
var execution_count: int = 0

# Check if action can be performed
func can_execute(gremlin: Entity, current_beat: int, current_tick: int) -> bool:
	# Check energy cost
	if energy_cost > 0:
		if gremlin.has_method("get_energy") and gremlin.get_energy() < energy_cost:
			return false
	
	# Check timing
	match timing:
		Timing.EVERY_N_BEATS:
			return (current_beat - last_execution_beat) >= timing_value
		
		Timing.EVERY_N_TICKS:
			return (current_tick - last_execution_tick) >= timing_value
		
		Timing.RANDOM_CHANCE:
			return randf() < chance
		
		Timing.ALWAYS:
			return true
		
		Timing.ON_SPAWN:
			return execution_count == 0
		
		Timing.WHEN_BELOW_HALF:
			if gremlin.has_method("is_below_half_health"):
				return gremlin.is_below_half_health()
		
		Timing.CONDITIONAL:
			return check_custom_condition(gremlin)
		
		_:
			return false

# Execute the action (to be overridden by subclasses)
func execute(gremlin: Entity) -> void:
	# Track execution
	execution_count += 1
	last_execution_beat = GlobalGameManager.get_current_beat() if GlobalGameManager.has_method("get_current_beat") else 0
	last_execution_tick = GlobalGameManager.get_current_tick() if GlobalGameManager.has_method("get_current_tick") else 0
	
	# Consume energy if required
	if energy_cost > 0 and gremlin.has_method("consume_energy"):
		gremlin.consume_energy(energy_cost)
	
	# Play animation/sound
	if animation_name != "" and gremlin.has_method("play_animation"):
		gremlin.play_animation(animation_name)
	
	if sound_effect != "" and gremlin.has_method("play_sound"):
		gremlin.play_sound(sound_effect)
	
	# Actual execution in subclasses
	__execute_action(gremlin)

# Override this in subclasses
func __execute_action(gremlin: Entity) -> void:
	pass

# Check custom condition (override in subclasses)
func check_custom_condition(gremlin: Entity) -> bool:
	return true

# Get action description for UI
func get_description() -> String:
	return action_name

# Get intent preview (what the action will do)
func get_intent() -> Dictionary:
	return {
		"name": action_name,
		"timing": Timing.keys()[timing],
		"value": timing_value
	}

# Clone the action (for instances)
func clone() -> GremlinAction:
	var new_action = duplicate()
	new_action.last_execution_beat = -1
	new_action.last_execution_tick = -1
	new_action.execution_count = 0
	return new_action