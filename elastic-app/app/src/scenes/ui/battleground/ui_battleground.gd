extends UiEntity
class_name UiBattleground

var slots: Array[UiBattlegroundSlot] = []
var last_preview_slot: int = -1

var ui_characters: Dictionary[String, UiCharacter] = {}

func _ready():
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.core_hero_created.connect(__on_hero_created)
	GlobalSignals.core_mob_created.connect(__on_mob_created)
	GlobalSignals.core_arena_created.connect(__on_arena_created)
	GlobalSignals.core_arena_destroyed.connect(__on_arena_destroyed)
	GlobalSignals.core_mob_moved.connect(__on_mob_moved)
	GlobalSignals.core_hero_moved.connect(__on_hero_moved)
	GlobalSignals.core_mob_check_state.connect(__on_mob_health_changed)
	GlobalSignals.core_battleground_targeting_preview_changed.connect(__on_targeting_preview_changed)
	
func __on_targeting_preview_changed(on_index: int):
	for slot_index in range(0, slots.size()):
		slots[slot_index].remove_targeting_preview_icon()
		if on_index == slot_index:
			slots[slot_index].add_targeting_preview_icon()

func __on_arena_created(size: int):
	var UI_BATTLEGROUND_SLOT: PackedScene = preload("res://src/scenes/ui/battleground/ui_battleground_slot.tscn")
	for i in range(size):
		var slot: UiBattlegroundSlot = UI_BATTLEGROUND_SLOT.instantiate()
		slots.append(slot)
		%SlotsContainer.add_child(slot)

func __on_arena_destroyed(instance_id: String):
	__clear_slots()
	__clear_characters()
			
func __clear_slots():
	for slot in slots:
		%SlotsContainer.remove_child(slot)
		slot.queue_free()
	
	slots.clear()

func __clear_characters():
	for character_key in ui_characters.keys():
		if ui_characters[character_key] == null:
			printerr("UI character had a key but no entry: " + character_key)
			continue
		ui_characters[character_key].queue_free()
		
	ui_characters.clear()
		
func __on_start_game():
	set_entity_data(BattlegroundEntity.BattlegroundEntityBuilder.new().build())

func __on_hero_created(instance_id: String):
	print("on_hero_created " + instance_id)
	if instance_id == GlobalGameManager.hero.instance_id:
		var desired_slot: int = get_desired_slot(GlobalGameManager.hero)
		await add_ui_character(GlobalGameManager.hero, GlobalGameManager.hero.image_name, desired_slot)
		
func __on_mob_created(instance_id: String):
	print("on_mob_created " + instance_id)
	if instance_id in GlobalGameManager.battleground.mobs.keys():
		var mob = GlobalGameManager.battleground.mobs[instance_id]
		var desired_slot: int = get_desired_slot(mob)
		await add_ui_character(mob, mob.template_id, desired_slot)

func __on_mob_health_changed(instance_id: String, new_value: int):
	if new_value == 0 and instance_id in GlobalGameManager.battleground.mobs.keys():
		var mob = GlobalGameManager.battleground.mobs[instance_id]
		if not ui_characters.has(mob.instance_id):
			return
		ui_characters[mob.instance_id].queue_free()
		ui_characters.erase(mob.instance_id)

func __on_hero_moved(instance_id: String, new_slot: int):
	if instance_id == GlobalGameManager.hero.instance_id:
		move_ui_character(GlobalGameManager.hero, new_slot)
	
func __on_mob_moved(instance_id: String, new_slot: int):
	if instance_id in GlobalGameManager.battleground.mobs.keys():
		var mob = GlobalGameManager.battleground.mobs[instance_id]
		move_ui_character(mob, new_slot)

func move_ui_character(entity: BattleEntity, new_slot: int):
	if ui_characters.has(entity.instance_id):
		var ui_character: UiCharacter = ui_characters[entity.instance_id]
		
		var pos = get_position_for_character(new_slot)
		
		# Create tween with easing
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(ui_character, "global_position", pos, 0.3)
		# Tween ui_chacter to pos

func add_ui_character(entity: Entity, sprite_name: String, slot: int):
	var ui_character: UiCharacter = UiCharacter.load_character(sprite_name)
	if ui_character == null:
		assert(false, "Failed to load character and sprite: " + sprite_name)
		return null
		
	# Wait for slot layout to be calculated
	await get_tree().process_frame
	await get_tree().process_frame  # Sometimes we need 2 frames
	ui_character.assign_entity(entity)
	%ArenaPanelControl.add_child(ui_character)
		
	var pos = get_position_for_character(slot)
	
	ui_character.set_global_position(pos)
	ui_characters[entity.instance_id] = ui_character
	
func get_desired_slot(entity: Entity):
	return GlobalGameManager.battleground.arena.unit_position_bimap.get_position(entity.instance_id)

func get_slot_x(slot_index: int):
	var result = slots[slot_index].get_global_rect().position
#	print("slot index: " + str(slot_index) + " slot center: " + str(slots[slot_index].get_global_rect()))
	return result.x
	
func get_default_y():
	return %ArenaPanelControl.get_global_rect().position.y + %ArenaPanelControl.get_global_rect().size.y - 240
	
func get_position_for_character(slot_index: int):
	var desired_x = get_slot_x(slot_index)	
	var desired_y = get_default_y()	
	
	return Vector2(desired_x, desired_y)
