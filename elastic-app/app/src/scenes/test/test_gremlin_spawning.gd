extends Node
class_name TestGremlinSpawning

## Test scene for verifying gremlin spawning system
## Run this to test spawning individual gremlins and waves

var spawn_controller: GremlinSpawnController
var wave_manager: WaveManager

func _ready() -> void:
	print("\n=== Gremlin Spawning Test Started ===\n")
	
	# Create controllers if they don't exist
	if not GremlinSpawnController.instance:
		spawn_controller = GremlinSpawnController.new()
		add_child(spawn_controller)
	else:
		spawn_controller = GremlinSpawnController.instance
	
	if not WaveManager.instance:
		wave_manager = WaveManager.new()
		add_child(wave_manager)
	else:
		wave_manager = WaveManager.instance
	
	# Connect signals for testing
	spawn_controller.gremlin_spawned.connect(_on_gremlin_spawned)
	spawn_controller.wave_spawned.connect(_on_wave_spawned)
	spawn_controller.all_gremlins_defeated.connect(_on_all_defeated)
	
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	
	# Run tests
	await get_tree().create_timer(0.5).timeout
	await test_single_gremlin_spawn()
	
	await get_tree().create_timer(1.0).timeout
	await test_wave_spawn()
	
	await get_tree().create_timer(1.0).timeout
	await test_damage_and_poison()
	
	print("\n=== All Tests Complete ===\n")

## Test spawning a single gremlin
func test_single_gremlin_spawn() -> void:
	print("\n--- Test: Single Gremlin Spawn ---")
	
	# Spawn a basic dust mite
	var gremlin = spawn_controller.spawn_gremlin("dust_mite", 0)
	
	if gremlin:
		print("✓ Successfully spawned: ", gremlin.gremlin_name)
		print("  HP: ", gremlin.current_hp, "/", gremlin.max_hp)
		print("  Slot: ", gremlin.slot_index)
		print("  Archetype: ", gremlin.get_meta("archetype", "unknown"))
		
		# Test that it's registered
		var active = spawn_controller.get_active_gremlins()
		assert(active.size() == 1, "Should have 1 active gremlin")
		print("✓ Gremlin registered in active list")
	else:
		print("✗ Failed to spawn gremlin")

## Test spawning a wave
func test_wave_spawn() -> void:
	print("\n--- Test: Wave Spawn ---")
	
	# Clear previous gremlins
	spawn_controller.clear_all_gremlins()
	
	# Start first tutorial wave
	var success = wave_manager.start_wave("wave_1a")
	
	if success:
		print("✓ Successfully started wave: wave_1a")
		
		# Check spawned gremlins
		await get_tree().create_timer(0.5).timeout
		var gremlins = spawn_controller.get_active_gremlins()
		print("  Spawned ", gremlins.size(), " gremlin(s)")
		
		for g in gremlins:
			print("    - ", g.gremlin_name, " (HP: ", g.current_hp, ")")
	else:
		print("✗ Failed to start wave")
	
	# Test swarm wave
	spawn_controller.clear_all_gremlins()
	success = wave_manager.start_wave("wave_1d")
	
	if success:
		print("✓ Started swarm wave: wave_1d")
		var gremlins = spawn_controller.get_active_gremlins()
		print("  Spawned ", gremlins.size(), " gremlins (expected 3)")
		assert(gremlins.size() == 3, "Swarm should spawn 3 gremlins")

## Test damage and poison mechanics
func test_damage_and_poison() -> void:
	print("\n--- Test: Damage and Poison ---")
	
	spawn_controller.clear_all_gremlins()
	
	# Spawn a test gremlin
	var gremlin = spawn_controller.spawn_gremlin("dust_mite", 0)
	if not gremlin:
		print("✗ Could not spawn gremlin for damage test")
		return
	
	var initial_hp = gremlin.current_hp
	print("Initial HP: ", initial_hp)
	
	# Test basic damage
	gremlin.take_damage(5, false, false)
	print("After 5 damage: ", gremlin.current_hp, " (expected ", initial_hp - 5, ")")
	assert(gremlin.current_hp == initial_hp - 5, "Damage should reduce HP")
	
	# Test poison application
	gremlin.apply_poison(3)
	var poison_stacks = gremlin.get_poison_stacks()
	print("Applied 3 poison stacks: ", poison_stacks, " stacks")
	assert(poison_stacks == 3, "Should have 3 poison stacks")
	
	# Simulate beat processing for poison
	var context = BeatContext.new()
	context.beat_number = 1
	
	# Process 10 beats (1 tick) to trigger poison
	for i in range(10):
		context.beat_number = i + 1
		gremlin.process_beat(context)
	
	print("After 10 beats (poison tick): HP = ", gremlin.current_hp)
	
	# Test defeat
	gremlin.take_damage(100, true, false)  # Pierce damage to ensure defeat
	print("After lethal damage: HP = ", gremlin.current_hp)
	
	# Check if defeated signal was emitted
	await get_tree().create_timer(0.5).timeout
	var remaining = spawn_controller.get_active_gremlins()
	assert(remaining.size() == 0, "Defeated gremlin should be removed from active list")
	print("✓ Gremlin properly removed after defeat")

## Signal handlers for testing
func _on_gremlin_spawned(gremlin: Gremlin) -> void:
	print("  [Signal] Gremlin spawned: ", gremlin.gremlin_name)

func _on_wave_spawned(gremlins: Array) -> void:
	print("  [Signal] Wave spawned with ", gremlins.size(), " gremlins")

func _on_all_defeated() -> void:
	print("  [Signal] All gremlins defeated!")

func _on_wave_started(wave_id: String, wave_data: Dictionary) -> void:
	print("  [Signal] Wave started: ", wave_id, " - ", wave_data.get("display_name", ""))

func _on_wave_completed(wave_id: String) -> void:
	print("  [Signal] Wave completed: ", wave_id)

## Helper to simulate a full combat
func simulate_combat() -> void:
	print("\n--- Simulating Full Combat ---")
	
	# Start a wave
	wave_manager.start_wave("wave_1a")
	
	# Simulate time passing and card plays
	var beat_count = 0
	var context = BeatContext.new()
	
	while not spawn_controller.are_all_defeated() and beat_count < 1000:
		beat_count += 1
		context.beat_number = beat_count
		
		# Process beats for all gremlins
		for gremlin in spawn_controller.get_active_gremlins():
			if is_instance_valid(gremlin):
				gremlin.process_beat(context)
		
		# Every 50 beats (5 ticks), deal some damage
		if beat_count % 50 == 0:
			print("  Tick ", beat_count / 10, ": Dealing damage...")
			for gremlin in spawn_controller.get_active_gremlins():
				if is_instance_valid(gremlin):
					gremlin.take_damage(3, false, false)
					print("    ", gremlin.gremlin_name, " HP: ", gremlin.current_hp, "/", gremlin.max_hp)
	
	if spawn_controller.are_all_defeated():
		print("✓ Combat complete - all gremlins defeated in ", beat_count, " beats")
	else:
		print("✗ Combat timed out after ", beat_count, " beats")