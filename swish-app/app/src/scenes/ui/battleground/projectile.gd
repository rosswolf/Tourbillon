extends Area2D
class_name Projectile

# Projectile properties
@export var speed: float = 400.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
@export var piercing: int = 1  # How many enemies it can hit (1 = single hit)

# Internal variables
var velocity: Vector2
var time_alive: float = 0.0
var enemies_hit: int = 0

func _ready():
    # Connect collision signals
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func _physics_process(delta):
    # Move the projectile manually
    position += velocity * delta
    
    # Update lifetime
    time_alive += delta
    
    # Destroy if lifetime exceeded
    if time_alive >= lifetime:
        queue_free()

func initialize(start_position: Vector2, direction: Vector2, projectile_speed: float = speed, lifetime_in: float = lifetime):
    # Set starting position
    global_position = start_position
    
    # Set velocity based on direction and speed
    velocity = direction.normalized() * projectile_speed
    
    # Rotate sprite to match direction
    rotation = direction.angle()
    
    lifetime = lifetime_in

func _on_body_entered(body):
    # Check if it's an enemy (adjust this based on your enemy setup)
    if body.has_method("take_damage"):
        # Deal damage to enemy
        body.take_damage(damage)
        
        # Increment hit counter
        enemies_hit += 1
        
        # Destroy if we've hit our piercing limit
        if enemies_hit >= piercing:
            queue_free()

func _on_area_entered(area):
    # Alternative collision detection if enemies are Area2D instead of CharacterBody2D
    if area.has_method("take_damage"):
        area.take_damage(damage)
        enemies_hit += 1
        
        if enemies_hit >= piercing:
            queue_free()

# Optional: Visual effect on destruction
func _exit_tree():
    # Add destruction effect here if desired
    pass
