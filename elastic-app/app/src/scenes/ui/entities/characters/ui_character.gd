extends Control

class_name UiCharacter


var __entity: Entity = null

@onready var health_bar: HealthBar = %HealthBar

const UI_INTENT: PackedScene = preload("res://src/scenes/ui/entities/characters/intents/ui_intent.tscn")

var intent_visuals: Array[UiIntent] = []

func _ready() -> void:
	GlobalSignals.core_hero_resource_changed.connect(on_hero_resource_changed)
	GlobalSignals.core_mob_resource_changed.connect(on_mob_resource_changed)
	GlobalSignals.core_mob_intent_updated.connect(on_intent_changed)
	set_health_bar()
	set_intent_bar()	
	pass
	
func on_intent_changed(mob_instance_id: String):
	if __entity.instance_id == mob_instance_id:
		set_intent_bar()		
	
func on_hero_resource_changed(type: GameResource.Type, new_amount: int):
	check_resource_and_update(type, new_amount)

func on_mob_resource_changed(mob_instance_id: String, type: GameResource.Type, new_amount: int):
	if __entity.instance_id != mob_instance_id:
		return
	check_resource_and_update(type, new_amount)

func check_resource_and_update(type: GameResource.Type, new_amount: int):
	if type in [GameResource.Type.CURRENT_HEALTH, GameResource.Type.MAX_HEALTH, GameResource.Type.BLOCK, GameResource.Type.ARMOR, GameResource.Type.MAX_ARMOR]:
		set_health_bar()
				
func assign_entity(entity: Entity):
	__entity = entity
	set_health_bar()

func assign_sprite(sprite: AnimatedSprite2D, size: Vector2):
	%SpriteControl.set_sprite(sprite, size)

func set_health_bar():
	if not is_node_ready():
		await self.ready
	await get_tree().process_frame
	if __entity is Mob:
		var mob: Mob = __entity as Mob
		if health_bar != null:
			health_bar.set_health(mob.health.amount, mob.health.max_amount)
			health_bar.set_block(mob.block.amount)
			health_bar.set_armor(mob.armor.amount, mob.armor.max_amount)
	elif __entity is Hero:
		if health_bar != null:
			health_bar.set_health(GlobalGameManager.hero.health.amount, GlobalGameManager.hero.health.max_amount)
			health_bar.set_block(GlobalGameManager.hero.block.amount)
			health_bar.set_armor(GlobalGameManager.hero.armor.amount, GlobalGameManager.hero.armor.max_amount)

func set_intent_bar():
	if not is_node_ready():
		await self.ready
	await get_tree().process_frame
	if not __entity is Mob:
		%IntentsContainer.visible = false
		clear_intent_bar()
	else:
		clear_intent_bar()
		var mob: Mob = __entity as Mob
		var move_pieces: Array[MoveParser.MovePiece] = mob.get_move_pieces()
		for move_piece in move_pieces:
			var intent: UiIntent = UI_INTENT.instantiate()
			intent_visuals.append(intent)
			%IntentsContainer.add_child(intent)
			var label = move_piece.get_label()
			intent.set_intent(move_piece.intent, label)
		%IntentsContainer.visible = true

func clear_intent_bar():
	for ui_intent: UiIntent in intent_visuals:
		ui_intent.queue_free()
	intent_visuals = []

static func load_character(sprite_template_name: String) -> UiCharacter:
	const UI_CHARACTER = preload("res://src/scenes/ui/entities/characters/ui_character.tscn")
	
	var ui_character: UiCharacter = UI_CHARACTER.instantiate()
	
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = PreloadScenes.MOB_SPRITES[sprite_template_name]
	sprite.play("idle")
	sprite.flip_h = true
	var size: Vector2 = Vector2(100, 100)
	ui_character.assign_sprite(sprite, size)
	
	return ui_character
