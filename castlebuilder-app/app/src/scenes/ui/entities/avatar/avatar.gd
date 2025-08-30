extends CharacterBody2D

# Movement constraints
@export var max_speed: float = 150.0
@export var min_turn_speed: float = 5.0  # Minimum speed when turning (80% of max)
@export var spin_speed: float = 1.0  # How fast it spins (radians per second)
@export var friction: float = 0.8 # For slowing down when close to mouse

# Tail system
@export var tail_max_length: int = 200  # Maximum points in tail history
@export var tail_width: float = 50.0  # Width of the tail stripe
@export var tail_color: Color = Color.CYAN  # Base color of the tail
@export var tail_fade_color: Color = Color(Color.WHITE.r, Color.WHITE.g, Color.WHITE.b, 0.0)  # End color (transparent)

# Pulsating effect
@export var pulse_speed: float = 0.5  # How fast the pulsing is (cycles per second)
@export var pulse_percentage: float = 0.1  # Set this to whatever % you want

# Internal variables
var mouse_position: Vector2
var previous_mouse_position: Vector2
var current_angle: float
var spin_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise
var position_history: Array[Vector2] = []
var time_elapsed: float = 0.0
var previous_velocity: Vector2 = Vector2.ZERO
var original_scale: Vector2
var spin_direction_locked: bool = false  # Prevents rapid direction changes at start

# Spin speed tracking for weapons
var previous_rotation: float = 0.0
var actual_spin_speed: float = 0.0

# Visual components (you'll need to set these up in the scene)
@onready var sprite: Sprite2D = $Sprite2D  # Main entity sprite

func _ready():
	%AnimatedSprite2D.self_modulate = Color.WHITE
	original_scale = %AnimatedSprite2D.scale
	# Initialize position history
	position_history.append(global_position)
	
	# Initialize angles and mouse position
	current_angle = rotation
	previous_rotation = rotation
	previous_mouse_position = get_global_mouse_position()
	UiController.weapons_manager.register_unit("avatar", self, 45.0)
	UiController.weapons_manager.load_firing_pattern("front_assault","avatar")

func _physics_process(delta):
	# Update time for pulsing effect
	time_elapsed += delta
	
	# Update pulsing scale
	update_pulse_effect()
	
	# Get mouse position in global coordinates
	mouse_position = get_global_mouse_position()
	
	# Determine spin direction based on mouse movement
	var mouse_movement = mouse_position - previous_mouse_position
	if mouse_movement.length() > 1.0:  # Keep original sensitivity
		# Use cross product to determine if mouse is moving clockwise or counter-clockwise
		# relative to the entity's position
		var entity_to_mouse = (mouse_position - global_position).normalized()
		var entity_to_prev_mouse = (previous_mouse_position - global_position).normalized()
		
		# Cross product in 2D: if positive, clockwise; if negative, counter-clockwise
		var cross_product = entity_to_prev_mouse.x * entity_to_mouse.y - entity_to_prev_mouse.y * entity_to_mouse.x
		
		# More sensitive threshold for responsive control
		if abs(cross_product) > 0.05:  # Even more sensitive than before
			var new_direction = sign(cross_product)
			
			# Prevent wild spinning at startup by requiring some stability
			if not spin_direction_locked:
				# At startup, require a bit more evidence before first direction change
				if time_elapsed > 0.2:  # Very short delay
					spin_direction = new_direction
					spin_direction_locked = true
			else:
				# After startup, allow immediate direction changes (full sensitivity)
				spin_direction = new_direction
	
	# Always spin continuously
	current_angle += spin_direction * spin_speed * delta
	
	# Update rotation
	rotation = current_angle
	
	# Calculate movement - adjust speed based on actual direction change
	var distance_to_mouse = global_position.distance_to(mouse_position)
	
	if distance_to_mouse > 15.0:
		# Move directly towards mouse with speed based on direction change
		var direction_to_mouse_normalized = (mouse_position - global_position).normalized()
		
		# Calculate how much the movement direction is changing
		var turn_severity = 0.0
		if previous_velocity.length() > 0:
			var previous_direction = previous_velocity.normalized()
			var dot_product = previous_direction.dot(direction_to_mouse_normalized)
			# dot_product: 1 = same direction, -1 = opposite direction, 0 = 90 degrees
			turn_severity = (1.0 - dot_product) * 0.5  # Convert to 0-1 range
		
		# Interpolate speed based on turn severity
		var current_max_speed = lerp(max_speed, min_turn_speed, turn_severity)
		
		velocity = direction_to_mouse_normalized * current_max_speed
		previous_velocity = velocity
	elif distance_to_mouse > 5.0:
		# Gradual slowdown zone
		var slowdown_factor = distance_to_mouse / 15.0
		velocity = velocity * pow(friction, delta) * slowdown_factor
		previous_velocity = velocity
	else:
		# Complete stop when very close
		velocity = Vector2.ZERO
		previous_velocity = Vector2.ZERO
	
	# Move the character
	move_and_slide()
	
	# Update position history
	update_position_history()
	
	# Calculate actual spin speed for weapons prediction
	__update_spin_speed_tracking(delta)
	
	# Store current mouse position for next frame
	previous_mouse_position = mouse_position
	
	# Queue redraw for tail rendering
	queue_redraw()

func __update_spin_speed_tracking(delta: float):
	# Calculate actual rotation change this frame
	var rotation_change = rotation - previous_rotation
	
	# Handle angle wrapping (crossing from 2π to 0 or vice versa)
	while rotation_change > PI:
		rotation_change -= 2 * PI
	while rotation_change < -PI:
		rotation_change += 2 * PI
	
	# Calculate actual spin speed (radians per second)
	if delta > 0:
		actual_spin_speed = rotation_change / delta
	else:
		actual_spin_speed = 0.0
	
	# Store current rotation for next frame
	previous_rotation = rotation

func get_spin_speed() -> float:
	# Return actual measured spin speed for weapons prediction
	return actual_spin_speed

func update_position_history():
	# Check if we're moving
	var is_moving = velocity.length() > 5.0  # Threshold for considering "moving"
	
	if is_moving:
		# Only add position if we've moved a minimum distance
		var min_distance = 2.0  # Minimum pixels to move before adding to history
		
		if position_history.size() == 0:
			position_history.append(global_position)
		else:
			var last_position = position_history[-1]
			var distance_moved = global_position.distance_to(last_position)
			
			if distance_moved >= min_distance:
				position_history.append(global_position)
	else:
		# When stopped, gradually remove tail points
		if position_history.size() > 1:
			position_history.pop_front()  # Remove oldest point
	
	# Keep history to reasonable size
	if position_history.size() > tail_max_length:
		position_history = position_history.slice(position_history.size() - tail_max_length)

func _draw():
	# Draw the tail as multiple polylines broken at direction changes
	if position_history.size() < 2:
		return
	
	# Break the trail into segments based on direction continuity using dot product
	var segments: Array[Array] = []
	var current_segment: Array[Vector2] = [position_history[0]]
	
	for i in range(1, position_history.size()):
		# Always add the current point to the segment
		current_segment.append(position_history[i])
		
		# Check if we need to break at this point (if there's a next point to compare)
		if i < position_history.size() - 1:
			var prev_pos = position_history[i - 1]
			var current_pos = position_history[i]
			var next_pos = position_history[i + 1]
			
			# Calculate movement direction vectors
			var incoming_direction = (current_pos - prev_pos).normalized()
			var outgoing_direction = (next_pos - current_pos).normalized()
			
			# Use dot product to measure direction continuity
			# dot = 1.0: same direction (0°)
			# dot = 0.0: perpendicular (90°) 
			# dot = -1.0: opposite direction (180°)
			var direction_continuity = incoming_direction.dot(outgoing_direction)
			
			# Break when direction changes significantly
			if direction_continuity < 0.7:  # Break at ~45° direction changes
				segments.append(current_segment)
				current_segment = [current_pos]  # Start new segment with current point
	
	# Add the final segment
	if current_segment.size() > 1:
		segments.append(current_segment)
	
	# Draw each segment separately
	for segment in segments:
		if segment.size() < 2:
			continue
			
		# Convert to local coordinates
		var local_positions: PackedVector2Array = []
		for pos in segment:
			local_positions.append(to_local(pos))
		
		# Create colors for this segment based on global position in full trail
		var colors: PackedColorArray = []
		for i in range(segment.size()):
			# Find this point's position in the original history
			var global_index = -1
			for j in range(position_history.size()):
				if position_history[j] == segment[i]:
					global_index = j
					break
			
			# Calculate fade based on global position
			var global_fade = 0.0
			if global_index >= 0 and position_history.size() > 1:
				global_fade = float(global_index) / float(position_history.size() - 1)
			
			var color = tail_fade_color.lerp(tail_color, global_fade)
			colors.append(color)
		
		# Draw the segment 
		var layers = 8
		for layer in range(layers):
			var layer_factor = float(layers - layer) / float(layers)
			var width = tail_width * layer_factor
			var alpha_multiplier = 1.0  # Full alpha for debugging
			
			var layer_colors: PackedColorArray = []
			for color in colors:
				var layer_color = color
				layer_color.a *= alpha_multiplier
				layer_colors.append(layer_color)
			
			draw_polyline_colors(local_positions, layer_colors, width, true)



func update_pulse_effect():
	# Pulse factor goes from 0 to 1
	var pulse_factor = (sin(time_elapsed * pulse_speed * 2.0 * PI) + 1.0) * 0.5
	
	# Scale between original size (100%) and original + percentage
	var scale_increase = pulse_factor * (pulse_percentage)
	var current_scale = original_scale * (1.0 + scale_increase)
	
	if %AnimatedSprite2D:
		%AnimatedSprite2D.scale = current_scale

func angle_difference(target: float, current: float) -> float:
	# Calculate shortest angular distance between two angles
	var diff = target - current
	while diff > PI:
		diff -= 2 * PI
	while diff < -PI:
		diff += 2 * PI
	return diff
