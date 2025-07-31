extends Control

class_name UiIntent

var current_textures: Array[TextureRect] = []

#@onready var melee_attack_icon: TextureRect = %MeleeAttackIcon
#@onready var non_attack_icon: TextureRect = %NonAttackIcon
#@onready var ranged_attack_icon: TextureRect = %RangedAttackIcon
#@onready var move_icon: TextureRect = %MoveIcon
#
#@onready var intent_label: Label = %IntentLabel

func _ready():
	pass
	#await get_tree().process_frame
	#$%SomethingBesidesLabel.scale = Vector2(0.2, 0.2)

func set_intent(intent: Effect.Intent, label: String):
	#await get_tree().process_frame
	#clear_current_textures()
	
	if intent == Effect.Intent.MOVE:
		%MoveIcon.visible = true
	if intent == Effect.Intent.ATTACK_RANGED:
		%RangedAttackIcon.visible = true
	elif intent == Effect.Intent.NON_ATTACK:
		%NonAttackIcon.visible = true
	elif intent == Effect.Intent.ATTACK_MELEE:
		%MeleeAttackIcon.visible = true
	
	%IntentLabel.text = label
	
func clear_current_textures():
	%MoveIcon.visible = false
	%MeleeAttackIcon.visible = false
	%NonAttackIcon.visible = false
	%RangedAttackIcon.visible = false
