extends Node
class_name WaveManager

## Manager for wave progression and gremlin encounters
## Loads wave data and coordinates spawning with GremlinSpawnController

signal wave_started(wave_id: String, wave_data: Dictionary)
signal wave_completed(wave_id: String)
signal all_waves_completed()
signal boss_encountered(boss_wave: Dictionary)

static var instance: WaveManager

# Wave progression
var current_wave_id: String = ""
var current_wave_data: Dictionary = {}
var current_act: int = 1
var waves_completed: Array[String] = []

# Wave data cache
var all_waves: Array = []
var waves_by_act: Dictionary = {}  # act_number -> Array of waves
var boss_waves: Array = []

func _init() -> void:
	if instance == null:
		instance = self

func _ready() -> void:
	# Load wave data on ready
	_load_wave_data()
	
	# Connect to spawn controller signals
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.all_gremlins_defeated.connect(_on_all_gremlins_defeated)

## Load wave data from sheets or hardcoded data
func _load_wave_data() -> void:
	# Hardcoded wave data from update_wave_sheet.js
	# In production, this would load from Google Sheets or JSON
	all_waves = [
		{
			"wave_id": "wave_1a",
			"display_name": "First Contact",
			"act": 1,
			"difficulty": 13,
			"difficulty_tier": "Trivial",
			"archetype": "Rush Threat - Single Constraint",
			"strategy_hint": "Teaches soft caps and resource spending pressure",
			"gremlins": "dust_mite",
			"is_boss": false
		},
		{
			"wave_id": "wave_1b",
			"display_name": "Mechanical Disruption",
			"act": 1,
			"difficulty": 17,
			"difficulty_tier": "Easy",
			"archetype": "Disruption Threat - Timing Penalty",
			"strategy_hint": "Teaches timing efficiency and card sequencing",
			"gremlins": "gear_tick",
			"is_boss": false
		},
		{
			"wave_id": "wave_1c",
			"display_name": "Armored Introduction",
			"act": 1,
			"difficulty": 17,
			"difficulty_tier": "Easy",
			"archetype": "Turtle Threat - Armor Tutorial",
			"strategy_hint": "Teaches armor mechanics and sustained damage",
			"gremlins": "rust_speck",
			"is_boss": false
		},
		{
			"wave_id": "wave_1d",
			"display_name": "Swarm Basics",
			"act": 1,
			"difficulty": 3,
			"difficulty_tier": "Trivial",
			"archetype": "Pure Swarm - AOE Tutorial",
			"strategy_hint": "Teaches AOE vs single-target efficiency",
			"gremlins": "basic_gnat|basic_gnat|basic_gnat",
			"is_boss": false
		},
		{
			"wave_id": "wave_2a",
			"display_name": "Turtle and Rush",
			"act": 2,
			"difficulty": 69,
			"difficulty_tier": "Hard",
			"archetype": "Turtle + Rush Combination",
			"strategy_hint": "Tests priority targeting - rush vs turtle elimination",
			"gremlins": "oil_thief|dust_mite|dust_mite",
			"is_boss": false
		},
		{
			"wave_id": "boss_1",
			"display_name": "The Rust King's Domain",
			"act": 3,
			"difficulty": 399,
			"difficulty_tier": "Nightmare+",
			"archetype": "Phase Transition + Scaling Support",
			"strategy_hint": "Ultimate resource management + adaptation test",
			"gremlins": "rust_king_phase_1|spring_snapper|spring_snapper",
			"is_boss": true
		}
	]
	
	# Organize waves by act
	for wave in all_waves:
		var act = wave.get("act", 1)
		if not waves_by_act.has(act):
			waves_by_act[act] = []
		waves_by_act[act].append(wave)
		
		# Track boss waves separately
		if wave.get("is_boss", false):
			boss_waves.append(wave)
	
	print("Loaded ", all_waves.size(), " waves across ", waves_by_act.size(), " acts")

## Start a specific wave by ID
func start_wave(wave_id: String) -> bool:
	var wave_data = get_wave_data(wave_id)
	if wave_data.is_empty():
		push_error("Wave not found: " + wave_id)
		return false
	
	return _start_wave_internal(wave_data)

## Start the next wave in sequence
func start_next_wave() -> bool:
	# Get next wave based on current progression
	var next_wave = _get_next_wave()
	if next_wave.is_empty():
		all_waves_completed.emit()
		return false
	
	return _start_wave_internal(next_wave)

## Start a wave in the current act
func start_act_wave(wave_index: int) -> bool:
	if not waves_by_act.has(current_act):
		push_error("No waves for act ", current_act)
		return false
	
	var act_waves = waves_by_act[current_act]
	if wave_index < 0 or wave_index >= act_waves.size():
		push_error("Invalid wave index ", wave_index, " for act ", current_act)
		return false
	
	return _start_wave_internal(act_waves[wave_index])

## Get wave data by ID
func get_wave_data(wave_id: String) -> Dictionary:
	for wave in all_waves:
		if wave.get("wave_id", "") == wave_id:
			return wave
	return {}

## Get waves for specific act
func get_act_waves(act: int) -> Array:
	return waves_by_act.get(act, [])

## Get current wave progress info
func get_progress_info() -> Dictionary:
	return {
		"current_wave": current_wave_id,
		"current_act": current_act,
		"waves_completed": waves_completed.size(),
		"total_waves": all_waves.size(),
		"is_boss_wave": current_wave_data.get("is_boss", false)
	}

## Internal wave start logic
func _start_wave_internal(wave_data: Dictionary) -> bool:
	# Clear any existing gremlins
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.clear_all_gremlins()
	
	# Update current wave info
	current_wave_id = wave_data.get("wave_id", "")
	current_wave_data = wave_data
	current_act = wave_data.get("act", 1)
	
	print("Starting wave: ", wave_data.get("display_name", "Unknown"))
	print("  Strategy: ", wave_data.get("strategy_hint", ""))
	
	# Check if boss wave
	if wave_data.get("is_boss", false):
		boss_encountered.emit(wave_data)
	
	# Spawn the gremlins
	var gremlin_composition = wave_data.get("gremlins", "")
	if gremlin_composition.is_empty():
		push_error("Wave has no gremlins defined")
		return false
	
	if GremlinSpawnController.instance:
		var spawned = GremlinSpawnController.instance.spawn_wave(gremlin_composition)
		if spawned.is_empty():
			push_error("Failed to spawn gremlins for wave")
			return false
	
	# Emit wave started
	wave_started.emit(current_wave_id, wave_data)
	
	# Show strategy hint in UI if available
	if wave_data.has("strategy_hint"):
		_show_strategy_hint(wave_data["strategy_hint"])
	
	return true

## Get the next wave in progression
func _get_next_wave() -> Dictionary:
	if current_wave_id.is_empty():
		# Start with first wave
		if not all_waves.is_empty():
			return all_waves[0]
		return {}
	
	# Find current wave index and return next
	for i in range(all_waves.size()):
		if all_waves[i].get("wave_id", "") == current_wave_id:
			if i + 1 < all_waves.size():
				return all_waves[i + 1]
			break
	
	return {}

## Show strategy hint to player
func _show_strategy_hint(hint: String) -> void:
	# This would connect to UI system
	print("Strategy Hint: ", hint)
	# if BattleUI.instance:
	#     BattleUI.show_hint(hint)

## Handle all gremlins defeated
func _on_all_gremlins_defeated() -> void:
	if current_wave_id.is_empty():
		return
	
	print("Wave completed: ", current_wave_id)
	
	# Track completion
	if not current_wave_id in waves_completed:
		waves_completed.append(current_wave_id)
	
	# Emit completion signal
	wave_completed.emit(current_wave_id)
	
	# Could auto-advance to next wave or wait for player input
	# For now, just log completion

## Reset wave progression
func reset_progression() -> void:
	current_wave_id = ""
	current_wave_data = {}
	current_act = 1
	waves_completed.clear()
	print("Wave progression reset")

## Start specific act
func start_act(act_number: int) -> bool:
	current_act = act_number
	var act_waves = get_act_waves(act_number)
	if act_waves.is_empty():
		push_error("No waves found for act ", act_number)
		return false
	
	# Start first wave of the act
	return _start_wave_internal(act_waves[0])

## Debug function to list all waves
func debug_list_waves() -> void:
	print("=== All Waves ===")
	for wave in all_waves:
		print("  ", wave.get("wave_id", ""), ": ", wave.get("display_name", ""), 
			  " (Act ", wave.get("act", 0), ", Difficulty: ", wave.get("difficulty_tier", ""), ")")
	print("=== Boss Waves ===")
	for wave in boss_waves:
		print("  ", wave.get("wave_id", ""), ": ", wave.get("display_name", ""))