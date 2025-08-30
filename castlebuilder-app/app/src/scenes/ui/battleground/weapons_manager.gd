# Centralized weapons manager - handles all firing for all units
class_name WeaponsManager
extends Node

# Data classes
class WeaponData:
	var shots: Array[ShotData] = []
	var source: String = ""
	var instance_id: String = ""
	
class ShotData:
	var firing_delay: float = 0.0  # Delay from trigger time
	var muzzle_angle_degrees: float = 0.0  # Muzzle position angle in degrees (0 = up, 90 = right, etc.)
	var speed: float = 1.0
	var damage: float = 1.0
	var trigger_rotation: float = 0.0  # Rotation when shot was queued
	var trigger_time: float = 0.0  # When shot was queued
	var lifetime: float = 1.0
	var uuid: String = ""

# Unit firing info - what each unit will fire next
class UnitFiring:
	var unit_id: String
	var unit_node: Node2D  # Reference to the actual unit
	var muzzle_offset: float = 35.0  # Distance from center to muzzle
	var firing_pattern: WeaponData  # The repeating pattern
	var current_shot_index: int = 0  # Which shot in the pattern is next
	var next_shot_time: float = 0.0  # When the next shot should fire
	var pattern_start_time: float = 0.0  # When current pattern cycle started

# Active units being managed
var managed_units: Dictionary = {}  # unit_id -> UnitFiring

func _ready():
	# Run every frame to check for shots to fire
	set_process(true)
	UiController.weapons_manager = self

func _process(delta):
	var current_time = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	
	# Check each unit for shots ready to fire
	for unit_id in managed_units.keys():
		var unit_firing: UnitFiring = managed_units[unit_id]
		__process_unit_shots(unit_firing, current_time)
		
func __process_unit_shots(unit_firing: UnitFiring, current_time: float):
	# Skip if no firing pattern set
	if not unit_firing.firing_pattern or unit_firing.firing_pattern.shots.is_empty():
		return
	
	# Check if it's time to fire
	if current_time < unit_firing.next_shot_time:
		return
	
	# Get the delay time for the current shot that's ready to fire
	var current_shot = unit_firing.firing_pattern.shots[unit_firing.current_shot_index]
	var firing_delay = current_shot.firing_delay
	
	# Collect all shots that have the same firing delay
	var shots_to_fire: Array[ShotData] = []
	var original_index = unit_firing.current_shot_index
	
	# Loop through pattern starting from current position to find all shots with same delay
	for i in range(unit_firing.firing_pattern.shots.size()):
		var shot_index = (original_index + i) % unit_firing.firing_pattern.shots.size()
		var shot = unit_firing.firing_pattern.shots[shot_index]
		
		if shot.firing_delay == firing_delay:
			# This shot has the same delay - include it
			shot.trigger_rotation = unit_firing.unit_node.rotation
			shot.trigger_time = current_time
			shots_to_fire.append(shot)
			
			# Advance the current shot index
			unit_firing.current_shot_index = (shot_index + 1) % unit_firing.firing_pattern.shots.size()
		else:
			# Different delay found - we're done collecting
			break
	
	# Calculate next shot time based on where we ended up
	var next_shot = unit_firing.firing_pattern.shots[unit_firing.current_shot_index]
	unit_firing.next_shot_time = current_time + next_shot.firing_delay
	
	# Create all projectiles first
	var projectiles: Array = []
	for shot_data in shots_to_fire:
		var projectile = _get_shot(unit_firing, shot_data, current_time)
		if projectile != null:
			projectiles.append(projectile)
	
	# Add all projectiles to scene simultaneously
	for projectile in projectiles:
		get_tree().current_scene.add_child(projectile)
		

func _get_shot(unit_firing: UnitFiring, shot_data: ShotData, current_time: float):
	var unit_node = unit_firing.unit_node
	assert(is_instance_valid(unit_node), "Unit node must be valid to create shots")
	
	# Muzzle position uses CURRENT rotation (not predicted)
	var muzzle_offset_direction = Vector2.UP.rotated(deg_to_rad(shot_data.muzzle_angle_degrees))
	var rotated_muzzle_direction = muzzle_offset_direction.rotated(unit_node.rotation)
	var muzzle_pos = unit_node.global_position + rotated_muzzle_direction * unit_firing.muzzle_offset
	
	# Fire direction uses PREDICTED rotation for smooth shooting
	var spin_speed = unit_node.get_spin_speed()
	# Calculate predicted rotation at fire time
	var time_to_fire = shot_data.firing_delay
	var predicted_rotation = shot_data.trigger_rotation + (spin_speed * time_to_fire)
	
	# Fire direction uses predicted rotation
	var predicted_muzzle_direction = muzzle_offset_direction.rotated(predicted_rotation)
	var final_direction = predicted_muzzle_direction
	
	# Calculate final properties
	var final_speed = shot_data.speed 
	var final_damage = shot_data.damage
	
	var final_lifetime = shot_data.lifetime
	
	# Spawn the projectile
	return __spawn_projectile(muzzle_pos, final_direction, final_speed, final_damage, final_lifetime)

func __spawn_projectile(position: Vector2, direction: Vector2, speed: float, damage: float, lifetime):
	var projectile = PreloadScenes.SCENES['projectile'].instantiate()
	projectile.damage = damage
	projectile.initialize(position, direction, speed, lifetime)
	return projectile

# Public API Methods

# Register a unit for weapon management
func register_unit(unit_id: String, unit_node: Node2D, muzzle_offset: float = 35.0):
	var unit_firing = UnitFiring.new()
	unit_firing.unit_id = unit_id
	unit_firing.unit_node = unit_node
	unit_firing.muzzle_offset = muzzle_offset
	
	managed_units[unit_id] = unit_firing

# Remove unit from management
func unregister_unit(unit_id: String):
	if unit_id in managed_units:
		managed_units.erase(unit_id)

# Set the firing pattern for a unit (starts firing immediately)
func set_firing_pattern(unit_id: String, firing_data: WeaponData):
	assert(unit_id in managed_units, "Unit must be registered before setting firing pattern: " + unit_id)
	
	var unit_firing: UnitFiring = managed_units[unit_id]
	unit_firing.firing_pattern = firing_data
	unit_firing.current_shot_index = 0
	unit_firing.pattern_start_time = Time.get_ticks_msec() / 1000.0
	
	# Set time for first shot (fire immediately)
	if firing_data.shots.size() > 0:
		unit_firing.next_shot_time = unit_firing.pattern_start_time  # Fire first shot immediately

# Stop firing for a unit
func stop_firing(unit_id: String):
	var unit_firing = get_unit_firing(unit_id)
	if unit_firing:
		unit_firing.firing_pattern = null


func load_firing_pattern(pattern_id: String, unit_id: String):
	var firing_data = WeaponData.new()
	firing_data.source = pattern_id
	firing_data.instance_id = unit_id
	
	for i in range(8):
		var shot = load_weapon_shot(pattern_id, i)
		if shot != null:
			firing_data.shots.append(shot)
	
	set_firing_pattern(unit_id, firing_data)

func load_weapon_shot(pattern_id: String, index: int) -> ShotData:
	
	var weapon_template_data: Dictionary = StaticData.weapon_data.get(pattern_id)
	
	if int(weapon_template_data.get("shot_"+str(index), -1)) == -1:
		return null
	
	var shot = ShotData.new()
	
	shot.firing_delay = float(weapon_template_data.get("firing_delay_"+str(index)))
	shot.muzzle_angle_degrees = float(weapon_template_data.get("muzzle_angle_degrees_"+str(index)))
	shot.speed = float(weapon_template_data.get("speed_"+str(index)))
	shot.damage = float(weapon_template_data.get("damage_"+str(index)))
	shot.uuid = weapon_template_data.get("uuid_"+str(index), "")
	shot.lifetime = weapon_template_data.get("lifetime_"+str(index))
	
	
	return shot
	

# Get unit firing info (useful for checking cooldowns, etc.)
func get_unit_firing(unit_id: String) -> UnitFiring:
	return managed_units.get(unit_id, null)

# Check if unit is currently firing
func is_firing(unit_id: String) -> bool:
	var unit_firing = get_unit_firing(unit_id)
	return unit_firing != null and unit_firing.firing_pattern != null
