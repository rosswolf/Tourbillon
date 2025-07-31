extends Control
class_name HealthBar

@onready var health_bar_fill: ProgressBar = %HealthBarFill
@onready var health_text: Label = %HealthText
@onready var block_text: Label = %BlockText
@onready var block_bar_fill: ProgressBar = %BlockBarFill
@onready var block_container: Container = %BlockContainer
@onready var armor_text: Label = %ArmorText
@onready var armor_bar_fill: ProgressBar = %ArmorBarFill
@onready var armor_container: Container = %ArmorContainer

var last_comp: = Vector2.ZERO

func _ready():
	await get_tree().process_frame
	armor_container.visible = false

func set_health(current: int, maximum: int):
	update_health_bar(current, maximum)

func set_block(block: int):
	update_block_display(block)
	
func set_armor(current: int, maximum: int):
	update_armor_display(current, maximum)

func update_health_bar(current: int, maximum: int):
	var new_str = str(current) + "/" + str(maximum)
	health_text.text = new_str
	# Force update
	health_text.queue_redraw()
	health_bar_fill.max_value = maximum
	health_bar_fill.value = current

func update_block_display(block_value: int):
	if block_value == 0:
		block_container.visible = false
	else:
		block_container.visible = true
		var new_str = str(block_value)
		block_text.text = new_str
		# Force update
		block_text.queue_redraw()
		block_bar_fill.max_value = block_value
		block_bar_fill.value = block_value

func update_armor_display(current: int, maximum: int):
	if maximum == 0:
		armor_container.visible = false
	else:
		armor_container.visible = true
		var new_str = str(current) + "/" + str(maximum)
		armor_text.text = new_str
		# Force update
		armor_text.queue_redraw()
		armor_bar_fill.max_value = maximum
		armor_bar_fill.value = current
