extends Hero
class_name HeroDamageable

## Hero with unified damage system support
## This extends Hero to add Damageable functionality without breaking existing code

# Damageable properties
@export var hero_max_hp: int = 100
var hero_current_hp: int = 100
var hero_shields: int = 0
var hero_barrier_count: int = 0

# Advanced defenses
@export var hero_damage_cap: int = 0
@export var hero_damage_resistance: float = 0.0
@export var hero_reflect_percent: float = 0.0
@export var hero_execute_immunity_threshold: int = 0

# Status flags
@export var hero_invulnerable: bool = false
var hero_burn_duration: int = 0

# Create internal Damageable to handle damage logic
var _damage_handler: Damageable

func _init() -> void:
	super._init()
	_damage_handler = Damageable.new()
	# Note: Core objects don't use scene tree - damage handler works without add_child

	# Connect signals from damage handler
	_damage_handler.damage_received.connect(_on_damage_received)
	_damage_handler.hp_changed.connect(_on_hp_changed)
	_damage_handler.shields_changed.connect(_on_shields_changed)
	_damage_handler.barrier_broken.connect(_on_barrier_broken)
	_damage_handler.defeated.connect(_on_defeated)

	# Sync properties with damage handler immediately
	# This needs to be deferred since exported properties aren't set yet in _init
	call_deferred("_sync_to_handler")

## Main damage interface
func receive_damage(packet: DamagePacket) -> int:
	_sync_to_handler()

	# Apply hero-specific damage modifiers
	var modified_packet = _apply_hero_modifiers(packet)

	# Let damage handler process it
	var damage = _damage_handler.receive_damage(modified_packet)

	# Sync back from handler
	_sync_from_handler()

	return damage

## Apply hero-specific damage modifiers
func _apply_hero_modifiers(packet: DamagePacket) -> DamagePacket:
	# Check for damage reduction from Balance force
	if balance and balance.current > 5:
		var modified = packet.duplicate(true) as DamagePacket
		# Add 20% resistance if we have high Balance
		_damage_handler.damage_resistance = max(_damage_handler.damage_resistance, 0.2)

	return packet

## Heal the hero
func heal(amount: int) -> int:
	_sync_to_handler()
	var healed = _damage_handler.heal(amount)
	_sync_from_handler()
	return healed

## Add shields
func add_shields(amount: int) -> void:
	_damage_handler.add_shields(amount)
	hero_shields = _damage_handler.shields

## Add barriers
func add_barriers(count: int) -> void:
	_damage_handler.add_barriers(count)
	hero_barrier_count = _damage_handler.barrier_count

## Apply burn
func apply_burn(ticks: int) -> void:
	_damage_handler.apply_burn(ticks)
	hero_burn_duration = _damage_handler.burn_duration

## Check if can be executed
func can_be_executed(threshold: int) -> bool:
	return _damage_handler.can_be_executed(threshold)

## Execute
func execute() -> void:
	_damage_handler.execute()

## Sync properties to damage handler
func _sync_to_handler() -> void:
	_damage_handler.max_hp = hero_max_hp
	_damage_handler.current_hp = hero_current_hp
	_damage_handler.armor = armor.amount if armor else 0  # Get amount from CappedResource
	_damage_handler.shields = hero_shields
	_damage_handler.barrier_count = hero_barrier_count
	_damage_handler.damage_cap = hero_damage_cap
	_damage_handler.damage_resistance = hero_damage_resistance
	_damage_handler.reflect_percent = hero_reflect_percent
	_damage_handler.execute_immunity_threshold = hero_execute_immunity_threshold
	_damage_handler.invulnerable = hero_invulnerable
	_damage_handler.burn_duration = hero_burn_duration

## Sync properties from damage handler
func _sync_from_handler() -> void:
	hero_current_hp = _damage_handler.current_hp
	hero_shields = _damage_handler.shields
	hero_barrier_count = _damage_handler.barrier_count
	hero_burn_duration = _damage_handler.burn_duration

## Signal handlers
func _on_damage_received(packet: DamagePacket, actual_damage: int) -> void:
	# Could emit hero-specific signals here
	pass

func _on_hp_changed(new_hp: int, max: int) -> void:
	hero_current_hp = new_hp
	# Could update UI here
	GlobalSignals.signal_core_hero_hp_changed(new_hp, max)

func _on_shields_changed(new_shields: int) -> void:
	hero_shields = new_shields

func _on_barrier_broken() -> void:
	# Could play sound/animation
	pass

func _on_defeated() -> void:
	# Hero defeated - this is different from running out of cards
	GlobalSignals.signal_core_defeat()