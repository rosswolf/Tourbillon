extends Node2D
class_name EffectVisualizer

## Displays visual feedback for effects like damage, force production, etc.
## Creates floating text and particle effects

var floating_text_scene = preload("res://src/scenes/ui/tourbillon/floating_text.tscn")

# Effect colors by type
const EFFECT_COLORS = {
	"damage": Color.RED,
	"heal": Color.GREEN,
	"shield": Color.CYAN,
	"poison": Color.PURPLE,
	"burn": Color.ORANGE,
	"heat": Color(1.0, 0.3, 0.0),      # Red-orange
	"precision": Color(0.0, 0.5, 1.0),  # Blue
	"momentum": Color(0.0, 0.8, 0.0),   # Green
	"balance": Color(1.0, 1.0, 1.0),    # White
	"entropy": Color(0.5, 0.0, 0.5),    # Purple
	"inspiration": Color(1.0, 0.8, 0.0), # Gold
	"draw": Color.YELLOW,
	"discard": Color.GRAY
}

func _ready() -> void:
	# Connect to effect signals
	__connect_effect_signals()

func __connect_effect_signals() -> void:
	# These would be emitted by TourbillonEffectProcessor
	GlobalSignals.effect_damage_dealt.connect(_on_damage_dealt)
	GlobalSignals.effect_force_produced.connect(_on_force_produced)
	GlobalSignals.effect_force_consumed.connect(_on_force_consumed)
	GlobalSignals.effect_card_drawn.connect(_on_card_drawn)
	GlobalSignals.effect_status_applied.connect(_on_status_applied)

func _on_damage_dealt(amount: int, target_position: Vector2) -> void:
	__create_floating_text("-" + str(amount), target_position, EFFECT_COLORS["damage"])
	__create_impact_particles(target_position, EFFECT_COLORS["damage"])

func _on_force_produced(force_type: GameResource.Type, amount: int, source_position: Vector2) -> void:
	var force_name = __get_force_name(force_type)
	var color = EFFECT_COLORS.get(force_name.to_lower(), Color.WHITE)
	__create_floating_text("+" + str(amount) + " " + force_name, source_position, color)
	__create_production_particles(source_position, color)

func _on_force_consumed(force_type: GameResource.Type, amount: int, source_position: Vector2) -> void:
	var force_name = __get_force_name(force_type)
	var color = EFFECT_COLORS.get(force_name.to_lower(), Color.GRAY)
	__create_floating_text("-" + str(amount) + " " + force_name, source_position, color)

func _on_card_drawn(card_count: int, position: Vector2) -> void:
	__create_floating_text("Draw " + str(card_count), position, EFFECT_COLORS["draw"])

func _on_status_applied(status_type: String, stacks: int, target_position: Vector2) -> void:
	var color = EFFECT_COLORS.get(status_type.to_lower(), Color.WHITE)
	__create_floating_text(status_type + " " + str(stacks), target_position, color)
	__create_status_particles(target_position, color, status_type)

func __create_floating_text(text: String, position: Vector2, color: Color) -> void:
	if not floating_text_scene:
		# Create a simple label if scene doesn't exist
		var label = Label.new()
		label.text = text
		label.modulate = color
		label.position = position
		add_child(label)
		
		# Animate it floating up and fading
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", position.y - 50, 1.0)
		tween.tween_property(label, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(label.queue_free)
	else:
		var floating_text = floating_text_scene.instantiate()
		floating_text.setup(text, color)
		floating_text.position = position
		add_child(floating_text)

func __create_impact_particles(position: Vector2, color: Color) -> void:
	# Create a simple particle effect for impacts
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.spread = 45.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = color
	
	add_child(particles)
	
	# Clean up after emission
	await particles.finished
	particles.queue_free()

func __create_production_particles(position: Vector2, color: Color) -> void:
	# Create upward flowing particles for production
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.direction = Vector2.UP
	particles.spread = 15.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.2
	particles.color = color
	
	add_child(particles)
	
	# Clean up after emission
	await particles.finished
	particles.queue_free()

func __create_status_particles(position: Vector2, color: Color, status_type: String) -> void:
	# Create swirling particles for status effects
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.angular_velocity_min = 90.0
	particles.angular_velocity_max = 180.0
	particles.orbit_velocity_min = 0.1
	particles.orbit_velocity_max = 0.2
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.color = color
	
	add_child(particles)
	
	# Clean up after emission
	await particles.finished
	particles.queue_free()

func __get_force_name(force_type: GameResource.Type) -> String:
	match force_type:
		GameResource.Type.HEAT:
			return "Heat"
		GameResource.Type.PRECISION:
			return "Precision"
		GameResource.Type.MOMENTUM:
			return "Momentum"
		GameResource.Type.BALANCE:
			return "Balance"
		GameResource.Type.ENTROPY:
			return "Entropy"
		GameResource.Type.INSPIRATION:
			return "Inspiration"
		_:
			return "Force"

## Show effect at a specific slot
func show_slot_effect(slot: EngineSlot, effect_type: String, value: Variant = null) -> void:
	var slot_position = slot.global_position + slot.size / 2
	
	match effect_type:
		"fire":
			__create_production_particles(slot_position, Color.WHITE)
		"ready":
			__create_floating_text("READY!", slot_position, Color.YELLOW)
		"cooldown":
			__create_floating_text("Cooldown", slot_position, Color.GRAY)
		_:
			pass